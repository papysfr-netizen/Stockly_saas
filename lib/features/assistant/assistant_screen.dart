// ✨ Écran « Demandez à Nguli » (Rapport → bouton ✨)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/currency_provider.dart';
import '../../core/providers/produit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../boutiques/boutique_provider.dart';
import 'assistant_service.dart';

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
  Map<String, dynamic>? _resume;
  String? _erreur;
  bool _reflechit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  void dispose() {
    _question.dispose();
    _defilement.dispose();
    super.dispose();
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
    String reponse;
    try {
      reponse = await AssistantService.demander(
        resume: resume,
        question: q,
        langue: Localizations.localeOf(context).languageCode,
        historique: _echanges.sublist(0, _echanges.length - 1),
      );
      if (reponse.isEmpty) reponse = t.astNoAnswer;
    } on TimeoutException {
      reponse = t.astTimeout;
    } catch (_) {
      reponse = t.astError;
    }
    if (!mounted) return;
    setState(() {
      _echanges[_echanges.length - 1] = (q, reponse);
      _reflechit = false;
    });
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
    final sombre = Theme.of(context).brightness == Brightness.dark;
    return Align(
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
        child: SelectableText(
          texte,
          style: TextStyle(color: moi ? Colors.white : null, fontSize: 15, height: 1.35),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final suggestions = [t.astSuggest1, t.astSuggest2, t.astSuggest3, t.astSuggest4];
    return Scaffold(
      appBar: AppBar(title: Text(t.astTitle)),
      body: Column(
        children: [
          Expanded(
            child: _erreur != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_erreur!, textAlign: TextAlign.center)))
                : _resume == null
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                                padding: EdgeInsets.all(8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
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
                    IconButton.filled(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _resume == null || _reflechit ? null : () => _envoyer(),
                    ),
                  ]),
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
