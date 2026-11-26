// ✨ Écran « Demandez à Nguli » (Rapport → visage de Nguli)
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'avatar_nguli.dart';

import '../../core/providers/currency_provider.dart';
import '../../core/providers/produit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../boutiques/boutique_provider.dart';
import '../../core/services/photo_ia_service.dart';
import 'assistant_service.dart';
import 'historique_assistant.dart';
import 'voix_naturelle.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  const AssistantScreen({super.key, required this.entrepriseId});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _question = TextEditingController();
  final _defilement = ScrollController();
  final List<(String, String)> _echanges = []; // (question, réponse)

  // 🕘 Discussion en cours (gardée sur le téléphone)
  int _idDiscussion = DateTime.now().millisecondsSinceEpoch;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  void _sauver() => unawaited(
      HistoriqueAssistant.enregistrer(widget.entrepriseId, _uid, Discussion(_idDiscussion, List.of(_echanges))));

  void _nouvelleDiscussion() {
    _voix.stop();
    setState(() {
      _echanges.clear();
      _idDiscussion = DateTime.now().millisecondsSinceEpoch;
    });
  }

  Future<void> _ouvrirHistorique() async {
    final t = AppLocalizations.of(context);
    final liste = await HistoriqueAssistant.lire(widget.entrepriseId, _uid);
    if (!mounted) return;
    final choisie = await showModalBottomSheet<Discussion>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateFeuille) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: liste.isEmpty
                ? Center(child: Text(t.astHistoryEmpty))
                : ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(t.astHistory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      for (final d in liste)
                        ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(d.titre, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${_dateCourte(d.date)} · ${t.astNbQuestions('${d.echanges.length}')}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: t.astDelete,
                            onPressed: () async {
                              await HistoriqueAssistant.supprimer(widget.entrepriseId, _uid, d.id);
                              setStateFeuille(() => liste.remove(d));
                            },
                          ),
                          onTap: () => Navigator.pop(ctx, d),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
    if (choisie == null || !mounted) return;
    _voix.stop();
    setState(() {
      _echanges
        ..clear()
        ..addAll(choisie.echanges);
      _idDiscussion = choisie.id; // on peut continuer cette discussion
    });
    _enBas();
  }

  static String _dateCourte(DateTime d) {
    String deux(int v) => v.toString().padLeft(2, '0');
    return '${deux(d.day)}/${deux(d.month)}/${d.year} ${deux(d.hour)}:${deux(d.minute)}';
  }
  Map<String, dynamic>? _resume;
  String? _erreur;
  bool _reflechit = false;

  // 🎤 Question à voix haute, 🔊 réponse lue à voix haute
  final _micro = AudioRecorder();
  final _voix = FlutterTts();
  bool _ecoute = false;
  bool _lireReponses = true;
  Timer? _limite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  void dispose() {
    _limite?.cancel();
    _micro.dispose();
    _voix.stop();
    _question.dispose();
    _defilement.dispose();
    super.dispose();
  }

  /// 🔊 Lit un texte dans la langue de l'application, avec la voix la plus naturelle
  ///    installée sur le téléphone (lingala : voix française, aucune voix lingala n'existe)
  String? _langueVoix;
  Future<void> _lire(String texte) async {
    final code = Localizations.localeOf(context).languageCode;
    final essais = switch (code) {
      'en' => ['en-US', 'en-GB'],
      'sw' => ['sw-KE', 'sw-TZ', 'sw', 'fr-FR'],
      _ => ['fr-FR', 'fr-BE', 'fr'],
    };
    if (_langueVoix != code) {
      var choisie = false;
      try {
        final voix = await _voix.getVoices;
        final meilleure = VoixNaturelle.choisirVoix(voix is List ? voix : const [], essais);
        if (meilleure != null) {
          await _voix.setVoice(meilleure);
          choisie = true;
        }
      } catch (_) {}
      if (!choisie) {
        for (final l in essais) {
          try {
            if (await _voix.isLanguageAvailable(l) == true) {
              await _voix.setLanguage(l);
              break;
            }
          } catch (_) {}
        }
      }
      await _voix.setSpeechRate(0.5); // vitesse normale (0,5 = 1,0 sur Android)
      await _voix.setPitch(1.0);
      _langueVoix = code;
    }
    await _voix.stop();
    await _voix.speak(VoixNaturelle.preparer(texte, code));
  }

  /// 🎤 Premier appui : on écoute. Deuxième appui (ou 30 s) : on envoie.
  Future<void> _microAppui() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_resume == null || _reflechit) return;
    if (_ecoute) {
      _limite?.cancel();
      final chemin = await _micro.stop();
      setState(() => _ecoute = false);
      if (chemin == null) return;
      final octets = await File(chemin).readAsBytes();
      if (octets.length < 8000) return; // moins d'une demi-seconde : rien à envoyer
      await _envoyerAudio(octets);
      return;
    }
    if (!await _micro.hasPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(t.astMicDenied)));
      return;
    }
    await _voix.stop();
    final dossier = await getTemporaryDirectory();
    await _micro.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: '${dossier.path}/question_nguli.wav',
    );
    setState(() => _ecoute = true);
    _limite = Timer(const Duration(seconds: 30), () {
      if (_ecoute) _microAppui();
    });
  }

  Future<void> _envoyerAudio(List<int> octets) async {
    final t = AppLocalizations.of(context);
    final resume = _resume;
    if (resume == null) return;
    setState(() {
      _reflechit = true;
      _echanges.add(('🎤 …', ''));
    });
    _enBas();
    var question = '🎤';
    String reponse;
    try {
      final (q, r) = await AssistantService.demanderAudio(
        resume: resume,
        audio: Uint8List.fromList(octets),
        mimeType: 'audio/wav',
        langue: Localizations.localeOf(context).languageCode,
        historique: _echanges.sublist(0, _echanges.length - 1),
      );
      if (q.isNotEmpty) question = '🎤 $q';
      reponse = r.isEmpty ? t.astNoAnswer : r;
    } on TimeoutException {
      reponse = t.astTimeout;
    } catch (e) {
      // Google saturé (même après les modèles de secours) : message clair, sans anglais
      reponse = e.toString().toLowerCase().contains('quota')
          ? t.astQuota
          : PhotoIaService.surcharge(e)
              ? t.astBusy
              : '${t.astError}\n(${AssistantService.raison(e)})';
    }
    if (!mounted) return;
    setState(() {
      _echanges[_echanges.length - 1] = (question, reponse);
      _reflechit = false;
    });
    _sauver();
    _enBas();
    if (_lireReponses) unawaited(_lire(reponse));
  }

  /// Lecture unique des 30 derniers jours (réutilisée pour toutes les questions)
  Future<void> _charger() async {
    final t = AppLocalizations.of(context);
    try {
      final produits = ref.read(produitsStreamProvider).value ?? const [];
      final boutiques = ref.read(boutiquesActivesProvider(widget.entrepriseId));
      final devise = ref.read(currencyProvider);
      final resume = await AssistantService.charger(
        entrepriseId: widget.entrepriseId,
        produits: produits,
        nomsBoutiques: {for (final b in boutiques) b.id: b.nom},
        tauxCDF: devise.currencies['CDF']?.rateToUSD ?? 0,
      ).timeout(const Duration(seconds: 30));
      if (mounted) setState(() => _resume = resume);
    } catch (e) {
      if (mounted) setState(() => _erreur = t.astLoadError);
    }
  }

  Future<void> _envoyer([String? texte]) async {
    final t = AppLocalizations.of(context);
    final q = (texte ?? _question.text).trim();
    final resume = _resume;
    if (q.isEmpty || resume == null || _reflechit) return;
    _question.clear();
    setState(() {
      _reflechit = true;
      _echanges.add((q, ''));
    });
    _enBas();
    var reponse = '';
    try {
      // ⚡ Le texte s'affiche au fur et à mesure qu'il arrive
      await for (final partiel in AssistantService.demander(
        resume: resume,
        question: q,
        langue: Localizations.localeOf(context).languageCode,
        historique: _echanges.sublist(0, _echanges.length - 1),
      )) {
        reponse = partiel;
        if (!mounted) return;
        setState(() => _echanges[_echanges.length - 1] = (q, reponse));
        _enBas();
      }
      if (reponse.isEmpty) reponse = t.astNoAnswer;
    } on TimeoutException {
      reponse = reponse.isNotEmpty ? reponse : t.astTimeout;
    } catch (e) {
      // Google saturé (même après les modèles de secours) : message clair, sans anglais
      reponse = e.toString().toLowerCase().contains('quota')
          ? t.astQuota
          : PhotoIaService.surcharge(e)
              ? t.astBusy
              : '${t.astError}\n(${AssistantService.raison(e)})';
    }
    if (!mounted) return;
    setState(() {
      _echanges[_echanges.length - 1] = (q, reponse);
      _reflechit = false;
    });
    _sauver();
    _enBas();
  }

  void _enBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_defilement.hasClients) {
        _defilement.animateTo(_defilement.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Widget _bulle(String texte, {required bool moi}) {
    final t = AppLocalizations.of(context);
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final bulle = Align(
      alignment: moi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: moi
              ? const Color(0xFF1E3A8A)
              : (sombre ? const Color(0xFF22262E) : Colors.teal.shade50),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              // Au cas où l'IA met quand même du markdown : on retire ** et # en début de ligne
              moi ? texte : texte.replaceAll('**', '').replaceAll(RegExp(r'^#+\s*', multiLine: true), ''),
              style: TextStyle(color: moi ? Colors.white : null, fontSize: 15, height: 1.35),
            ),
            // 🔊 Réécouter la réponse
            if (!moi)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: t.astReadAloud,
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                onPressed: () => _lire(texte),
              ),
          ],
        ),
      ),
    );
    if (moi) return bulle;
    // 👩🏾 Le visage de Nguli à côté de chaque réponse
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 6, right: 6), child: AvatarNguli(taille: 30)),
        Flexible(child: bulle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final suggestions = [t.astSuggest1, t.astSuggest2, t.astSuggest3, t.astSuggest4];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const AvatarNguli(taille: 34),
          const SizedBox(width: 10),
          const Flexible(child: Text('Nguli', overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          // 🕘 Discussions passées et ➕ nouvelle discussion
          IconButton(
            tooltip: t.astHistory,
            icon: const Icon(Icons.history_rounded),
            onPressed: _reflechit || _ecoute ? null : _ouvrirHistorique,
          ),
          IconButton(
            tooltip: t.astNew,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _reflechit || _ecoute || _echanges.isEmpty ? null : _nouvelleDiscussion,
          ),
          // 🔊 Lire (ou non) les réponses à voix haute
          IconButton(
            tooltip: _lireReponses ? t.astVoiceOff : t.astVoiceOn,
            icon: Icon(_lireReponses ? Icons.volume_up_rounded : Icons.volume_off_rounded),
            onPressed: () {
              setState(() => _lireReponses = !_lireReponses);
              if (!_lireReponses) _voix.stop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _erreur != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_erreur!, textAlign: TextAlign.center)))
                : _resume == null
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const AvatarNguli(taille: 96),
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(t.astLoading),
                        ]),
                      )
                    : ListView(
                        controller: _defilement,
                        padding: const EdgeInsets.all(12),
                        children: [
                          _bulle(t.astIntro, moi: false),
                          if (_echanges.isEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final s in suggestions)
                                  ActionChip(label: Text(s), onPressed: () => _envoyer(s)),
                              ],
                            ),
                          for (final (q, r) in _echanges) ...[
                            _bulle(q, moi: true),
                            if (r.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Row(children: [
                                  AvatarNguli(taille: 30),
                                  SizedBox(width: 10),
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                ]),
                              )
                            else
                              _bulle(r, moi: false),
                          ],
                        ],
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _question,
                        enabled: _resume != null,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _envoyer(),
                        decoration: InputDecoration(
                          hintText: t.astPlaceholder,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 🎤 Parler au lieu de taper
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: _ecoute ? Colors.red : Colors.teal),
                      tooltip: t.astMicTip,
                      icon: Icon(_ecoute ? Icons.stop_rounded : Icons.mic_rounded),
                      onPressed: _resume == null || _reflechit ? null : _microAppui,
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _resume == null || _reflechit ? null : () => _envoyer(),
                    ),
                  ]),
                  if (_ecoute)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(t.astListening,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 4),
                  Text(t.astDisclaimer,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
