// lib/services/plan_comptable_service.dart

class AccountModel {
  final String code;
  final String label;

  const AccountModel({
    required this.code,
    required this.label,
  });

  /// Numéro de la classe principale (1 à 8)
  String get accountClass => code.isNotEmpty ? code[0] : '';
}

class PlanComptableService {
  /// Extrait des principaux comptes du Référentiel SYSCOHADA Révisé
  static const List<AccountModel> _accounts = [
    // --- CLASSE 1 : COMPTES DE RESSOURCES DURABLES ---
    AccountModel(code: '101000', label: 'Capital social'),
    AccountModel(code: '111000', label: 'Réserve légale'),
    AccountModel(code: '121000', label: 'Report à nouveau créditeur'),
    AccountModel(code: '129000', label: 'Report à nouveau débiteur'),
    AccountModel(code: '130100', label: 'Résultat en instance d\'affectation (Bénéfice)'),
    AccountModel(code: '130900', label: 'Résultat en instance d\'affectation (Perte)'),
    AccountModel(code: '162000', label: 'Emprunts auprès des établissements de crédit'),

    // --- CLASSE 2 : COMPTES D'ACTIF IMMOBILISÉ ---
    AccountModel(code: '211000', label: 'Frais de développement'),
    AccountModel(code: '213000', label: 'Logiciels et droits similaires'),
    AccountModel(code: '221000', label: 'Terrains nus'),
    AccountModel(code: '231000', label: 'Bâtiments industriels'),
    AccountModel(code: '241000', label: 'Matériel et outillage industriel'),
    AccountModel(code: '244000', label: 'Matériel de transport'),
    AccountModel(code: '245000', label: 'Matériel informatique'),
    AccountModel(code: '284000', label: 'Amortissements du matériel'),

    // --- CLASSE 3 : COMPTES DE STOCKS ---
    AccountModel(code: '311000', label: 'Stock de marchandises A'),
    AccountModel(code: '321000', label: 'Stock de matières premières'),
    AccountModel(code: '361000', label: 'Stock de produits finis'),

    // --- CLASSE 4 : COMPTES DE TIERS ---
    AccountModel(code: '401100', label: 'Fournisseurs, dettes en compte'),
    AccountModel(code: '408100', label: 'Fournisseurs - Factures non parvenues'),
    AccountModel(code: '411100', label: 'Clients, créances en compte'),
    AccountModel(code: '418100', label: 'Clients - Factures à établir'),
    AccountModel(code: '421000', label: 'Personnel, rémunérations dues'),
    AccountModel(code: '431000', label: 'Sécurité sociale / Organismes sociaux'),
    AccountModel(code: '442100', label: 'État, impôts et taxes retenus à la source'),
    AccountModel(code: '443100', label: 'État, TVA facturée sur ventes'),
    AccountModel(code: '445100', label: 'État, TVA récupérable sur achats'),
    AccountModel(code: '471000', label: 'Comptes d\'attente'),

    // --- CLASSE 5 : COMPTES DE TRÉSORERIE ---
    AccountModel(code: '521100', label: 'Banque locale en monnaie nationale'),
    AccountModel(code: '521200', label: 'Banque en devises'),
    AccountModel(code: '531100', label: 'Chèques à encaisser'),
    AccountModel(code: '571100', label: 'Caisse principale'),
    AccountModel(code: '585000', label: 'Virements internes'),

    // --- CLASSE 6 : COMPTES DE CHARGES (ACTIVITÉS ORDINAIRES) ---
    AccountModel(code: '601100', label: 'Achats de marchandises dans la Région'),
    AccountModel(code: '602100', label: 'Achats de matières premières'),
    AccountModel(code: '604100', label: 'Achats d\'études et prestations de services'),
    AccountModel(code: '605100', label: 'Fournitures non stockables (Eau, Électricité)'),
    AccountModel(code: '612000', label: 'Transports sur ventes'),
    AccountModel(code: '622000', label: 'Locations et charges locatives'),
    AccountModel(code: '624000', label: 'Entretien, réparations et maintenance'),
    AccountModel(code: '625000', label: 'Primes d\'assurance'),
    AccountModel(code: '627000', label: 'Frais bancaires et d\'émission de titres'),
    AccountModel(code: '632000', label: 'Honoraires des professionnels libéraux'),
    AccountModel(code: '641000', label: 'Impôts et taxes directs'),
    AccountModel(code: '661000', label: 'Rémunérations directes versées au personnel'),
    AccountModel(code: '681000', label: 'Dotations aux amortissements d\'exploitation'),

    // --- CLASSE 7 : COMPTES DE PRODUITS (ACTIVITÉS ORDINAIRES) ---
    AccountModel(code: '701100', label: 'Ventes de marchandises dans la Région'),
    AccountModel(code: '702100', label: 'Ventes de produits finis'),
    AccountModel(code: '706100', label: 'Services vendus / Prestations'),
    AccountModel(code: '707100', label: 'Produits annexes'),
    AccountModel(code: '758000', label: 'Produits divers d\'exploitation'),
    AccountModel(code: '771000', label: 'Intérêts créditeurs et produits assimilés'),
  ];

  /// Liste complète du plan comptable
  static List<AccountModel> get allAccounts => _accounts;

  /// Recherche un compte par son numéro exact
  static AccountModel? findByCode(String code) {
    final cleanCode = code.trim();
    try {
      return _accounts.firstWhere((a) => a.code == cleanCode);
    } catch (_) {
      return null;
    }
  }

  /// Recherche filtrée pour un champ d'auto-complétion (par code ou libellé)
  static List<AccountModel> search(String query) {
    if (query.trim().isEmpty) return _accounts;

    final q = query.toLowerCase().trim();
    return _accounts.where((account) {
      return account.code.contains(q) ||
          account.label.toLowerCase().contains(q);
    }).toList();
  }

  /// Propose l'intitulé correspondant si le code existe, sinon retourne une valeur vide
  static String getLabelForCode(String code) {
    final match = findByCode(code);
    return match?.label ?? '';
  }
}