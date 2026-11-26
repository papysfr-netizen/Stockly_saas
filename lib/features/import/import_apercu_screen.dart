import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:stockly_saas/core/utils/payment_calculator.dart';

import '../../core/services/packing_list_service.dart';
import 'package:stockly_saas/core/widgets/liste_paresseuse.dart';

/// 📥 Écran d'aperçu avant import : on voit tout, on choisit, puis on confirme.
class ImportApercuScreen extends StatefulWidget {
  final AnalyseImport analyse;
  final PackingListService service;

  const ImportApercuScreen({super.key, required this.analyse, required this.service});

  @override
  State<ImportApercuScreen> createState() => _ImportApercuScreenState();
}

class _ImportApercuScreenState extends State<ImportApercuScreen> {
  // 🌙 Mode sombre
  bool get _sombre => Theme.of(context).brightness == Brightness.dark;
  Color get _fondPage => _sombre ? const Color(0xFF121418) : const Color(0xFFF3F4F6);
  Color get _fondCarte => _sombre ? const Color(0xFF1C1F26) : Colors.white;
  Color get _fondChamp => _sombre ? const Color(0xFF22262E) : Colors.white;
  Color _pastel(Color clair, Color base) => _sombre ? base.withValues(alpha: 0.22) : clair;
  ModeImport _mode = ModeImport.arrivage;
  bool _enCours = false;
  // 📦 Fiche de l'arrivage
  late final _fournisseur = TextEditingController(text: widget.analyse.fournisseur);
  late final _numero = TextEditingController(text: widget.analyse.numero);
  // Frais de l'arrivage (fret, transport…), en dollars — lus par l'IA ou saisis
  late final _frais = TextEditingController(
      text: widget.analyse.frais > 0 ? widget.analyse.frais.toStringAsFixed(2) : '');

  @override
  void dispose() {
    _fournisseur.dispose();
    _numero.dispose();
    _frais.dispose();
    super.dispose();
  }
  String _progression = '';

  String _prix(double v) => v <= 0 ? '—' : v.toStringAsFixed(2);

