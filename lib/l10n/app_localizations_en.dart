// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stockly Pro';

  @override
  String get settings => 'Settings';

  @override
  String get storeInfo => 'Store information';

  @override
  String get storeName => 'Store name';

  @override
  String get address => 'Address';

  @override
  String get phone => 'Phone';

  @override
  String get saveInfo => 'Save information';

  @override
  String get bccSection => 'BCC rate & active currency';

  @override
  String get bccRate => 'Exchange rate (BCC)';

  @override
  String get activeCurrency => 'Main currency';

  @override
  String get appLanguage => 'App language';

  @override
  String get reportsExport => 'Data export';

  @override
  String get exportExcel => 'Export stock to Excel';

  @override
  String get dbMaintenance => 'Maintenance';

  @override
  String get mergeDuplicates => 'Merge duplicates';

  @override
  String get teamManagement => 'Team & permissions';

  @override
  String get teamManagementSubtitle =>
      'Add collaborators and manage their rights';

  @override
  String get navAccueil => 'Home';

  @override
  String get navCaisse => 'Checkout';

  @override
  String get navStock => 'Stock';

  @override
  String get navRapport => 'Report';

  @override
  String get navParametres => 'Settings';

  @override
  String accHello(String prenom) {
    return 'Hello $prenom 👋';
  }

  @override
  String get tauxTitle => 'Today\'s rate';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get accToday => 'TODAY';

  @override
  String get accOfSales => 'in sales';

  @override
  String get accCashed => 'Collected';

  @override
  String get accCredit => 'Credit';

  @override
  String get accExpenses => 'Expenses';

  @override
  String accCashInDrawer(String montant) {
    return 'Cash in the till today: $montant';
  }

  @override
  String accDiscounts(String montant) {
    return 'Discounts given: $montant';
  }

  @override
  String get accSendSummary => 'Send today\'s summary';

  @override
  String get accExpense => 'Expense';

  @override
  String get accSales => 'Sales';

  @override
  String get accClientAccounts => 'Customer accounts';

  @override
  String get accAccounting => 'Accounting';

  @override
  String get accHelp => 'Help';

  @override
  String accTodaySales(int count) {
    return 'Today\'s sales ($count)';
  }

  @override
  String get accNoSales => 'No sales yet today.\nTap “Checkout” to start.';

  @override
  String get accClient => 'Customer';

  @override
  String accRemaining(String montant) {
    return '$montant left';
  }

  @override
  String get accMainShop => 'Main shop';

  @override
  String get resMorning => 'Good morning';

  @override
  String get resAfternoon => 'Good afternoon';

  @override
  String get resEvening => 'Good evening';

  @override
  String get resNoSales => 'No sales yet today. Have a good working day! 💪';

  @override
  String get resTodayPrefix => 'Today, ';

  @override
  String resSalesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return '$_temp0';
  }

  @override
  String get resFor => ' for ';

  @override
  String get resGained => '. You earned ';

  @override
  String get resLoss => '. So far, a loss of ';

  @override
  String get todoTitle => '📋 To do today';

  @override
  String get todoNothing => '✅ Nothing urgent. Everything is in order!';

  @override
  String todoOwes(String nom, String montant) {
    return '$nom owes you $montant';
  }

  @override
  String todoOtherClients(int count) {
    return '…and $count more customer(s)';
  }

  @override
  String todoOut(String nom) {
    return '$nom: out of stock';
  }

  @override
  String todoLow(int count, String nom) {
    return 'Only $count $nom left';
  }

  @override
  String todoOtherProducts(int count) {
    return '…and $count more product(s) to reorder';
  }

  @override
  String get actSee => 'See';

  @override
  String get actAll => 'All';

  @override
  String get caisseNoCompany => 'Error: no company selected.';

  @override
  String caisseOutOfStock(String nom) {
    return '$nom is out of stock!';
  }

  @override
  String caisseStockLimit(int count) {
    return 'Stock limit reached ($count)';
  }

  @override
  String caisseAdded(String nom) {
    return '$nom added to the cart!';
  }

  @override
  String caisseNoBarcode(String code) {
    return 'No product found for code: $code';
  }

  @override
  String get caisseSearch => 'Search for a product…';

  @override
  String get caisseScan => 'Scan a barcode';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get caisseNoProducts =>
      'No products yet.\nAdd your products in the “Stock” tab.';

  @override
  String get caisseHint => 'Tap a product to add it • long press: quantity';

  @override
  String get caisseNoMatch => 'No product matches your search.';

  @override
  String caisseCheckout(String montant) {
    return 'Checkout $montant';
  }

  @override
  String get caisseNoName => 'No name';

  @override
  String get caisseOut => 'Out';

  @override
  String get caissePriceNeedsPermission =>
      'Changing the price requires the “Discounts and withdrawals” permission.';

  @override
  String get cartTitle => 'Shopping cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String cartCount(int count) {
    return 'Cart ($count items)';
  }

  @override
  String get cartClear => 'Empty the cart';

  @override
  String cartNormalPrice(String montant) {
    return 'Normal price: $montant';
  }

  @override
  String get cartLoss => 'Sold at a loss';

  @override
  String addTitle(String nom) {
    return 'Add $nom';
  }

  @override
  String lossConfirm(String nom) {
    return 'The price of $nom is below the purchase price.\nDo you really want to sell at this price?';
  }

  @override
  String get noCorrect => 'No, fix it';

  @override
  String get yesSell => 'Yes, sell';

  @override
  String stockAvailable(int count) {
    return 'Available stock: $count';
  }

  @override
  String unitPrice(String code) {
    return 'Unit price ($code)';
  }

  @override
  String discountPerPiece(String montant) {
    return 'Discount: $montant per piece';
  }

  @override
  String get fixedPrice =>
      'Fixed price (“Discounts and withdrawals” permission needed)';

  @override
  String lossWithCost(String montant) {
    return 'Selling at a loss! Purchase price: $montant';
  }

  @override
  String get lossBelowCost =>
      'Selling at a loss: this price is below the purchase price.';

  @override
  String get qtyInvalid => 'Invalid quantity';

  @override
  String maxAvailable(int count) {
    return 'Max available: $count';
  }

  @override
  String get quantity => 'Quantity';

  @override
  String get subtotal => 'Subtotal:';

  @override
  String qtyOverStock(int count) {
    return 'Quantity above available stock ($count)';
  }

  @override
  String get outOfStockGeneric => 'Product out of stock!';

  @override
  String get sellAtLoss => 'Sell at a loss';

  @override
  String get add => 'Add';

  @override
  String priceFor(String nom) {
    return 'Price for $nom';
  }

  @override
  String get agreedPrice => 'Agreed price (per piece)';

  @override
  String get normalPriceBtn => 'Normal price';

  @override
  String get validate => 'Confirm';

  @override
  String get payTitle => 'Finish the sale & payment';

  @override
  String get payClientName => 'Customer name';

  @override
  String get payPhone => 'Phone (e.g. +243...)';

  @override
  String payClientAccount(String montant) {
    return 'Customer account: $montant';
  }

  @override
  String get payUse => 'Use';

  @override
  String payPaidByAccount(String montant, String solde) {
    return 'Paid from account: $montant • New balance: $solde';
  }

  @override
  String get payMethod => 'Method';

  @override
  String get payStatus => 'Status';

  @override
  String get payCash => 'Cash';

  @override
  String get payCard => 'Bank card';

  @override
  String get payTransfer => 'Bank transfer';

  @override
  String get payPaid => 'Paid';

  @override
  String get payDebt => 'Debt';

  @override
  String get payPartial => 'Partial payment';

  @override
  String get payInvoiceTotal => 'Invoice total:';

  @override
  String get payPaidByClientAccount => 'Paid from customer account:';

  @override
  String get payToCollect => 'To collect now:';

  @override
  String payAllIn(String code) {
    return 'All in $code';
  }

  @override
  String payRestIn(String code) {
    return 'Rest in $code';
  }

  @override
  String payReceived(String code) {
    return 'Amount received ($code)';
  }

  @override
  String get payRemaining => 'Balance due:';

  @override
  String payChange(String code) {
    return 'Change to give ($code):';
  }

  @override
  String get payDelivery => 'Delivery';

  @override
  String get payDeliveredNow => 'Delivered now';

  @override
  String get payDeliverLater => 'Deliver later';

  @override
  String get payPickupBefore => 'Pick up before';

  @override
  String payDeadline(String date) {
    return 'Deadline: $date — the customer will appear in “To deliver”.';
  }

  @override
  String payDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get payReceiptActions => 'Receipt options:';

  @override
  String get payPrintReceipt => 'Print the receipt';

  @override
  String get paySendWhatsApp => 'Send by WhatsApp';

  @override
  String get paySendSms => 'Send by SMS';

  @override
  String get payValidate => 'Confirm & collect';

  @override
  String payBalanceChanged(String montant) {
    return 'The customer\'s balance changed (available: $montant \$). Turn “Use” off and on again to recalculate.';
  }

  @override
  String get payNotSaved => 'Sale NOT saved';

  @override
  String payDenied(String code) {
    return 'The server refused this sale (insufficient rights).\n\nNothing was saved: not the sale, the stock or the till.\nDo not hand over the goods yet: tell the manager.\n\nCode: $code';
  }

  @override
  String payNotSavedOther(String detail) {
    return 'Nothing was saved.\n\n$detail';
  }

  @override
  String get payUnderstood => 'OK';

  @override
  String get paySaved => 'Sale saved successfully!';

  @override
  String paySavedPickup(String date) {
    return 'Sale saved — to be picked up before $date.';
  }

  @override
  String payNewBalance(String montant) {
    return ' Customer\'s new balance: $montant.';
  }

  @override
  String payError(String message) {
    return 'Error while confirming: $message';
  }

  @override
  String get debtNewClient => 'New customer credit';

  @override
  String get debtNewSupplier => 'New supplier debt';

  @override
  String get debtClientName => 'Customer name *';

  @override
  String get debtSupplierName => 'Supplier name *';

  @override
  String get debtInvoiceRef => 'Invoice no. / Reference';

  @override
  String get debtTotal => 'Total amount *';

  @override
  String get debtAlreadyPaid => 'Amount already paid (partial payment)';

  @override
  String get debtPickDueDate => 'Choose a due date';

  @override
  String debtDueDate(String date) {
    return 'Due: $date';
  }

  @override
  String get debtNote => 'Note / Description (optional)';

  @override
  String get debtPaidOverTotal =>
      'The amount already paid is more than the total.';

  @override
  String debtPaymentTitle(String nom) {
    return 'Payment: $nom';
  }

  @override
  String debtInvoiceNo(String numero) {
    return 'Invoice no.: $numero';
  }

  @override
  String debtRemainingNow(String montant) {
    return 'Amount still owed: $montant';
  }

  @override
  String get debtPaymentAmount => 'Payment amount';

  @override
  String debtHelperSurplus(String montant) {
    return 'Owed: $montant. Any extra can go to the customer account.';
  }

  @override
  String debtMax(String montant) {
    return 'Maximum: $montant';
  }

  @override
  String get debtPaymentMode => 'Payment method';

  @override
  String get debtCashDesk => 'Cash (till)';

  @override
  String get debtCheck => 'Cheque';

  @override
  String get debtEnterAmount => 'Enter an amount.';

  @override
  String debtTooHighNoPhone(String montant) {
    return 'Too high. Maximum: $montant (customer has no number: no customer account)';
  }

  @override
  String debtTooHigh(String montant) {
    return 'Too high. Maximum: $montant';
  }

  @override
  String get debtGivesMore => 'The customer gives more';

  @override
  String debtSurplusQuestion(
      String dette, String donne, String surplus, String nom) {
    return 'Debt: $dette\nGiven: $donne\n\nPut $surplus on $nom\'s customer account?\nThey can use it for their next purchases.';
  }

  @override
  String get debtYesAccount => 'Yes, to their account';

  @override
  String debtSettled(String montant, String nom) {
    return 'Debt settled. $montant added to $nom\'s account.';
  }

  @override
  String get debtPendingNet => ' (will be sent when internet is back)';

  @override
  String debtPaymentSaved(String montant) {
    return 'Payment of $montant saved.';
  }

  @override
  String get debtValidatePayment => 'Confirm payment';
}
