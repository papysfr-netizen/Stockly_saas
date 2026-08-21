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

  int get accountClass => int.parse(code[0]);
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

  /// Conservation de la Map originale pour rétrocompatibilité directe
  static Map<String, String> get map => {
        for (var item in items) item.code: item.label,
      };

  /// Recherche par code ou libellé
  static List<AccountPlanItem> search(String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((e) => e.code.contains(q) || e.label.toLowerCase().contains(q))
        .toList();
  }

  /// Obtenir la liste des comptes filtrée par classe (ex: 6 pour les charges)
  static List<AccountPlanItem> byClass(int accountClass) {
    return items.where((e) => e.accountClass == accountClass).toList();
  }
}

/// Conservation de la Map constante originale pour éviter les breaking changes
final Map<String, String> planComptableStandard = PlanComptable.map;