  Future<void> _importer() async {
    final a = widget.analyse;
    final aEcrire = a.nbNouveaux + a.nbExistants;
    if (aEcrire == 0 || a.nbAChoisir > 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).impConfirm),
        content: Text(
          AppLocalizations.of(context).impConfirmBody('${a.nbNouveaux}', '${a.nbExistants}', '${a.nbIgnores}') + (_mode == ModeImport.arrivage ? AppLocalizations.of(context).impModeArrivalWarn : AppLocalizations.of(context).impModeInventoryWarn),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).impImport)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _enCours = true;
      _progression = AppLocalizations.of(context).impSaving;
    });

    final navigator = Navigator.of(context);
    a.fournisseur = _fournisseur.text;
    a.numero = _numero.text;
    a.frais = parseAmount(_frais.text);
    try {
      final resultat = await widget.service.appliquer(
        a,
        _mode,
        onProgress: (faits, total) {
          if (mounted) setState(() => _progression = AppLocalizations.of(context).impSavingProgress('$faits', '$total'));
        },
      );
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).impDone),
            ],
          ),
          content: Text(
            AppLocalizations.of(context).impDoneBody('${resultat.nouveaux}', '${resultat.misAJour}', '${resultat.ignores}') + (resultat.horsLigne ? '\n\n${AppLocalizations.of(context).impOffline}' : ''),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      navigator.pop(resultat);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorWith('$e')), backgroundColor: Colors.red),
      );
    }
  }

  Widget _colonne(String titre, String cle) {
    final trouvee = widget.analyse.colonnes[cle];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(trouvee != null ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 16, color: trouvee != null ? Colors.green : Colors.orange.shade800),
          const SizedBox(width: 6),
          Expanded(child: Text(titre)),
          Text(
            trouvee != null ? '« $trouvee »' : AppLocalizations.of(context).impColMissing,
            style: TextStyle(
              color: trouvee != null ? (_sombre ? Colors.white : Colors.black87) : Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🟠 Cas douteux : l'utilisateur choisit « même produit » ou « nouveau produit »
  Widget _tuileDouteuse(LigneImport l) {
    final choisi = l.memeProduit;
    return Card(
      color: _pastel(Colors.orange.shade50, Colors.orange),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: choisi == null ? Colors.orange.shade700 : Colors.orange.shade200,
          width: choisi == null ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_rounded, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(AppLocalizations.of(context).impCheck(l.doute),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).impFileLine(l.nom), style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(AppLocalizations.of(context).impCodeQty(l.codeBarre.isEmpty ? '—' : l.codeBarre, '${l.quantite}'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context).impAlready(l.nomCandidat), style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(AppLocalizations.of(context).impCodeStock(l.codeCandidat.isEmpty ? '—' : l.codeCandidat, '${l.stockCandidat}'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(AppLocalizations.of(context).impSame),
                  selected: choisi == true,
                  onSelected: _enCours ? null : (_) => setState(() => l.choisir(true)),
                ),
                ChoiceChip(
                  label: Text(AppLocalizations.of(context).impNew),
                  selected: choisi == false,
                  onSelected: _enCours ? null : (_) => setState(() => l.choisir(false)),
                ),
              ],
            ),
            if (choisi == true)
              Text(AppLocalizations.of(context).impStockChange('${l.stockActuel}', '${l.nouveauStock(_mode)}'),
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
            if (choisi == false)
              Text(AppLocalizations.of(context).impWillCreate('${l.quantite}'),
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _tuile(LigneImport l) {
    if (l.douteux && l.statut != StatutLigne.ignore) return _tuileDouteuse(l);
    switch (l.statut) {
      case StatutLigne.nouveau:
        return ListTile(
          dense: true,
          leading: const Icon(Icons.add_circle, color: Colors.green),
          title: Text(l.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            AppLocalizations.of(context).impNewLine('${l.quantite}', l.codeBarre.isNotEmpty ? ' • ${l.codeBarre}' : '', _prix(l.prixAchat), _prix(l.prixVente)),
          ),
          isThreeLine: true,
        );
      case StatutLigne.existant:
        return ListTile(
          dense: true,
          leading: Icon(Icons.sync, color: Colors.blue.shade700),
          title: Text(l.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            AppLocalizations.of(context).impExistsLine(l.nomExistant.isNotEmpty && l.nomExistant != l.nom ? ' (« ${l.nomExistant} »)' : '', '${l.stockActuel}', '${l.nouveauStock(_mode)}', l.prixAchat > 0 ? _prix(l.prixAchat) : AppLocalizations.of(context).impUnchanged, l.prixVente > 0 ? _prix(l.prixVente) : AppLocalizations.of(context).impUnchanged),
          ),
          isThreeLine: true,
        );
      case StatutLigne.ignore:
        return ListTile(
          dense: true,
          leading: const Icon(Icons.block, color: Colors.grey),
          title: Text(l.nom, style: const TextStyle(color: Colors.grey)),
          subtitle: Text(AppLocalizations.of(context).impSkipped('${l.numeroLigne}', l.raison)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analyse;
    final aEcrire = a.nbNouveaux + a.nbExistants;
    // 🟠 Cas douteux (affichés en haut de la liste)
    final douteux = a.lignes.where((l) => l.douteux && l.statut != StatutLigne.ignore).toList();
    final autres = a.lignes.where((l) => !(l.douteux && l.statut != StatutLigne.ignore));

    return PopScope(
      canPop: !_enCours,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).impPreview),
          // ✖ Toujours un moyen d'annuler (rien n'est importé)
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: AppLocalizations.of(context).cancel,
            onPressed: _enCours ? null : () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListeParesseuse(
                padding: const EdgeInsets.all(12),
                elements: a.lignes.isEmpty ? const [] : [...douteux, ...autres],
                construire: (_, l) => _tuile(l),
                avant: [
                  // Fichier + colonnes reconnues
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.description, color: Colors.teal),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(a.nomFichier,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(AppLocalizations.of(context).impColumns,
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          _colonne(AppLocalizations.of(context).impColCode, 'code'),
                          _colonne(AppLocalizations.of(context).impColName, 'nom'),
                          _colonne(AppLocalizations.of(context).impColQty, 'quantite'),
                          _colonne(AppLocalizations.of(context).impColCost, 'prixAchat'),
                          _colonne(AppLocalizations.of(context).impColPrice, 'prixVente'),
                          if (!a.avecEntete)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                AppLocalizations.of(context).impNoHeader,
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Choix du mode
                  Text(AppLocalizations.of(context).impType, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SegmentedButton<ModeImport>(
                    segments: [
                      ButtonSegment(
                        value: ModeImport.arrivage,
                        icon: const Icon(Icons.add_box),
                        label: Text(AppLocalizations.of(context).lotArrival),
                      ),
                      ButtonSegment(
                        value: ModeImport.inventaire,
                        icon: const Icon(Icons.fact_check),
                        label: Text(AppLocalizations.of(context).impInventory),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: _enCours ? null : (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mode == ModeImport.arrivage
                        ? AppLocalizations.of(context).impModeArrivalInfo
                        : AppLocalizations.of(context).impModeInventoryInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: _mode == ModeImport.arrivage ? Colors.teal.shade800 : Colors.red.shade700,
                    ),
                  ),
                  // 📦 Arrivage : la packing list est gardée comme une fiche
                  if (_mode == ModeImport.arrivage) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fournisseur,
                            enabled: !_enCours,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).impSupplier,
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _numero,
                            enabled: !_enCours,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).impListNo,
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _frais,
                      enabled: !_enCours,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).impFees,
                        prefixText: '\$ ',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    // 🤖 Lu par l'IA : on le dit, pour que la personne vérifie
                    if (a.fournisseur.isNotEmpty || a.numero.isNotEmpty || a.dateFacture.isNotEmpty || a.frais > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          AppLocalizations.of(context).impReadByAi +
                              (a.dateFacture.isEmpty ? '' : ' · ${AppLocalizations.of(context).impInvoiceDate(a.dateFacture)}'),
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),

                  // Résumé
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.add_circle, color: Colors.green, size: 18),
                        label: Text(AppLocalizations.of(context).impChipNew('${a.nbNouveaux}')),
                      ),
                      Chip(
                        avatar: Icon(Icons.sync, color: Colors.blue.shade700, size: 18),
                        label: Text(AppLocalizations.of(context).impChipUpd('${a.nbExistants}')),
                      ),
                      Chip(
                        avatar: const Icon(Icons.block, color: Colors.grey, size: 18),
                        label: Text(AppLocalizations.of(context).impChipSkip('${a.nbIgnores}')),
                      ),
                      if (a.nbAChoisir > 0)
                        Chip(
                          backgroundColor: _pastel(Colors.orange.shade100, Colors.orange),
                          avatar: Icon(Icons.help_rounded, color: Colors.orange.shade800, size: 18),
                          label: Text(AppLocalizations.of(context).impChipCheck('${a.nbAChoisir}')),
                        ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 🟠 Cas douteux : explication + choix pour tous
                  if (douteux.isNotEmpty) ...[
                    Text(
                      a.nbAChoisir > 0
                          ? AppLocalizations.of(context).impToCheck('${a.nbAChoisir}')
                          : AppLocalizations.of(context).impChecked,
                      style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _enCours
                              ? null
                              : () => setState(() {
                                    for (final l in douteux) {
                                      l.choisir(true);
                                    }
                                  }),
                          child: Text(AppLocalizations.of(context).impAllSame),
                        ),
                        TextButton(
                          onPressed: _enCours
                              ? null
                              : () => setState(() {
                                    for (final l in douteux) {
                                      l.choisir(false);
                                    }
                                  }),
                          child: Text(AppLocalizations.of(context).impAllNew),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  if (a.lignes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(AppLocalizations.of(context).impEmpty)),
                    ),
                ],
              ),
            ),

            // Bouton d'import
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_enCours || aEcrire == 0 || a.nbAChoisir > 0) ? null : _importer,
                    icon: _enCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.file_download_done),
                    label: Text(
                      _enCours
                          ? _progression
                          : a.nbAChoisir > 0
                              ? AppLocalizations.of(context).impChooseFirst('${a.nbAChoisir}')
                              : AppLocalizations.of(context).impImportN('$aEcrire'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}