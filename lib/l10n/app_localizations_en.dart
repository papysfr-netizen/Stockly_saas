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

  @override
  String get debtScreenTitle => 'Credits & Debts';

  @override
  String get debtExport => 'Export';

  @override
  String get debtExportExcel => 'Export to Excel';

  @override
  String get debtPrintPdf => 'Print / PDF';

  @override
  String get debtTabClients => 'Customers';

  @override
  String get debtTabSuppliers => 'Suppliers';

  @override
  String debtLoadError(String message) {
    return 'Loading error: $message';
  }

  @override
  String get debtAdd => 'Add a debt';

  @override
  String get ageToday => 'Today';

  @override
  String get ageYesterday => 'Yesterday';

  @override
  String ageDays(int count) {
    return '$count days ago';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String get whatsAppError => 'Cannot open WhatsApp on this device.';

  @override
  String get debtEmptyClients => 'No customer credit';

  @override
  String get debtEmptySuppliers => 'No supplier debt';

  @override
  String get debtEmptyClientsHint =>
      'Credit or partly paid sales will appear here automatically.';

  @override
  String get debtEmptySuppliersHint =>
      'Add here what you owe your suppliers with the “Add a debt” button.';

  @override
  String get noResults => 'No results';

  @override
  String get noResultsHint => 'Try another filter or search.';

  @override
  String get debtToCollect => 'TO COLLECT (CUSTOMERS)';

  @override
  String get debtToPay => 'TO PAY (SUPPLIERS)';

  @override
  String debtOpenFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'open files',
      one: 'open file',
    );
    return '$_temp0';
  }

  @override
  String debtClientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'customers',
      one: 'customer',
    );
    return '$_temp0';
  }

  @override
  String debtSuppliersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'suppliers',
      one: 'supplier',
    );
    return '$_temp0';
  }

  @override
  String debtLateCount(int count) {
    return 'overdue ($count)';
  }

  @override
  String get debtSearchClients => 'Search a customer, invoice, phone…';

  @override
  String get debtSearchSuppliers => 'Search a supplier, invoice…';

  @override
  String get filterOngoing => 'Open';

  @override
  String get filterRecent => 'Recent (< 30 d)';

  @override
  String get filterLate => 'Overdue';

  @override
  String get filterPartial => 'Partial';

  @override
  String get filterSettled => 'Settled';

  @override
  String get statusSettled => 'Settled';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String invoiceShort(String numero) {
    return 'Inv. $numero';
  }

  @override
  String paidOf(String paye, String total) {
    return 'Paid $paye of $total';
  }

  @override
  String lastPayment(String date) {
    return 'Last payment $date';
  }

  @override
  String get remind => 'Remind';

  @override
  String get message => 'Message';

  @override
  String get collect => 'Collect';

  @override
  String get pay => 'Pay';

  @override
  String printFailed(String message) {
    return 'Printing failed: $message';
  }

  @override
  String get printerTitle => 'Printer';

  @override
  String get printerPhoneOnly => 'Settings for this phone only';

  @override
  String get printerPaperWidth => 'Paper width';

  @override
  String get printer58 => '58 mm (small)';

  @override
  String get printer80 => '80 mm (large)';

  @override
  String get printerAfterSale => 'After a sale, the receipt…';

  @override
  String get printerPrints => 'Is printed';

  @override
  String get printerPrintsHint =>
      'Android print window (printer set up on the phone)';

  @override
  String get printerPdf => 'Is sent as PDF';

  @override
  String get printerPdfHint =>
      'WhatsApp, Bluetooth, e-mail… (when there is no printer)';

  @override
  String get printerTest => 'Print a test receipt';

  @override
  String get crashTest => 'Test error reports';

  @override
  String get crashDebugOnly =>
      'Reports are only sent from the APK (not over the cable).';

  @override
  String get crashSent =>
      'Test report sent. It appears in Firebase within a few minutes.';

  @override
  String get guideTitle => 'User guide';

  @override
  String get guideSubtitle => 'How to sell, collect a debt, print…';

  @override
  String get guideSearch => 'Search: debt, rate, print…';

  @override
  String guideNotFound(String mot) {
    return 'Nothing found for “$mot”.';
  }

  @override
  String get guideOwnerOnly => 'Owner / manager';

  @override
  String stockDeleted(String nom) {
    return '“$nom” deleted.';
  }

  @override
  String stockDeletedOffline(String nom) {
    return '“$nom” deleted on the phone. It will sync when internet is back.';
  }

  @override
  String stockDeleteError(String message) {
    return 'Error while deleting: $message';
  }

  @override
  String get stockAnalyzing => 'Analysing...';

  @override
  String stockImported(int count) {
    return '$count product(s) imported or updated!';
  }

  @override
  String stockImportError(String message) {
    return 'Import error: $message';
  }

  @override
  String stockConnected(String nom) {
    return 'Signed in: $nom';
  }

  @override
  String get stockImportTooltip => 'Import Excel / CSV / Packing List';

  @override
  String get myAccount => 'My account';

  @override
  String get changePassword => 'Change my password';

  @override
  String get logout => 'Log out';

  @override
  String get stockNoProduct => 'No product found.';

  @override
  String get stockProducts => 'Products';

  @override
  String get stockValue => 'Stock value';

  @override
  String get stockCannotDelete => 'Cannot delete';

  @override
  String stockCannotDeleteMsg(String nom, int count) {
    return '“$nom” still has $count item(s) in stock.\n\nFirst set the stock to 0 (stock count or loss), so the loss stays visible in the accounts.';
  }

  @override
  String get stockDeleteTitle => 'Delete the product';

  @override
  String stockDeleteConfirm(String nom) {
    return 'Do you really want to delete “$nom”?\n\nThis cannot be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get stockNewProduct => 'New product';

  @override
  String stockQty(int count) {
    return 'Stock: $count';
  }

  @override
  String get stockAlert => 'Low stock';

  @override
  String get edit => 'Edit';

  @override
  String get prodDefaultName => 'Unnamed product';

  @override
  String get prodBarcodeUsed => 'Barcode already used';

  @override
  String prodBarcodeUsedMsg(String nom, String stock, String prix) {
    return 'This code already belongs to:\n\n“$nom”\nStock: $stock  •  Price: $prix \$\n\nDo you want to open this product to edit it (for example to add stock)?';
  }

  @override
  String get prodOpenThis => 'Open this product';

  @override
  String get prodNoCompany => 'Company not found. Log out and log in again.';

  @override
  String get prodSavedOffline =>
      'Saved on the phone. It will be sent when internet is back.';

  @override
  String get prodUpdated => 'Product updated!';

  @override
  String get prodAdded => 'Product added!';

  @override
  String prodSaveError(String message) {
    return 'Error while saving: $message';
  }

  @override
  String get prodEditTitle => 'Edit product';

  @override
  String get prodImportPacking => 'Import Packing List (Excel / CSV)';

  @override
  String get prodOrManual => 'OR ENTER MANUALLY';

  @override
  String get prodImageUrl => 'Image URL';

  @override
  String get prodImageUrlOpt => 'Image URL (optional)';

  @override
  String get prodName => 'Product name *';

  @override
  String get prodNameHint => 'e.g. Cotton T-shirt';

  @override
  String get prodNameRequired => 'Name required';

  @override
  String get prodBarcode => 'Barcode';

  @override
  String get prodBarcodeHint => 'Scan / Type';

  @override
  String get prodCategory => 'Category';

  @override
  String get prodBuyPrice => 'Purchase price (\$)';

  @override
  String get prodInvalidPrice => 'Invalid price';

  @override
  String get prodSellPrice => 'Selling price (\$)*';

  @override
  String get prodPriceRequired => 'Price required';

  @override
  String get prodStock => 'Stock *';

  @override
  String get prodInitialStock => 'Opening stock *';

  @override
  String get prodStockRequired => 'Stock required';

  @override
  String get prodWholeNumber => 'Whole number';

  @override
  String get prodAlertLevel => 'Alert level';

  @override
  String get prodSaving => 'Saving...';

  @override
  String get prodUpdate => 'Update';

  @override
  String get prodSave => 'Save the product';

  @override
  String get msgLanguage => 'Message language';
}
