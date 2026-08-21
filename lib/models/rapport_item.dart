enum TypeRapport {
  dettesClient,
  dettesFournisseur,
  depenses,
  documents,
  transactions,
  livreCaisse,
  mouvementStock,
  profitsPertes,
  reassort,
  ventesArticles,
  ventesClient,
  ventesDate,
  ventesMois,
  ventesUtilisateur,
}

class RapportItem {
  final String id;
  final String titre;
  final TypeRapport type;
  bool estFavori;

  RapportItem({
    required this.id,
    required this.titre,
    required this.type,
    this.estFavori = false,
  });
}