// lib/features/cloture/cloture_screen.dart
//
// 🔒 Écrans de la clôture de caisse :
//  - ClotureScreen : comptage du soir (à l'aveugle) + résultat si autorisé
//  - ClotureHistoriqueScreen : les clôtures passées (« Voir les finances »)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/core/services/utilisateur_service.dart';
import 'package:stockly_saas/core/utils/payment_calculator.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

import 'cloture_service.dart';

const _vert = Color(0xFF0B7A5A);

String _dollars(double x) => '${x.toStringAsFixed(2)} \$';

String _heure(Object? ts) {
  final d = ClotureService.date(ts);
  if (d == null) return '--:--';
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ============================================================================
// COMPTAGE DU SOIR
// ============================================================================
class ClotureScreen extends ConsumerStatefulWidget {
  final String entrepriseId;
  const ClotureScreen({super.key, required this.entrepriseId});

  @override
  ConsumerState<ClotureScreen> createState() => _ClotureScreenState();
}

class _ClotureScreenState extends ConsumerState<ClotureScreen> {
  final _fondUSD = TextEditingController();
  final _fondCDF = TextEditingController();
  final _compteUSD = TextEditingController();
  final _compteCDF = TextEditingController();
  final _compteMobile = TextEditingController();
  final _demainUSD = TextEditingController();
  final _demainCDF = TextEditingController();
  final _note = TextEditingController();

  String? _boutiqueChoisie; // patron « toutes les boutiques » : on demande
  String? _fondCharge; // boutique dont le fond a été pré-rempli
  bool _enregistrement = false;

  @override
  void dispose() {
    for (final c in [_fondUSD, _fondCDF, _compteUSD, _compteCDF, _compteMobile, _demainUSD, _demainCDF, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String _boutique() =>
      ref.read(boutiqueActiveProvider) ?? _boutiqueChoisie ?? 'principale';

  /// Le fond laissé hier pour aujourd'hui, pré-rempli une seule fois
  Future<void> _prechargerFond(String boutiqueId) async {
    if (_fondCharge == boutiqueId) return;
    _fondCharge = boutiqueId;
    final f = await ClotureService.fondPropose(widget.entrepriseId, boutiqueId);
    if (!mounted) return;
    setState(() {
      if (_fondUSD.text.isEmpty && f.usd > 0) _fondUSD.text = f.usd.toStringAsFixed(2);
      if (_fondCDF.text.isEmpty && f.cdf > 0) _fondCDF.text = f.cdf.toStringAsFixed(0);
    });
  }

  Future<void> _enregistrer(AppLocalizations t, double taux) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.cloConfirmTitle),
        content: Text(t.cloConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.cloSave)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _enregistrement = true);
    final boutiqueId = _boutique();
    final maintenant = DateTime.now();
    try {
      if (await ClotureService.estCloturee(widget.entrepriseId, boutiqueId, maintenant)) {
        throw Exception(t.cloAlreadyDone);
      }
      final nom = await nomUtilisateurConnecte();
      final envoi = ClotureService.enregistrer(
        entrepriseId: widget.entrepriseId,
        boutiqueId: boutiqueId,
        jour: maintenant,
        parNom: nom,
        taux: taux,
        fondUSD: parseAmount(_fondUSD.text),
        fondCDF: parseAmount(_fondCDF.text),
        compteUSD: parseAmount(_compteUSD.text),
        compteCDF: parseAmount(_compteCDF.text),
        compteMobile: parseAmount(_compteMobile.text),
        fondDemainUSD: parseAmount(_demainUSD.text),
        fondDemainCDF: parseAmount(_demainCDF.text),
        note: _note.text.trim(),
      );
      // Hors ligne : la clôture part au retour du réseau
      try {
        await envoi.timeout(const Duration(seconds: 6));
      } on Exception catch (e) {
        if (e is FirebaseException) rethrow;
      }
      if (!mounted) return;
      final voitResultat = ref.read(userProfileProvider).value?.peutVoirFinances ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(voitResultat ? t.cloSavedShort : t.cloSaved), backgroundColor: _vert),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final devise = ref.watch(currencyProvider);
    final taux = devise.currencies['CDF']?.rateToUSD ?? devise.bccCdfRate;
    final profil = ref.watch(userProfileProvider).value;
    final voirFinances = profil?.peutVoirFinances ?? false;
    final boutiqueActive = ref.watch(boutiqueActiveProvider);
    final boutiques = ref.watch(boutiquesActivesProvider(widget.entrepriseId));
    final boutiqueId = boutiqueActive ?? _boutiqueChoisie ?? 'principale';
    final aujourdhui = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) => _prechargerFond(boutiqueId));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.cloTitle),
        actions: [
          if (voirFinances)
            IconButton(
              tooltip: t.cloHistory,
              icon: const Icon(Icons.history_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClotureHistoriqueScreen(entrepriseId: widget.entrepriseId),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ClotureService.ecouter(widget.entrepriseId, boutiqueId, aujourdhui),
        builder: (context, snap) {
          final dejaFaite = snap.data?.exists == true;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 🏬 Boutique (choix seulement pour le patron sur « toutes »)
              if (boutiqueActive == null && boutiques.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: boutiqueId,
                  decoration: InputDecoration(
                    labelText: t.cloPickBoutique,
                    prefixIcon: const Icon(Icons.storefront_rounded),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final b in boutiques) DropdownMenuItem(value: b.id, child: Text(b.nom)),
                  ],
                  onChanged: (v) => setState(() {
                    _boutiqueChoisie = v;
                    _fondUSD.clear();
                    _fondCDF.clear();
                  }),
                ),
                const SizedBox(height: 16),
              ],

              if (dejaFaite) ...[
                _Bandeau(
                  icone: Icons.lock_rounded,
                  couleur: _vert,
                  texte: t.cloDoneBy(_heure(snap.data!.data()?['createdAt']),
                      (snap.data!.data()?['parNom'] ?? '').toString()),
                ),
                const SizedBox(height: 12),
                if (voirFinances)
                  CarteResultat(entrepriseId: widget.entrepriseId, cloture: snap.data!.data()!)
                else
                  Text(t.cloSaved, textAlign: TextAlign.center),
              ] else ...[
                _Bandeau(icone: Icons.visibility_off_rounded, couleur: Colors.indigo, texte: t.cloBlindInfo),
                const SizedBox(height: 16),
                _Titre(t.cloFloatMorning, Icons.savings_rounded),
                _DeuxMonnaies(usd: _fondUSD, cdf: _fondCDF, t: t),
                const SizedBox(height: 18),
                _Titre(t.cloCounted, Icons.payments_rounded),
                _DeuxMonnaies(usd: _compteUSD, cdf: _compteCDF, t: t),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(t.cloRate(taux.toStringAsFixed(0)),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
                const SizedBox(height: 18),
                _Titre(t.cloMobileReceived, Icons.phone_android_rounded),
                _Champ(controller: _compteMobile, label: t.cloInDollars, aide: t.cloMobileHint),
                const SizedBox(height: 18),
                _Titre(t.cloFloatTomorrow, Icons.wb_twilight_rounded),
                _DeuxMonnaies(usd: _demainUSD, cdf: _demainCDF, t: t),
                const SizedBox(height: 18),
                TextField(
                  controller: _note,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: t.cloNote,
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _vert,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _enregistrement ? null : () => _enregistrer(t, taux),
                  icon: _enregistrement
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_rounded),
                  label: Text(t.cloSave, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// RÉSULTAT (attendu / compté / écart) — réservé à « Voir les finances »
// ============================================================================
class CarteResultat extends ConsumerStatefulWidget {
  final String entrepriseId;
  final Map<String, dynamic> cloture;
  const CarteResultat({super.key, required this.entrepriseId, required this.cloture});

  @override
  ConsumerState<CarteResultat> createState() => _CarteResultatState();
}

class _CarteResultatState extends ConsumerState<CarteResultat> {
  // Calculé une seule fois (et pas à chaque rafraîchissement de l'écran)
  late Future<ResultatCloture> _resultat = _calculer();

  String get entrepriseId => widget.entrepriseId;
  Map<String, dynamic> get cloture => widget.cloture;

  @override
  void didUpdateWidget(covariant CarteResultat old) {
    super.didUpdateWidget(old);
    if (old.cloture['jour'] != widget.cloture['jour'] ||
        old.cloture['boutiqueId'] != widget.cloture['boutiqueId'] ||
        old.cloture['createdAt'] != widget.cloture['createdAt']) {
      _resultat = _calculer();
    }
  }

  Future<ResultatCloture> _calculer() async {
    final jour = DateTime.tryParse((cloture['jour'] ?? '').toString()) ?? DateTime.now();
    final debut = DateTime(jour.year, jour.month, jour.day);
    final fin = ClotureService.date(cloture['createdAt']) ?? DateTime.now();
    final attendu = await ClotureService.calculerAttendu(
      entrepriseId: entrepriseId,
      boutiqueId: (cloture['boutiqueId'] ?? 'principale').toString(),
      debut: debut,
      fin: fin,
    );
    return ResultatCloture(cloture, attendu);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final profil = ref.watch(userProfileProvider).value;
    final peutRouvrir = profil?.role.isAdminOrOwner ?? false;

    return FutureBuilder<ResultatCloture>(
      future: _resultat,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(snap.hasError ? '${snap.error}' : t.cloLoading),
            ]),
          );
        }
        final r = snap.data!;
        final a = r.attendu;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.cloResult, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _LigneEcart(
                titre: t.cloCash, attendu: r.especesAttendues, compte: r.especesComptees, ecart: r.ecartEspeces, t: t),
            const SizedBox(height: 10),
            _LigneEcart(
                titre: t.cloMobile, attendu: r.mobileAttendu, compte: r.mobileCompte, ecart: r.ecartMobile, t: t),
            if (a.ventesApresCloture > 0) ...[
              const SizedBox(height: 10),
              _Bandeau(
                icone: Icons.schedule_rounded,
                couleur: Colors.orange.shade800,
                texte: t.cloAfterSales('${a.ventesApresCloture}', _dollars(a.montantApresCloture)),
              ),
            ],
            if (a.depensesIllisibles) ...[
              const SizedBox(height: 10),
              _Bandeau(icone: Icons.warning_amber_rounded, couleur: Colors.red, texte: t.cloExpensesHidden),
            ],
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(t.cloDetail, style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                _Detail(t.cloLineFloat, r.fond),
                _Detail('${t.cloLineSales} — ${t.cloCash}', a.ventesEspeces),
                _Detail('${t.cloLineSales} — ${t.cloMobile}', a.ventesMobile),
                _Detail('${t.cloLineDebts} — ${t.cloCash}', a.dettesEspeces),
                _Detail('${t.cloLineDebts} — ${t.cloMobile}', a.dettesMobile),
                _Detail(t.cloLineDeposits, a.depotsEspeces + a.depotsMobile),
                _Detail(t.cloLineWithdrawals, -(a.retraitsEspeces + a.retraitsMobile)),
                _Detail(t.cloLineExpenses, -(a.depensesEspeces + a.depensesMobile)),
                _Detail(t.cloLineSuppliers, -(a.fournisseursEspeces + a.fournisseursMobile)),
                _Detail(t.cloLineRefunds, -a.remboursementsEspeces),
                if (a.autres > 0.005) _Detail(t.cloLineOther, a.autres, gris: true),
                if ((cloture['note'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('📝 ${cloture['note']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
            if (peutRouvrir) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(t.cloReopen),
                onPressed: () => _rouvrir(context, t),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _rouvrir(BuildContext context, AppLocalizations t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.cloReopenConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.cloReopen),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final boutiqueId = (cloture['boutiqueId'] ?? 'principale').toString();
    final jour = (cloture['jour'] ?? '').toString();
    await ClotureService.collection(entrepriseId).doc('${boutiqueId}_$jour').delete();
  }
}

class _LigneEcart extends StatelessWidget {
  final String titre;
  final double attendu, compte, ecart;
  final AppLocalizations t;
  const _LigneEcart(
      {required this.titre, required this.attendu, required this.compte, required this.ecart, required this.t});

  @override
  Widget build(BuildContext context) {
    final juste = ResultatCloture.juste(ecart);
    final couleur = juste ? _vert : (ecart < 0 ? Colors.red : Colors.orange.shade800);
    final verdict = juste
        ? t.cloOk
        : (ecart < 0 ? t.cloMissing(_dollars(-ecart)) : t.cloSurplus(_dollars(ecart)));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Text(verdict, style: TextStyle(fontWeight: FontWeight.bold, color: couleur)),
          ]),
          const SizedBox(height: 6),
          Text('${t.cloExpected} : ${_dollars(attendu)}   ·   ${t.cloCountedShort} : ${_dollars(compte)}'),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String libelle;
  final double montant;
  final bool gris;
  const _Detail(this.libelle, this.montant, {this.gris = false});

  @override
  Widget build(BuildContext context) {
    if (montant.abs() < 0.005 && !gris) return const SizedBox.shrink();
    final style = TextStyle(color: gris ? Colors.grey : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(libelle, style: style)),
        Text(_dollars(montant), style: style.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ============================================================================
// HISTORIQUE
// ============================================================================
class ClotureHistoriqueScreen extends ConsumerWidget {
  final String entrepriseId;
  const ClotureHistoriqueScreen({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final boutiques = ref.watch(boutiquesProvider(entrepriseId)).value ?? const [];
    String nomBoutique(String id) =>
        boutiques.where((b) => b.id == id).map((b) => b.nom).firstOrNull ?? id;

    return Scaffold(
      appBar: AppBar(title: Text(t.cloHistory)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ClotureService.collection(entrepriseId)
            .orderBy('createdAt', descending: true)
            .limit(60)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Center(child: Text(t.cloHistoryEmpty));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final c = docs[i].data();
              return Card(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: ExpansionTile(
                  leading: const Icon(Icons.lock_rounded, color: _vert),
                  title: Text('${c['jour']} — ${nomBoutique((c['boutiqueId'] ?? '').toString())}'),
                  subtitle: Text(t.cloBy((c['parNom'] ?? '').toString(), _heure(c['createdAt']))),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [CarteResultat(entrepriseId: entrepriseId, cloture: c)],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// Petits éléments
// ============================================================================
class _Bandeau extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String texte;
  const _Bandeau({required this.icone, required this.couleur, required this.texte});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icone, color: couleur),
          const SizedBox(width: 10),
          Expanded(child: Text(texte)),
        ]),
      );
}

class _Titre extends StatelessWidget {
  final String texte;
  final IconData icone;
  const _Titre(this.texte, this.icone);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icone, size: 20, color: _vert),
          const SizedBox(width: 8),
          Expanded(child: Text(texte, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        ]),
      );
}

class _Champ extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? aide;
  const _Champ({required this.controller, required this.label, this.aide});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          helperText: aide,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
      );
}

class _DeuxMonnaies extends StatelessWidget {
  final TextEditingController usd, cdf;
  final AppLocalizations t;
  const _DeuxMonnaies({required this.usd, required this.cdf, required this.t});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _Champ(controller: usd, label: t.cloInDollars)),
        const SizedBox(width: 10),
        Expanded(child: _Champ(controller: cdf, label: t.cloInFrancs)),
      ]);
}
