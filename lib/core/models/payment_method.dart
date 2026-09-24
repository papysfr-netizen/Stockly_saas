// lib/core/models/payment_method.dart

enum PaymentMethod {
  cash,
  bank,
  bankTransfer,
  check,
  mobileMoney,
  credit;

  /// Libellé d'affichage pour l'interface utilisateur
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.bank:
      case PaymentMethod.bankTransfer:
        return 'Banque / Virement';
      case PaymentMethod.check:
        return 'Chèque';
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
      case PaymentMethod.bankTransfer:
      case PaymentMethod.check:
        return '521000'; // Banque / Chèque
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
      case 'banktransfer':
      case 'bank_transfer':
      case 'virement':
        return PaymentMethod.bankTransfer;
      case 'check':
      case 'cheque':
        return PaymentMethod.check;
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