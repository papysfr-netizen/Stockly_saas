import 'package:flutter/material.dart';

import '../../core/services/packing_list_service.dart';

/// 📥 Écran d'aperçu avant import : on voit tout, on choisit, puis on confirme.
class ImportApercuScreen extends StatefulWidget {
  final AnalyseImport analyse;
  final PackingListService service;

  const ImportApercuScreen({super.key, required this.analyse, required this.service});

  @override
  State<ImportApercuScreen> createState() => _ImportApercuScreenState();
}

class _ImportApercuScreenState extends State<ImportApercuScreen> {
  ModeImport _mode = ModeImport.arrivage;
  bool _enCours = false;
  String _progression = '';

  String _prix(double v) => v <= 0 ? '—' : v.toStringAsFixed(2);

  Future<void> _importer() async {
    final a = widget.analyse;
    final aEcrire = a.nbNouveaux + a.nbExistants;
    if (aEcrire == 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer l'import"),
        content: Text(
          '${a.nbNouveaux} nouveau(x) produit(s)\n'
          '${a.nbExistants} produit(s) mis à jour\n'
          '${a.nbIgnores} ligne(s) ignorée(s)\n\n'
          '${_mode == ModeImport.arrivage ? 'Mode ARRIVAGE : les quantités seront AJOUTÉES au stock.' : 'Mode INVENTAIRE : le stock sera REMPLACÉ par les quantités du fichier.'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importer')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _enCours = true;
      _progression = 'Enregistrement…';
    });

    final navigator = Navigator.of(context);
    try {
      final resultat = await widget.service.appliquer(
        a,
        _mode,
        onProgress: (faits, total) {
          if (mounted) setState(() => _progression = 'Enregistrement : $faits / $total');
        },
      );
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Import terminé'),
            ],
          ),
          content: Text(
            '🟢 ${resultat.nouveaux} nouveau(x) produit(s)\n'
            '🔵 ${resultat.misAJour} produit(s) mis à jour\n'
            '⚪ ${resultat.ignores} ligne(s) ignorée(s)'
            '${resultat.horsLigne ? '\n\nPas d\'internet : les changements seront envoyés au retour du réseau.' : ''}',
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
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
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
            trouvee != null ? '« $trouvee »' : 'non trouvée',
            style: TextStyle(
              color: trouvee != null ? Colors.black87 : Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tuile(LigneImport l) {
    switch (l.statut) {
      case StatutLigne.nouveau:
        return ListTile(
          dense: true,
          leading: const Icon(Icons.add_circle, color: Colors.green),
          title: Text(l.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Nouveau produit • Qté : ${l.quantite}'
            '${l.codeBarre.isNotEmpty ? ' • Code : ${l.codeBarre}' : ''}\n'
            'Prix achat : ${_prix(l.prixAchat)} • Prix vente : ${_prix(l.prixVente)}',
          ),
          isThreeLine: true,
        );
      case StatutLigne.existant:
        return ListTile(
          dense: true,
          leading: Icon(Icons.sync, color: Colors.blue.shade700),
          title: Text(l.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Existe déjà${l.nomExistant.isNotEmpty && l.nomExistant != l.nom ? ' (« ${l.nomExistant} »)' : ''} • '
            'Stock : ${l.stockActuel} → ${l.nouveauStock(_mode)}\n'
            'Prix achat : ${l.prixAchat > 0 ? _prix(l.prixAchat) : 'inchangé'} • '
            'Prix vente : ${l.prixVente > 0 ? _prix(l.prixVente) : 'inchangé'}',
          ),
          isThreeLine: true,
        );
      case StatutLigne.ignore:
        return ListTile(
          dense: true,
          leading: const Icon(Icons.block, color: Colors.grey),
          title: Text(l.nom, style: const TextStyle(color: Colors.grey)),
          subtitle: Text('Ligne ${l.numeroLigne} ignorée : ${l.raison}'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analyse;
    final aEcrire = a.nbNouveaux + a.nbExistants;

    return PopScope(
      canPop: !_enCours,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Aperçu de l'import"),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
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
                          const Text('Colonnes reconnues :',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          _colonne('Code-barres', 'code'),
                          _colonne('Nom', 'nom'),
                          _colonne('Quantité', 'quantite'),
                          _colonne("Prix d'achat", 'prixAchat'),
                          _colonne('Prix de vente', 'prixVente'),
                          if (!a.avecEntete)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Pas de ligne de titres : l'ordre A=Code, B=Nom, C=Qté, D=Prix achat, E=Prix vente est utilisé.",
                                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Choix du mode
                  const Text('Type d\'import :', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SegmentedButton<ModeImport>(
                    segments: const [
                      ButtonSegment(
                        value: ModeImport.arrivage,
                        icon: Icon(Icons.add_box),
                        label: Text('Arrivage'),
                      ),
                      ButtonSegment(
                        value: ModeImport.inventaire,
                        icon: Icon(Icons.fact_check),
                        label: Text('Inventaire'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: _enCours ? null : (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _mode == ModeImport.arrivage
                        ? 'Les quantités du fichier sont AJOUTÉES au stock actuel (nouvelle marchandise reçue).'
                        : 'Le stock est REMPLACÉ par les quantités du fichier (après un comptage physique).',
                    style: TextStyle(
                      fontSize: 12,
                      color: _mode == ModeImport.arrivage ? Colors.teal.shade800 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Résumé
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.add_circle, color: Colors.green, size: 18),
                        label: Text('${a.nbNouveaux} nouveau(x)'),
                      ),
                      Chip(
                        avatar: Icon(Icons.sync, color: Colors.blue.shade700, size: 18),
                        label: Text('${a.nbExistants} mis à jour'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.block, color: Colors.grey, size: 18),
                        label: Text('${a.nbIgnores} ignoré(s)'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (a.lignes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Aucun produit trouvé dans ce fichier.')),
                    )
                  else
                    ...a.lignes.map(_tuile),
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
                    onPressed: (_enCours || aEcrire == 0) ? null : _importer,
                    icon: _enCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.file_download_done),
                    label: Text(
                      _enCours ? _progression : 'Importer $aEcrire produit(s)',
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