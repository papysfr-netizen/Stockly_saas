// lib/constants/plan_comptable.dart

enum AccountType { asset, liability, equity, revenue, expense }

enum NormalBalance { debit, credit }

class AccountPlanItem {
  final String code;
  final String label;
  final AccountType type;
  final NormalBalance normalBalance;

  const AccountPlanItem({
    required this.code,
    required this.label,
    required this.type,
    required this.normalBalance,
  });

  /// Extrait le numéro de classe de façon sécurisée
  int get accountClass =>
      int.tryParse(code.isNotEmpty ? code[0] : '0') ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountPlanItem &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$code - $label';
}

/// Modèle du Plan Comptable SYSCOHADA Révisé adapté à la gestion de stock SaaS
class PlanComptable {
  static const List<AccountPlanItem> items = [
    // --- CLASSE 1 : CAPITAUX PROPRES ET RESSOURCES ASSIMILÉES ---
    AccountPlanItem(
      code: '101000',
      label: 'Capital social',
      type: AccountType.equity,
      normalBalance: NormalBalance.credit,
    ),
    AccountPlanItem(
      code: '131000',
      label: 'Résultat net de l\'exercice',
      type: AccountType.equity,
      normalBalance: NormalBalance.credit,
    ),

    // --- CLASSE 2 : COMPTES D\'ACTIF IMMOBILISÉ ---
    AccountPlanItem(
      code: '241000',
      label: 'Matériel et équipement',
      type: AccountType.asset,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '284100',
      label: 'Amortissement du matériel',
      type: AccountType.asset,
      normalBalance: NormalBalance.credit,
    ),

    // --- CLASSE 3 : COMPTES DE STOCKS ET EN-COURS ---
    AccountPlanItem(
      code: '311000',
      label: 'Stock de marchandises',
      type: AccountType.asset,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '391000',
      label: 'Dépréciation des stocks de marchandises',
      type: AccountType.asset,
      normalBalance: NormalBalance.credit,
    ),

    // --- CLASSE 4 : COMPTES DE TIERS (Achats/Ventes/Taxes) ---
    AccountPlanItem(
      code: '401000',
      label: 'Fournisseurs',
      type: AccountType.liability,
      normalBalance: NormalBalance.credit,
    ),
    AccountPlanItem(
      code: '411000',
      label: 'Clients',
      type: AccountType.asset,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '443100',
      label: 'TVA facturée sur ventes',
      type: AccountType.liability,
      normalBalance: NormalBalance.credit,
    ),
    AccountPlanItem(
      code: '445200',
      label: 'TVA récupérable sur achats',
      type: AccountType.asset,
      normalBalance: NormalBalance.debit,
    ),

    // --- CLASSE 5 : COMPTES DE TRÉSORERIE ---
    AccountPlanItem(
      code: '521000',
      label: 'Banque',
      type: AccountType.asset,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '571000',
      label: 'Caisse',
      type: AccountType.asset,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '572000',
      label: 'Mobile Money (Airtel/M-Pesa/Orange)',
      type: AccountType.asset,
      normalBalance: NormalBalance.debit,
    ),

    // --- CLASSE 6 : COMPTES DE CHARGES ---
    AccountPlanItem(
      code: '601000',
      label: 'Achats de marchandises',
      type: AccountType.expense,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '603100',
      label: 'Variation des stocks de marchandises',
      type: AccountType.expense,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '613000',
      label: 'Loyers',
      type: AccountType.expense,
      normalBalance: NormalBalance.debit,
    ),
    AccountPlanItem(
      code: '661000',
      label: 'Charges de personnel',
      type: AccountType.expense,
      normalBalance: NormalBalance.debit,
    ),

    // --- CLASSE 7 : COMPTES DE PRODUITS ---
    AccountPlanItem(
      code: '701000',
      label: 'Ventes de marchandises',
      type: AccountType.revenue,
      normalBalance: NormalBalance.credit,
    ),
    AccountPlanItem(
      code: '709100',
      label: 'Rabais, remises et ristournes accordés',
      type: AccountType.revenue,
      normalBalance: NormalBalance.debit,
    ),
  ];

  /// Indexation rapide par code $O(1)$
  static final Map<String, AccountPlanItem> _byCodeMap = {
    for (var item in items) item.code: item,
  };

  /// Conservation de la Map originale pour rétrocompatibilité directe
  static Map<String, String> get map => {
        for (var item in items) item.code: item.label,
      };

  /// Recherche rapide d'un compte par son code exact $O(1)$
  static AccountPlanItem? findByCode(String code) => _byCodeMap[code.trim()];

  /// Recherche par code ou libellé (insensible à la casse)
  static List<AccountPlanItem> search(String query) {
    if (query.isEmpty) return items;
    final q = query.trim().toLowerCase();
    return items
        .where((e) => e.code.contains(q) || e.label.toLowerCase().contains(q))
        .toList();
  }

  /// Obtenir la liste des comptes filtrée par classe (ex: 6 pour les charges)
  static List<AccountPlanItem> byClass(int accountClass) {
    return items.where((e) => e.accountClass == accountClass).toList();
  }

  /// Obtenir la liste des comptes par type comptable
  static List<AccountPlanItem> byType(AccountType type) {
    return items.where((e) => e.type == type).toList();
  }
}

/// Conservation de la Map constante originale pour éviter les breaking changes
final Map<String, String> planComptableStandard = PlanComptable.map;