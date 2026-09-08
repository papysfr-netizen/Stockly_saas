// lib/models/payment_method.dart

enum PaymentMethod {
  cash,
  bank,
  mobileMoney,
  credit;

  /// Libellé d'affichage pour l'interface utilisateur
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.bank:
        return 'Banque / Virement';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.credit:
        return 'Crédit / À terme';
    }
  }

  /// Code comptable de trésorerie/tiers associé (SYSCOHADA)
  String get accountCode {
    switch (this) {
      case PaymentMethod.cash:
        return '571000'; // Caisse
      case PaymentMethod.bank:
        return '521000'; // Banque
      case PaymentMethod.mobileMoney:
        return '572000'; // Monnaie Électronique
      case PaymentMethod.credit:
        return '411000'; // Créances Clients (ou 401000 Fournisseurs)
    }
  }

  /// Deserialization sécurisée depuis Firebase / JSON
  static PaymentMethod fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'cash':
      case 'especes':
      case 'espèces':
        return PaymentMethod.cash;
      case 'bank':
      case 'banque':
        return PaymentMethod.bank;
      case 'mobilemoney':
      case 'mobile_money':
        return PaymentMethod.mobileMoney;
      case 'credit':
      case 'creance':
      case 'dette':
        return PaymentMethod.credit;
      default:
        return PaymentMethod.cash;
    }
  }
}