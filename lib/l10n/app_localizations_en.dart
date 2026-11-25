// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nguli';

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
  String get debtNote => 'Reason (optional)';

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

  @override
  String get sumDays =>
      'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';

  @override
  String get sumAllShops => 'All shops';

  @override
  String sumSales(int count, String montant) {
    return 'Sales: $count for $montant';
  }

  @override
  String sumCollected(String montant) {
    return 'Collected: $montant';
  }

  @override
  String sumCredit(String montant) {
    return 'Credit: $montant';
  }

  @override
  String sumExpenses(String montant) {
    return 'Expenses: $montant';
  }

  @override
  String sumCash(String montant) {
    return '💵 Cash in the till: $montant';
  }

  @override
  String sumProfit(String montant) {
    return '📈 Profit: $montant';
  }

  @override
  String sumRate(String taux) {
    return 'Rate: 1 \$ = $taux FC';
  }

  @override
  String sumSentBy(String nom) {
    return 'Sent by $nom — Nguli';
  }

  @override
  String get logoutQuestion => 'Log out?';

  @override
  String get logoutWarning =>
      'You will have to log in again with your e-mail and password.';

  @override
  String get exportDone => 'Excel export completed!';

  @override
  String exportError(String message) {
    return 'Export error: $message';
  }

  @override
  String get attention => 'Warning';

  @override
  String get mergeConfirm =>
      'Do you really want to merge duplicate products? This cannot be undone.';

  @override
  String get mergeDone => 'Duplicates cleaned up!';

  @override
  String get confirmBtn => 'Confirm';

  @override
  String get backfillTitle => 'Catch up the cost of old sales';

  @override
  String get backfillExplain =>
      'Old sales without a “Stock out” entry will receive one, at their original date.\n\nThe cost is calculated with the CURRENT purchase price of each product.\n\nYou can run this again safely: a sale is never counted twice.';

  @override
  String get launch => 'Start';

  @override
  String get backfillRunning => 'Catching up…';

  @override
  String get backfillNothing => 'Nothing to catch up';

  @override
  String get backfillDone => 'Catch-up finished';

  @override
  String backfillAllDone(String count) {
    return 'All sales ($count) already have their “Stock out” entry.';
  }

  @override
  String backfillResult(String nb, String total, String cout) {
    return '$nb sale(s) caught up out of $total.\n\nCost of goods added: $cout \$';
  }

  @override
  String backfillNoPrice(String count) {
    return '⚠️ $count item(s) without a purchase price: their cost counts as 0. Add their purchase price, then run again.';
  }

  @override
  String get backfillOffline =>
      'Saved on the phone: it will be sent when internet is back.';

  @override
  String get error => 'Error';

  @override
  String backfillFailed(String message) {
    return 'The catch-up could not be done: $message';
  }

  @override
  String get maintTitle => 'Maintenance & database';

  @override
  String get shopTitle => 'My shops';

  @override
  String get shopCardSubtitle => 'Create and manage your points of sale';

  @override
  String get shopNew => 'New shop';

  @override
  String get shopEditTitle => 'Edit shop';

  @override
  String get shopNameLabel => 'Shop name *';

  @override
  String get shopNameHint => 'E.g.: Birere Shop';

  @override
  String get shopNameError => 'Enter a name (at least 2 letters)';

  @override
  String get shopAddress => 'Address (optional)';

  @override
  String get shopPhone => 'Phone (optional)';

  @override
  String shopCreated(String nom) {
    return 'Shop “$nom” created';
  }

  @override
  String get shopUpdated => 'Shop updated';

  @override
  String shopReactivated(String nom) {
    return '“$nom” reactivated';
  }

  @override
  String shopDeactivated(String nom) {
    return '“$nom” deactivated';
  }

  @override
  String get shopTransfersTooltip => 'Stock transfers';

  @override
  String shopLoadError(String message) {
    return 'Unable to load shops: $message';
  }

  @override
  String get shopInfo =>
      'Main shop stock = total stock − stock of the other shops. Use “Transfer stock” to supply a shop, and “Prices per shop” to adapt prices to each market.';

  @override
  String get shopTransferTitle => 'Transfer stock';

  @override
  String get shopTransferSubtitle => 'Send goods from one shop to another';

  @override
  String get shopPricesTitle => 'Prices per shop';

  @override
  String get shopPricesSubtitle =>
      'Adapt selling prices to each shop\'s market';

  @override
  String get shopMainBadge => 'Main';

  @override
  String get shopDisabledBadge => 'Disabled';

  @override
  String get shopNoAddress => 'No address';

  @override
  String get shopDeactivate => 'Deactivate';

  @override
  String get shopReactivate => 'Reactivate';

  @override
  String get teamTitle => 'Team management';

  @override
  String get teamOwnerOnly => 'Access reserved for the shop owner.';

  @override
  String get teamNoMembers =>
      'No employees yet.\nTap “New member” to create an account for a cashier or a manager.';

  @override
  String get teamNewMember => 'New member';

  @override
  String get teamAccountCreated => 'Account created';

  @override
  String teamGiveInfo(String nom) {
    return 'Give this information to $nom:';
  }

  @override
  String get teamLogin => 'Username';

  @override
  String get teamPassword => 'Password';

  @override
  String get teamNoteNow =>
      'Write them down now: the password will not be shown again.';

  @override
  String get teamCopy => 'Copy';

  @override
  String get teamCopied => 'Copied!';

  @override
  String get teamFullName => 'Full name';

  @override
  String get teamNameRequired => 'Name required';

  @override
  String get teamLoginLabel => 'Username (e.g. grace)';

  @override
  String teamLoginPreview(String login) {
    return 'Sign-in: $login';
  }

  @override
  String get teamLoginMin => 'At least 3 letters or digits';

  @override
  String get teamPasswordMin => 'At least 6 characters';

  @override
  String get teamRole => 'Role';

  @override
  String get teamRoleLabel => 'Role:';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get teamManagerInfo =>
      'A manager has all permissions by default. You can remove some later.';

  @override
  String get teamCashierInfo =>
      'A cashier has no special permissions by default. You can grant some later.';

  @override
  String get teamCreateAccount => 'Create account';

  @override
  String teamYou(String nom) {
    return '$nom (you)';
  }

  @override
  String get teamOwnerAll => 'The owner has all rights.';

  @override
  String get teamRoleChanged => 'Role changed';

  @override
  String get teamActive => 'Access active (turn off to suspend)';

  @override
  String get teamCanLogin => 'Can sign in';

  @override
  String get teamDisabledInfo =>
      'Suspended: cannot work, can be reactivated anytime';

  @override
  String get teamReactivated => 'Access reactivated';

  @override
  String get teamDeactivated => 'Employee suspended';

  @override
  String teamPermissions(int count, int total) {
    return 'Permissions ($count/$total)';
  }

  @override
  String get teamManagerDefault => 'Default for a manager: everything allowed';

  @override
  String get teamCashierDefault => 'Default for a cashier: nothing special';

  @override
  String teamPermGranted(String perm, String nom) {
    return '“$perm” allowed for $nom';
  }

  @override
  String teamPermRemoved(String perm, String nom) {
    return '“$perm” removed from $nom';
  }

  @override
  String get permFinances => 'View finances';

  @override
  String get permFinancesDesc =>
      'P&L, accounting, purchase prices and margins.';

  @override
  String get permReturns => 'Returns and cancellations';

  @override
  String get permReturnsDesc =>
      'Record a return or cancel a sale not yet picked up.';

  @override
  String get permStock => 'Manage stock';

  @override
  String get permStockDesc => 'Add, edit, delete products, import a file.';

  @override
  String get permDiscounts => 'Discounts and withdrawals';

  @override
  String get permDiscountsDesc =>
      'Change prices at checkout and withdraw money from a customer account.';

  @override
  String get permMaintenance => 'Data maintenance';

  @override
  String get permMaintenanceDesc =>
      'Settings: fill in missing costs, merge duplicates.';

  @override
  String get histTitle => 'Sales history';

  @override
  String get histSearch => 'Customer, phone or invoice no.…';

  @override
  String get histToday => 'Today';

  @override
  String get hist7Days => '7 days';

  @override
  String get hist30Days => '30 days';

  @override
  String get histAllTime => 'All';

  @override
  String histLoadError(String message) {
    return 'Loading error: $message';
  }

  @override
  String histSalesOf(String nom) {
    return 'Sales by $nom';
  }

  @override
  String get histTotal => 'Total';

  @override
  String get histRemaining => 'Remaining';

  @override
  String get histNoResult => 'No sales for this search.';

  @override
  String get histPaid => 'Paid';

  @override
  String get histPartial => 'Partial';

  @override
  String get histDebt => 'Debt';

  @override
  String get histCancelledSale => 'Cancelled';

  @override
  String get histToDeliver => 'To deliver';

  @override
  String get histDelivered => 'Delivered';

  @override
  String get histPartialCancel => 'Partly cancelled';

  @override
  String get histFullReturn => 'Fully returned';

  @override
  String get histPartialReturn => 'Partly returned';

  @override
  String histInvoice(String numero) {
    return 'Invoice $numero';
  }

  @override
  String get histPrint => 'Print';

  @override
  String get histShare => 'Share (WhatsApp, e-mail…)';

  @override
  String histInvoiceError(String message) {
    return 'Unable to create the invoice: $message';
  }

  @override
  String histDeliveredOn(String date) {
    return 'Delivered on $date';
  }

  @override
  String get histItems => 'Items';

  @override
  String histReturnedQty(int count) {
    return '↩ $count returned';
  }

  @override
  String histCancelledQty(int count) {
    return '✕ $count cancelled';
  }

  @override
  String get histReturned => 'Returned';

  @override
  String get histCancelled => 'Cancelled';

  @override
  String get histNetTotal => 'Net total';

  @override
  String get histToPay => 'Left to pay';

  @override
  String get histMethod => 'Method';

  @override
  String get histSoldBy => 'Sold by';

  @override
  String get histDeliveredBy => 'Delivered by';

  @override
  String get histPdfButton => 'PDF invoice (print / WhatsApp)';

  @override
  String get histDeliveryNote => 'Delivery note';

  @override
  String get histReturnGoods => 'Return goods';

  @override
  String get histCancelSale => 'Cancel the sale (not picked up)';

  @override
  String histArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String histBy(String nom) {
    return 'by $nom';
  }

  @override
  String get histWalkIn => 'Walk-in customer';

  @override
  String get ddMotif => 'Reason';

  @override
  String get ddNoItems => 'No items: debt added manually.';

  @override
  String get ddItemsError => 'Unable to load the items.';

  @override
  String get ddCall => 'Call';

  @override
  String get ddPdf => 'PDF invoice';

  @override
  String get ddDetails => 'Details';

  @override
  String ddDiscount(String montant) {
    return 'Discount given: $montant';
  }

  @override
  String ddDate(String date) {
    return 'Date: $date';
  }

  @override
  String get ddPayments => 'Payment history';

  @override
  String get ddPaidBefore => 'Paid earlier (at the sale or before)';

  @override
  String get ddNoPayments => 'No payments yet.';

  @override
  String get payMotif => 'Reason for credit (optional)';

  @override
  String get payMotifHint => 'E.g. will pay Friday after the market';

  @override
  String accDebtsCollected(String montant) {
    return 'Debts collected: $montant';
  }

  @override
  String accDebtsCollectedTitle(int count) {
    return 'Debts collected today ($count)';
  }

  @override
  String get repChoiceTitle => 'Which summary to send?';

  @override
  String get repShort => 'Short summary';

  @override
  String get repShortHint => 'Today\'s totals';

  @override
  String get repDetailed => 'Detailed report';

  @override
  String get repDetailedHint =>
      'Each sale, products, sellers, expenses, debts, stock';

  @override
  String repSales(int count, String montant) {
    return '🛒 SALES ($count): $montant';
  }

  @override
  String get repProducts => '📦 PRODUCTS SOLD';

  @override
  String get repBySeller => '👤 BY SELLER';

  @override
  String get repByMethod => '💳 BY PAYMENT METHOD';

  @override
  String repExpenses(String montant) {
    return '💸 EXPENSES ($montant)';
  }

  @override
  String repDebtsCollected(String montant) {
    return '💰 DEBTS COLLECTED ($montant)';
  }

  @override
  String repNewCredits(String montant) {
    return '📝 NEW CREDITS ($montant)';
  }

  @override
  String get repToReorder => '⚠️ TO REORDER';

  @override
  String repCredit(String montant) {
    return 'credit $montant';
  }

  @override
  String repMore(int count) {
    return '…and $count more';
  }

  @override
  String get retCancelTitle => 'Cancel the sale';

  @override
  String get retNoCancelRight =>
      'Only the manager and the owner can cancel a sale.';

  @override
  String get retNoReturnRight =>
      'Only the manager and the owner can record a return.';

  @override
  String retTooLate(String date, int jours, int limite) {
    return 'Return period exceeded: sale of $date ($jours days ago, limit $limite days).\n\nOnly the owner can accept this return.';
  }

  @override
  String get retNothingToCancel =>
      'Nothing to cancel on this sale.\n\nAll the goods have already been handed to the customer or cancelled. If they bring them back, use “Return goods”.';

  @override
  String get retNothingToReturn =>
      'Nothing to return on this sale.\n\nEither everything has already been returned, or the goods have not yet been handed to the customer (in that case, use “Cancel the sale”).';

  @override
  String get retModeAvoirHint =>
      'The amount is added to the customer account: they can use it at checkout.';

  @override
  String get retModeKeepHint =>
      'The shop keeps the money (deposit not refunded).';

  @override
  String get retModeCashHint => 'The money comes out of the till.';

  @override
  String retSaleOf(String date, String age) {
    return 'Sale of $date • $age';
  }

  @override
  String retInvoiceAmount(String montant) {
    return 'Invoice: $montant';
  }

  @override
  String retStillOwes(String montant) {
    return 'The customer still owes: $montant';
  }

  @override
  String get retCancelInfo =>
      'Goods never picked up by the customer: they go back into stock and the sale is cancelled for these items.';

  @override
  String retLateAccepted(int jours) {
    return 'Late ($jours days): return accepted exceptionally by the owner.';
  }

  @override
  String get retItemsToCancel => 'Items to cancel';

  @override
  String get retItemsReturned => 'Returned items';

  @override
  String retPrice(String montant) {
    return 'Price: $montant';
  }

  @override
  String retNotPicked(int count) {
    return 'not picked up: $count';
  }

  @override
  String retReturnable(int count) {
    return 'returnable: $count';
  }

  @override
  String retAlreadyReturned(int count) {
    return 'already returned: $count';
  }

  @override
  String get retResell => 'Put back on sale';

  @override
  String get retDamaged => 'Damaged (loss)';

  @override
  String get retCancelAll => 'Cancel all';

  @override
  String get retCancelReason => 'Reason for cancellation *';

  @override
  String get retReturnReason => 'Reason for return *';

  @override
  String get retCancelHint => 'E.g. customer never came, deadline passed…';

  @override
  String get retReturnHint => 'E.g. wrong size, manufacturing defect…';

  @override
  String retCancelledAmount(String montant) {
    return 'Amount cancelled: $montant';
  }

  @override
  String retReturnAmount(String montant) {
    return 'Return amount: $montant';
  }

  @override
  String retDeducted(String montant) {
    return 'Deducted from the customer\'s debt: $montant';
  }

  @override
  String retAlreadyPaid(String montant) {
    return 'Already paid by the customer: $montant';
  }

  @override
  String retToGiveBack(String montant) {
    return 'To give back to the customer: $montant';
  }

  @override
  String get retCash => 'Cash';

  @override
  String get retCredit => 'Store credit';

  @override
  String get retKeep => 'Keep';

  @override
  String get retPhoneLabel => 'Customer account phone *';

  @override
  String get retPhoneError => 'Store credit needs the customer\'s phone';

  @override
  String get retChooseItems => 'Choose the items';

  @override
  String retValidateCancel(String montant) {
    return 'Confirm cancellation ($montant)';
  }

  @override
  String retValidateReturn(String montant) {
    return 'Confirm return ($montant)';
  }

  @override
  String get retNeedReason => 'Enter the reason to confirm.';

  @override
  String get retConfirmCancel => 'Confirm the cancellation';

  @override
  String get retConfirmReturn => 'Confirm the return';

  @override
  String get retDamagedShort => 'damaged';

  @override
  String retAmount(String montant) {
    return 'Amount: $montant';
  }

  @override
  String retDamagedCount(int count) {
    return '$count damaged item(s): not returned to stock.';
  }

  @override
  String retCreditTo(String montant, String tel) {
    return 'Store credit of $montant added to account $tel.';
  }

  @override
  String get retIrreversible => 'This operation cannot be undone.';

  @override
  String get retBack => 'Back';

  @override
  String get retValidate => 'Confirm';

  @override
  String get retCancelSaved => 'Cancellation saved.';

  @override
  String get retReturnSaved => 'Return saved.';

  @override
  String retGiveCash(String montant) {
    return 'Give $montant back to the customer in cash.';
  }

  @override
  String retCreditAdded(String montant, String solde) {
    return 'Store credit of $montant added to the customer account (new balance: $solde).';
  }

  @override
  String retDepositKept(String montant) {
    return 'Deposit of $montant kept by the shop.';
  }

  @override
  String retDebtReduced(String montant) {
    return 'Customer\'s debt reduced by $montant.';
  }

  @override
  String get retOffline => '(will be sent when internet is back)';

  @override
  String get caisseNoShopProducts =>
      'No products in stock in this shop.\nAdd stock (purchase or transfer from the main shop).';

  @override
  String stockShowOut(int count) {
    return 'Show out of stock ($count)';
  }

  @override
  String get stockShowInStock => 'Back to products in stock';

  @override
  String get livTitle => 'To deliver';

  @override
  String livButtonLate(int count) {
    return 'To deliver ($count late)';
  }

  @override
  String get livNoneTitle => 'No pending deliveries';

  @override
  String get livNoneSub => 'All customers have received their goods.';

  @override
  String livWaitingLate(int count, int late) {
    return '$count customer(s) waiting — $late late';
  }

  @override
  String livWaiting(int count) {
    return '$count customer(s) waiting for their goods';
  }

  @override
  String get livNoWhatsapp => 'Cannot open WhatsApp.';

  @override
  String get livHandOverTitle => 'Hand over the goods';

  @override
  String livClient(String nom) {
    return 'Customer: $nom';
  }

  @override
  String get livWhatNow => 'Indicate what the customer takes now:';

  @override
  String get livAllGiven => 'Everything has already been handed over.';

  @override
  String livRemainDone(int reste, int deja) {
    return '$reste left (already handed: $deja)';
  }

  @override
  String livToHand(int count) {
    return 'To hand over: $count';
  }

  @override
  String get livChooseOne => 'Choose at least one item to hand over.';

  @override
  String livPartialAfter(int count) {
    return 'Partial pickup: $count item(s) will remain to collect.';
  }

  @override
  String get livComplete => 'Complete delivery: everything is handed over.';

  @override
  String livWarnUnpaid(String montant) {
    return 'Warning: $montant still to pay.';
  }

  @override
  String get livValidateExit => 'Confirm pickup';

  @override
  String get livAllDelivered => 'Yes, all delivered';

  @override
  String get livSavedOffline =>
      'Pickup saved on the phone. Will be sent when internet is back.';

  @override
  String livCompleteSaved(String client) {
    return 'Complete delivery saved for $client.';
  }

  @override
  String livPartialSaved(int count) {
    return 'Partial pickup saved: $count item(s) left to collect.';
  }

  @override
  String livLatePassed(String date) {
    return 'Deadline passed (limit: $date)';
  }

  @override
  String livLateDays(int jours, String date) {
    return 'Deadline passed by $jours day(s) (limit: $date)';
  }

  @override
  String livPickToday(String date) {
    return 'To collect today (limit: $date)';
  }

  @override
  String livPickTomorrow(String date) {
    return 'To collect before tomorrow evening ($date)';
  }

  @override
  String livPickBefore(String date, int jours) {
    return 'To collect before $date ($jours days left)';
  }

  @override
  String livCall(String tel) {
    return 'Call $tel';
  }

  @override
  String get livPartial => 'Partially delivered';

  @override
  String livSoldOn(String date) {
    return 'Sold on $date';
  }

  @override
  String livSoldOnBy(String date, String vendeur) {
    return 'Sold on $date by $vendeur';
  }

  @override
  String get livStillToHand => 'Still to hand over:';

  @override
  String get livToHandColon => 'To hand over:';

  @override
  String get livNothingToHand => 'nothing to hand over';

  @override
  String livOutOf(String count) {
    return '(of $count)';
  }

  @override
  String livHanded(int count) {
    return 'handed: $count';
  }

  @override
  String livCancelled(int count) {
    return '$count cancelled';
  }

  @override
  String get livAlreadyOut => 'Already collected:';

  @override
  String livUnpaid(String montant) {
    return 'Left to pay: $montant — collect before delivering';
  }

  @override
  String get livRemind => 'Remind';

  @override
  String get livMarkDelivered => 'Mark as delivered';

  @override
  String livBy(String nom) {
    return '(by $nom)';
  }

  @override
  String get ccDepositTitle => 'Customer deposit';

  @override
  String get ccWithdrawTitle => 'Customer withdrawal';

  @override
  String get ccPhoneLabel => 'Customer phone *';

  @override
  String get ccPhoneShort => 'Number too short';

  @override
  String get ccNameLabel => 'Customer name';

  @override
  String get ccAmountLabel => 'Amount (USD) *';

  @override
  String get ccMoreThanBalance => 'More than the available balance';

  @override
  String ccAvailable(String montant) {
    return 'Available balance: $montant';
  }

  @override
  String get ccCash => 'Cash';

  @override
  String get ccSaveDeposit => 'Save the deposit';

  @override
  String get ccSaveWithdraw => 'Save the withdrawal';

  @override
  String ccDepositSaved(String montant) {
    return 'Deposit of $montant saved.';
  }

  @override
  String ccWithdrawSaved(String montant) {
    return 'Withdrawal of $montant saved.';
  }

  @override
  String get ccNewDeposit => 'New deposit';

  @override
  String get ccSearchHint => 'Name or phone…';

  @override
  String ccCount(int count) {
    return '$count customer(s) with an account';
  }

  @override
  String ccTotalKept(String montant) {
    return 'Customers\' money held: $montant';
  }

  @override
  String get ccNone => 'No customer account.\nTap “New deposit” to create one.';

  @override
  String get ccAccountTitle => 'Customer account';

  @override
  String get ccAvailableLabel => 'Available balance';

  @override
  String get ccDeposit => 'Deposit';

  @override
  String get ccWithdraw => 'Withdrawal';

  @override
  String get ccSendStatement => 'Send the statement via WhatsApp';

  @override
  String get ccHistory => 'History';

  @override
  String get ccNoMovement => 'No transactions.';

  @override
  String ccDateBy(String date, String nom) {
    return '$date • by $nom';
  }

  @override
  String ccBalanceAfter(String montant) {
    return 'Balance: $montant';
  }

  @override
  String get depSearchHint => 'Search an expense...';

  @override
  String get depTitle => 'Charges & Expenses';

  @override
  String get depTabAll => 'All charges';

  @override
  String get depTabByCat => 'By category';

  @override
  String get depExport => 'Export';

  @override
  String get depColDate => 'Date';

  @override
  String get depColTitle => 'Title / Reason';

  @override
  String get depColCategory => 'Category';

  @override
  String get depColAmount => 'Amount';

  @override
  String get depColAuthor => 'Author';

  @override
  String get depColNote => 'Note';

  @override
  String get depReportTitle => 'Charges and Expenses Report';

  @override
  String get depToExcel => 'Export to Excel';

  @override
  String get depPrintPdf => 'Print / PDF';

  @override
  String get depTotalAll => 'Grand total of expenses';

  @override
  String depTotalFor(String categorie) {
    return 'Total for: $categorie';
  }

  @override
  String depNoResult(String recherche) {
    return 'No result for “$recherche”';
  }

  @override
  String get depNone => 'No expense recorded.';

  @override
  String depNote(String note) {
    return 'Note: $note';
  }

  @override
  String get depEdit => 'Edit';

  @override
  String get depDelete => 'Delete';

  @override
  String get depAdd => 'Add an expense';

  @override
  String get depDeleteTitle => 'Delete the expense';

  @override
  String get depDeleteConfirm =>
      'Are you sure you want to delete this expense line?';

  @override
  String get depInvalidAmount => 'Please enter a valid amount (> 0)';

  @override
  String get depEdited => 'Expense updated!';

  @override
  String get depSaved => 'Expense saved!';

  @override
  String depSaveError(String erreur) {
    return 'Error while saving: $erreur';
  }

  @override
  String get depFormEdit => 'Edit the expense';

  @override
  String get depFormNew => 'Record an expense';

  @override
  String get depReasonRequired => 'The reason is required';

  @override
  String get depReasonLabel => 'Reason / Title';

  @override
  String get depReasonHint => 'e.g. Rent, Electricity...';

  @override
  String get depAmountRequired => 'The amount is required';

  @override
  String get depAmountInvalid => 'Invalid amount';

  @override
  String get depCategoryLabel => 'Expense category';

  @override
  String depDate(String date) {
    return 'Date: $date';
  }

  @override
  String get depNoteLabel => 'Note / Comment (optional)';

  @override
  String get depSaveChanges => 'Save changes';

  @override
  String get depSaveExpense => 'Save the expense';

  @override
  String get depCatAll => 'All';

  @override
  String get depCatRent => 'Rent';

  @override
  String get depCatSalaries => 'Salaries';

  @override
  String get depCatUtilities => 'Electricity & Water';

  @override
  String get depCatTransport => 'Transport / Fuel';

  @override
  String get depCatTaxes => 'Taxes';

  @override
  String get depCatMaintenance => 'Maintenance / Repair';

  @override
  String get depCatMarketing => 'Marketing / Ads';

  @override
  String get depCatOther => 'Other';

  @override
  String get blTraceTitle => 'Traceability required';

  @override
  String blTraceMsg(String montant, String seuil) {
    return 'This delivery note amounts to $montant USD (above the $seuil USD threshold).\n\nFor financial security and tracking, a valid customer name and phone number are required.';
  }

  @override
  String get blTitle => 'Delivery note';

  @override
  String get blPrint => 'Print';

  @override
  String get blShare => 'Share (WhatsApp, e-mail…)';

  @override
  String blPdfError(String erreur) {
    return 'Cannot create the PDF: $erreur';
  }

  @override
  String get blPrintShare => 'Print / Share';

  @override
  String get blMyShop => 'My Shop';

  @override
  String blPhoneShort(String tel) {
    return 'Tel: $tel';
  }

  @override
  String get blDeliveredTo => 'DELIVERED TO:';

  @override
  String get blCounterClient => 'Walk-in customer';

  @override
  String blAddress(String adresse) {
    return 'Address: $adresse';
  }

  @override
  String get blNotSpecified => 'Not specified';

  @override
  String blPhone(String tel) {
    return 'Phone: $tel';
  }

  @override
  String get blColItem => 'Item';

  @override
  String get blColQty => 'Qty';

  @override
  String get blColUnit => 'Unit price';

  @override
  String get blColTotal => 'Total';

  @override
  String get blGrandTotal => 'GRAND TOTAL: ';

  @override
  String get blDeliverer => 'Deliverer / Sender';

  @override
  String get blCustomerSign => 'Customer (agreed)';

  @override
  String get panRateTitle => 'Today\'s rate (USD -> FC)';

  @override
  String get panRateFor1 => 'Rate for 1 USD';

  @override
  String get panUpdate => 'Update';

  @override
  String get panClear => 'Empty the cart';

  @override
  String get panEmpty => 'Your cart is empty';

  @override
  String get panTotal => 'Total to pay:';

  @override
  String get panCheckout => 'CHECKOUT';

  @override
  String get panRateLocked =>
      'Only the owner (or an authorised person) can change the rate.';

  @override
  String get payCreditNeedsPhone =>
      'For a credit sale, enter the customer\'s phone number (at least 9 digits).';

  @override
  String get debtClientPhone => 'Customer phone *';

  @override
  String get debtPhoneRequired =>
      'The customer\'s phone number is required for credit (at least 9 digits).';

  @override
  String get payCreditNeedsName =>
      'For a credit sale, enter the customer\'s name.';

  @override
  String get debtNameRequired => 'The customer\'s name is required for credit.';

  @override
  String get cloTitle => 'Cash register closing';

  @override
  String get cloButton => 'Close the register';

  @override
  String cloDoneAt(String heure) {
    return 'Register closed at $heure';
  }

  @override
  String get cloBoutique => 'Shop';

  @override
  String get cloPickBoutique => 'Choose the shop to close';

  @override
  String get cloBlindInfo =>
      'Count the money in the drawer and write what you find. Do not copy another amount: the owner then compares with the sales.';

  @override
  String get cloFloatMorning => 'Morning cash float';

  @override
  String get cloCounted => 'Money counted in the drawer';

  @override
  String get cloMobileReceived => 'Mobile Money received today';

  @override
  String get cloMobileHint => 'Total received on the shop phone, in dollars';

  @override
  String get cloFloatTomorrow => 'Float left for tomorrow (optional)';

  @override
  String get cloNote => 'Note (optional)';

  @override
  String get cloInDollars => 'In dollars (\$)';

  @override
  String get cloInFrancs => 'In francs (FC)';

  @override
  String get cloSave => 'Save the closing';

  @override
  String get cloConfirmTitle => 'Save the closing?';

  @override
  String get cloConfirmBody =>
      'Once saved, the closing can no longer be changed.';

  @override
  String get cloSaved => 'Closing saved. The owner will see the result.';

  @override
  String get cloAlreadyDone => 'This register is already closed today.';

  @override
  String get cloResult => 'Closing result';

  @override
  String get cloCash => 'Cash';

  @override
  String get cloMobile => 'Mobile Money';

  @override
  String get cloExpected => 'Expected';

  @override
  String get cloCountedShort => 'Counted';

  @override
  String get cloGap => 'Difference';

  @override
  String get cloOk => 'Correct ✓';

  @override
  String cloMissing(String montant) {
    return '$montant missing';
  }

  @override
  String cloSurplus(String montant) {
    return '$montant extra';
  }

  @override
  String get cloDetail => 'Expected amount details';

  @override
  String get cloLineFloat => 'Cash float';

  @override
  String get cloLineSales => 'Sales';

  @override
  String get cloLineDebts => 'Debts collected';

  @override
  String get cloLineDeposits => 'Customer account deposits';

  @override
  String get cloLineWithdrawals => 'Customer account withdrawals';

  @override
  String get cloLineExpenses => 'Expenses';

  @override
  String get cloLineSuppliers => 'Suppliers paid';

  @override
  String get cloLineRefunds => 'Return refunds';

  @override
  String get cloLineOther => 'Other payments (card, transfer…), not counted';

  @override
  String get cloExpensesHidden =>
      'Expenses could not be read: the expected amount may be too high.';

  @override
  String cloAfterSales(String nombre, String montant) {
    return '$nombre sale(s) after closing: $montant';
  }

  @override
  String cloBy(String nom, String heure) {
    return 'By $nom at $heure';
  }

  @override
  String get cloHistory => 'Closing history';

  @override
  String get cloHistoryEmpty => 'No closing yet.';

  @override
  String get cloReopen => 'Reopen (delete the closing)';

  @override
  String get cloReopenConfirm =>
      'Delete this closing? The register can be counted again.';

  @override
  String get cloAfterWarning =>
      'Register already closed today: this sale will be marked \"after closing\".';

  @override
  String cloRate(String taux) {
    return 'Rate: 1 \$ = $taux FC';
  }

  @override
  String get cloLoading => 'Computing the expected amount…';

  @override
  String cloDoneBy(String heure, String nom) {
    return 'Closed at $heure by $nom';
  }

  @override
  String get cloSavedShort => 'Closing saved.';

  @override
  String get caiTitle => 'Till';

  @override
  String get caiNewProduct => 'New product';

  @override
  String get caiSettings => 'Settings';

  @override
  String get caiExport => 'Export the catalogue';

  @override
  String get caiExportExcel => 'Export to Excel';

  @override
  String get caiExportPdf => 'Print / PDF';

  @override
  String get caiColName => 'Product';

  @override
  String get caiColStock => 'Stock';

  @override
  String get caiColPrice => 'Selling price';

  @override
  String get caiCatalogTitle => 'Product catalogue';

  @override
  String caiProfileError(String erreur) {
    return 'Could not load your profile: $erreur';
  }

  @override
  String get caiPickShop => 'Choose the selling shop';

  @override
  String caiSellingIn(String nom) {
    return 'Selling in: $nom';
  }

  @override
  String get caiMainShop => 'Main shop';

  @override
  String get payDeliveryNote => 'Delivery note';

  @override
  String get debtOrigin => 'Where does this debt come from?';

  @override
  String get debtOriginSale => 'Sale outside the till';

  @override
  String get debtOriginLoan => 'Money lent';

  @override
  String get debtOriginOld => 'Old debt (notebook)';

  @override
  String get debtOriginPurchase => 'Purchase on credit';

  @override
  String get debtOriginBorrow => 'Money borrowed';

  @override
  String get debtFromDrawer => 'The money came out of the till';

  @override
  String get debtToDrawer => 'The money went into the till';

  @override
  String get debtOldPaid => 'Already repaid before Nguli';

  @override
  String get cloLineBorrowed => 'Money borrowed (put in the till)';

  @override
  String get cloLineLent => 'Money lent (taken from the till)';

  @override
  String get prodPricePositive => 'The selling price must be above 0';

  @override
  String get prodNoNegative => 'No negative number';

  @override
  String payChangeToAccount(String montant) {
    return 'Put the change ($montant) on the customer\'s account';
  }

  @override
  String get delAccount => 'Delete my account';

  @override
  String get delTitle => 'Delete the account?';

  @override
  String get delOwnerWarning =>
      'You are the owner: the WHOLE business will be erased forever (products, sales, debts, accounts, customer accounts, expenses) and your employees will lose access. Make a backup first if you want to keep your figures.';

  @override
  String get delEmployeeWarning =>
      'Your access will be removed forever. The sales you made stay in the business records.';

  @override
  String get delConfirmWord => 'DELETE';

  @override
  String get delPassword => 'Your password';

  @override
  String get delSmsHint =>
      'SMS account: log out, log in again, then delete within 5 minutes.';

  @override
  String get delButton => 'Delete forever';

  @override
  String get delProgress =>
      'Deleting… Keep the app open and stay connected to the internet.';

  @override
  String get delErrPassword => 'Wrong password.';

  @override
  String get delErrRelogin =>
      'For security, log out, log in again, then try again within 5 minutes.';

  @override
  String get delErrNetwork =>
      'No internet connection. Deletion needs the internet: try again.';

  @override
  String get delErrUnknown =>
      'Deletion could not finish. Try again: what is already erased will not come back.';

  @override
  String get delDone => 'Your account has been deleted.';

  @override
  String delTypeConfirm(String mot) {
    return 'To confirm, type $mot';
  }

  @override
  String get delEmployeeAskOwner =>
      'Only your employer can delete your Nguli access. Ask them, or write to us at the address given in the privacy policy.';

  @override
  String get teamRemove => 'Remove from team';

  @override
  String teamRemoveQuestion(String nom) {
    return 'Remove $nom from the team?';
  }

  @override
  String get teamRemoveInfo =>
      'Their access is deleted forever: they can no longer enter the shop. The sales they made remain. For an absence, deactivate them instead.';

  @override
  String teamRemoved(String nom) {
    return '$nom was removed from the team';
  }

  @override
  String get accountRemovedTitle => 'Access removed';

  @override
  String get accountRemovedInfo =>
      'Your access to this shop has been removed. Contact the owner if this is a mistake.';

  @override
  String get payChangeHow => 'Give the change in:';

  @override
  String payChangeGive(String montant) {
    return 'Give: $montant';
  }

  @override
  String get scanTypeCode => 'Type the code by hand';

  @override
  String get scanTypeCodeHint => 'Type the number printed under the bars.';

  @override
  String get scanTitle => 'Scan the barcode';

  @override
  String get scanSwitchCamera => 'Switch camera';

  @override
  String get scanCameraNeeded => 'Camera access required';

  @override
  String get scanCameraAllow =>
      'Allow camera access in the phone settings to scan barcodes.';

  @override
  String get retry => 'Try again';

  @override
  String scanChecking(String fait, String total) {
    return 'Checking… $fait/$total';
  }

  @override
  String get scanStepBack =>
      'Step back a little: the whole barcode must fit in the frame';

  @override
  String get accountSuspendedTitle => 'Account suspended';

  @override
  String get accountSuspendedInfo =>
      'The owner has suspended your access.\nContact them to reactivate it.';

  @override
  String get backToLogin => 'Back to login';

  @override
  String authError(String erreur) {
    return 'Sign-in error: $erreur';
  }

  @override
  String profileLoadError(String erreur) {
    return 'Error loading the profile:\n$erreur';
  }

  @override
  String get pwdOldWrong => 'The old password is wrong.';

  @override
  String get pwdTooWeak => 'New password too weak (6 characters minimum).';

  @override
  String get pwdTooMany => 'Too many attempts. Wait a few minutes.';

  @override
  String get pwdNoInternet =>
      'No internet connection. Changing the password needs the internet.';

  @override
  String get pwdRelogin =>
      'For security, log out, log in again, and try again.';

  @override
  String get errorUnknown => 'Unknown error.';

  @override
  String get pwdFillAll => 'Fill in all three fields.';

  @override
  String get pwdMin6 => 'The new password must have at least 6 characters.';

  @override
  String get pwdMismatch => 'The two new passwords do not match.';

  @override
  String get pwdSameAsOld => 'The new password must differ from the old one.';

  @override
  String get pwdSmsAccount =>
      'This account does not sign in with a password (SMS sign-in).';

  @override
  String get pwdChanged => 'Password changed successfully.';

  @override
  String errorWith(String erreur) {
    return 'Error: $erreur';
  }

  @override
  String get pwdChangeTitle => 'Change my password';

  @override
  String get pwdOld => 'Old password';

  @override
  String get pwdNew => 'New password';

  @override
  String get pwdMinHint => '6 characters minimum';

  @override
  String get pwdConfirm => 'Confirm the new password';

  @override
  String get lotOldStock => 'Stock from before the arrivals';

  @override
  String get lotArrival => 'Arrival';

  @override
  String get lotSellFrom => 'Sell from the arrival';

  @override
  String lotChoice(String nom, String reste) {
    return '$nom ($reste left)';
  }

  @override
  String livMsgRest(String client, String liste, String boutique) {
    return 'Hello $client, the rest of your goods ($liste) is waiting for you at $boutique. ';
  }

  @override
  String livMsgAll(String client, String liste, String boutique) {
    return 'Hello $client, your goods ($liste) are waiting for you at $boutique. ';
  }

  @override
  String livMsgLate(String date) {
    return 'The pickup date ($date) has passed: please come and collect it as soon as possible. ';
  }

  @override
  String livMsgBefore(String date) {
    return 'Please collect it before $date. ';
  }

  @override
  String livMsgToPay(String montant) {
    return 'Left to pay: $montant. ';
  }

  @override
  String get livMsgThanks => 'Thank you!';

  @override
  String get lotProposed => 'suggested';

  @override
  String get cloByCurrency => 'By currency (float + cash sales)';

  @override
  String get cloDollars => 'Dollars';

  @override
  String get cloFrancs => 'Francs';

  @override
  String cloExpCounted(String attendu, String compte) {
    return 'expected $attendu · counted $compte';
  }

  @override
  String get cloByCurrencyNote =>
      'Debts, expenses and deposits are not split by currency: this comparison is right when the day has mostly sales.';

  @override
  String accMsgBalance(String nom, String boutique, String solde) {
    return 'Hello $nom, your balance at $boutique is $solde.';
  }

  @override
  String get accMsgLast => 'Latest movements:';

  @override
  String get accMsgThanks => 'Thank you for your trust!';

  @override
  String get accMvtDeposit => 'Deposit';

  @override
  String get logWrong => 'Wrong username (or e-mail) or password.';

  @override
  String get logDisabled => 'This account is suspended. Contact the owner.';

  @override
  String get logNoInternet => 'No internet connection. Check your network.';

  @override
  String get logError => 'Sign-in error.';

  @override
  String get logNoProfile => 'No profile found for this account.';

  @override
  String get logOk => 'Signed in!';

  @override
  String logWelcome(String nom) {
    return 'Welcome $nom!';
  }

  @override
  String logDbError(String erreur) {
    return 'Data access error: $erreur';
  }

  @override
  String get fillAll => 'Fill in all the fields.';

  @override
  String get logEnterPhone => 'Enter a phone number.';

  @override
  String logSmsError(String erreur) {
    return 'SMS error: $erreur';
  }

  @override
  String get logSmsSent => 'SMS code sent!';

  @override
  String get logEnterCode => 'Enter the code you received.';

  @override
  String get logBadCode => 'Invalid SMS code.';

  @override
  String get logWithPhone => 'Sign in with a phone number';

  @override
  String get logWithId => 'Sign in with username or e-mail';

  @override
  String get logIdLabel => 'E-mail or username';

  @override
  String get logIdHelp => 'Employee: type the username from the owner';

  @override
  String get logPassword => 'Password';

  @override
  String get logSignIn => 'Sign in';

  @override
  String get logPhoneLabel => 'Phone (e.g. +243970000000)';

  @override
  String get logSendSms => 'Send the SMS code';

  @override
  String get logCodeLabel => '6-digit code received by SMS';

  @override
  String get logValidateCode => 'Confirm the code';

  @override
  String get logNew => 'New to Nguli?';

  @override
  String get logCreateBusiness => 'Create a business';

  @override
  String get regDone => 'Business and account created!';

  @override
  String regError(String erreur) {
    return 'Sign-up error: $erreur';
  }

  @override
  String get regCreate => 'Create my business';

  @override
  String get regJoin => 'Join Nguli';

  @override
  String get regIntro => 'Set up your business and manage your stock easily.';

  @override
  String get regBusinessName => 'Business name *';

  @override
  String get regBusinessHint => 'e.g. La Grâce Store';

  @override
  String get regBusinessNeeded => 'Enter your business name';

  @override
  String get regManagerName => 'Your full name *';

  @override
  String get regNameNeeded => 'Enter your name';

  @override
  String get regPhone => 'Phone (optional)';

  @override
  String get regEmail => 'E-mail address *';

  @override
  String get regEmailNeeded => 'Enter an e-mail address';

  @override
  String get regEmailInvalid => 'Enter a valid e-mail address';

  @override
  String get regPassword => 'Password *';

  @override
  String get regConfirm => 'Confirm the password *';

  @override
  String get regCreating => 'Creating the account…';

  @override
  String get regHaveAccount => 'Already have an account?';

  @override
  String get cloOldSalesFc => 'Older sales: change assumed given in francs.';

  @override
  String get accMvtCredit => 'Credit (return)';

  @override
  String get accMvtPurchase => 'Purchase';

  @override
  String get accMvtWithdrawal => 'Withdrawal';

  @override
  String get impConfirm => 'Confirm the import';

  @override
  String impConfirmBody(String nouveaux, String maj, String ignores) {
    return '$nouveaux new product(s)\n$maj product(s) updated\n$ignores line(s) skipped\n\n';
  }

  @override
  String get impImport => 'Import';

  @override
  String get impSaving => 'Saving…';

  @override
  String impSavingProgress(String fait, String total) {
    return 'Saving: $fait / $total';
  }

  @override
  String get impDone => 'Import finished';

  @override
  String impDoneBody(String nouveaux, String maj, String ignores) {
    return '🟢 $nouveaux new product(s)\n🔵 $maj product(s) updated\n⚪ $ignores line(s) skipped';
  }

  @override
  String get impColMissing => 'not found';

  @override
  String impCheck(String doute) {
    return 'To check: $doute';
  }

  @override
  String impFileLine(String nom) {
    return '📄 File: $nom';
  }

  @override
  String impCodeQty(String code, String qte) {
    return 'Code: $code • Qty: $qte';
  }

  @override
  String impAlready(String nom) {
    return '📦 Already in stock: $nom';
  }

  @override
  String impCodeStock(String code, String stock) {
    return 'Code: $code • Stock: $stock';
  }

  @override
  String get impSame => 'Same product';

  @override
  String get impNew => 'New product';

  @override
  String impStockChange(String avant, String apres) {
    return 'Stock: $avant → $apres';
  }

  @override
  String impWillCreate(String qte) {
    return 'A new product will be created ($qte piece(s)).';
  }

  @override
  String impNewLine(String qte, String code, String achat, String vente) {
    return 'New product • Qty: $qte$code\nCost: $achat • Price: $vente';
  }

  @override
  String impExistsLine(
      String nom, String avant, String apres, String achat, String vente) {
    return 'Already exists$nom • Stock: $avant → $apres\nCost: $achat • Price: $vente';
  }

  @override
  String impSkipped(String n, String raison) {
    return 'Line $n skipped: $raison';
  }

  @override
  String get impPreview => 'Import preview';

  @override
  String get impColumns => 'Columns found:';

  @override
  String get impColCode => 'Barcode';

  @override
  String get impColName => 'Name';

  @override
  String get impColQty => 'Quantity';

  @override
  String get impColCost => 'Cost price';

  @override
  String get impColPrice => 'Selling price';

  @override
  String get impNoHeader =>
      'No title row: the order A=Code, B=Name, C=Qty, D=Cost, E=Price is used.';

  @override
  String get impType => 'Import type:';

  @override
  String get impModeArrivalInfo =>
      'The file quantities are ADDED to the current stock (new goods received).';

  @override
  String get impModeInventoryInfo =>
      'The stock is REPLACED by the file quantities (after a physical count).';

  @override
  String get impSupplier => 'Supplier';

  @override
  String get impListNo => 'List no.';

  @override
  String impChipNew(String n) {
    return '$n new';
  }

  @override
  String impChipUpd(String n) {
    return '$n updated';
  }

  @override
  String impChipSkip(String n) {
    return '$n skipped';
  }

  @override
  String impChipCheck(String n) {
    return '$n to check';
  }

  @override
  String impToCheck(String n) {
    return '$n product(s) to check (in orange): choose for each one.';
  }

  @override
  String get impChecked => 'Products checked ✔ (you can still change)';

  @override
  String get impAllSame => 'All: same product';

  @override
  String get impAllNew => 'All: new product';

  @override
  String get impEmpty => 'No product found in this file.';

  @override
  String impChooseFirst(String n) {
    return 'Choose first: $n to check';
  }

  @override
  String impImportN(String n) {
    return 'Import $n product(s)';
  }

  @override
  String get impModeArrivalWarn =>
      'ARRIVAL mode: quantities will be ADDED to the stock.';

  @override
  String get impModeInventoryWarn =>
      'INVENTORY mode: the stock will be REPLACED by the file quantities.';

  @override
  String get impOffline =>
      'No internet: changes will be sent when the network returns.';

  @override
  String get impUnchanged => 'unchanged';

  @override
  String get impInventory => 'Inventory';

  @override
  String get arrTitle => 'Arrivals (packing lists)';

  @override
  String get arrEmpty =>
      'No arrival yet.\n\nImport a packing list in « Arrival » mode (Stock → Import): it will appear here with its supplier and products.';

  @override
  String arrNo(String n) {
    return 'No. $n';
  }

  @override
  String get arrNoSupplier => 'Supplier not given';

  @override
  String arrListLine(
      String date, String boutique, String produits, String pieces) {
    return '$date · $boutique\n$produits product(s) · $pieces piece(s)';
  }

  @override
  String get arrNoNet => 'No internet connection: try again.';

  @override
  String get arrCancelQ => 'Cancel this arrival?';

  @override
  String arrCancelBody(String pieces) {
    return 'The quantities of this packing list will be REMOVED from the stock ($pieces piece(s)). Prices changed by the import stay as they are.';
  }

  @override
  String get no => 'No';

  @override
  String get arrCancelBtn => 'Cancel the arrival';

  @override
  String get arrCancelled => 'Arrival cancelled.';

  @override
  String get arrCancelOffline =>
      'No connection: the cancellation will be sent when the internet returns.';

  @override
  String arrCancelError(String erreur) {
    return 'Cancellation failed: $erreur';
  }

  @override
  String get arrSheet => 'Arrival sheet';

  @override
  String get arrNotFound => 'Arrival not found.';

  @override
  String arrPlNo(String n) {
    return 'Packing list no. $n';
  }

  @override
  String arrReceived(String date) {
    return 'Received on $date';
  }

  @override
  String arrShop(String nom) {
    return 'Shop: $nom';
  }

  @override
  String arrFile(String nom) {
    return 'File: $nom';
  }

  @override
  String arrCounts(String produits, String pieces) {
    return '$produits product(s) · $pieces piece(s)';
  }

  @override
  String arrCancelledOn(String date) {
    return 'CANCELLED on $date';
  }

  @override
  String get arrSales => 'Sales of this arrival';

  @override
  String arrSoldLeft(String vendu, String reste) {
    return 'Sold: $vendu piece(s) · Left: $reste piece(s)';
  }

  @override
  String arrRevenue(String montant) {
    return 'Sales money: $montant';
  }

  @override
  String arrCost(String montant) {
    return 'Cost of pieces sold: $montant';
  }

  @override
  String arrProfit(String montant) {
    return 'Profit: $montant';
  }

  @override
  String get arrOldestFirst =>
      'Nguli suggests the oldest stock first; the seller can choose another.';

  @override
  String arrLineCost(String montant) {
    return 'Cost $montant';
  }

  @override
  String arrLinePrice(String montant) {
    return 'Price $montant';
  }

  @override
  String get arrLineNew => 'new product';

  @override
  String arrLineStats(String vendu, String reste, String benefice) {
    return 'Sold $vendu · left $reste · profit $benefice';
  }

  @override
  String get arrCancelThis => 'Cancel this arrival';

  @override
  String get stockImportExcel => 'Excel / CSV file';

  @override
  String get stockImportPhoto => 'Invoice photo (AI)';

  @override
  String get arrMainShop => 'Main shop';

  @override
  String get arrCancelledTag => 'CANCELLED';

  @override
  String arrCancelMissing(String n) {
    return '$n piece(s) are no longer in stock (already sold or taken out): the stock of these products will become negative.';
  }

  @override
  String arrCancelDeleted(String n) {
    return '$n product(s) were deleted since then: they are skipped.';
  }

  @override
  String trfOnly(String nom, String dispo, String boutique) {
    return '« $nom »: only $dispo available at $boutique.';
  }

  @override
  String get trfConfirm => 'Confirm the transfer';

  @override
  String trfTotal(String n) {
    return 'Total: $n item(s)';
  }

  @override
  String get trfDo => 'Transfer';

  @override
  String get trfOffline =>
      'Transfer saved offline: it will be sent when the network returns.';

  @override
  String trfDone(String de, String vers) {
    return 'Transfer done: $de → $vers';
  }

  @override
  String get trfTitle => 'Stock transfers';

  @override
  String get accessRestricted => 'Restricted access';

  @override
  String get oneShopOnly => 'Only one shop';

  @override
  String get searchProduct => 'Search a product…';

  @override
  String get trfAll => 'Transfer all';

  @override
  String get trfNoProduct => 'No product available';

  @override
  String get trfChooseQty => 'Choose the quantities';

  @override
  String trfSummary(String articles, String produits) {
    return '$articles item(s) • $produits product(s)';
  }

  @override
  String trfAvailable(String n) {
    return 'Available: $n';
  }

  @override
  String trfQtyMax(String n) {
    return 'Quantity (max $n)';
  }

  @override
  String get trfNone => 'No transfer';

  @override
  String get trfTabNew => 'New';

  @override
  String get trfTabHistory => 'History';

  @override
  String pbSavedOffline(String n) {
    return '$n prices saved offline (sent when the network returns)';
  }

  @override
  String pbSaved(String n) {
    return '$n prices saved';
  }

  @override
  String get pbChooseShop => 'Choose the shop…';

  @override
  String get pbPickShop => 'Choose a shop';

  @override
  String get pbEmptyNormal => 'Empty field = normal price';

  @override
  String pbChanged(String n) {
    return '$n price(s) changed';
  }

  @override
  String get pbTitle => 'Price per shop';

  @override
  String pbNormal(String prix) {
    return 'Normal price: $prix';
  }

  @override
  String get trfNeedStock =>
      'You need the « Manage stock » permission to make transfers.';

  @override
  String get trfNeedTwoShops =>
      'Create at least 2 shops (Settings → My shops) to transfer stock.';

  @override
  String get trfAllSearch => 'All (search)';

  @override
  String get trfNoStock => 'This shop has no stock to transfer.';

  @override
  String get trfNoneInfo => 'Completed transfers will appear here.';

  @override
  String get pbNeedStock =>
      'You need the « Manage stock » permission to change prices.';

  @override
  String get pbNeedTwoShops =>
      'Create at least 2 shops to set different prices.';

  @override
  String get pbPickShopInfo =>
      'Then enter the selling price of each product in this shop.';

  @override
  String repColAmount(String devise) {
    return 'Amount ($devise)';
  }

  @override
  String get repToday => 'TODAY';

  @override
  String get repYesterday => 'YESTERDAY';

  @override
  String get rep7Days => '7 DAYS';

  @override
  String get repThisMonth => 'THIS MONTH';

  @override
  String get repLastMonth => 'LAST MONTH';

  @override
  String get repThisYear => 'THIS YEAR';

  @override
  String get repDates => 'DATES…';

  @override
  String get repColItem => 'Item';

  @override
  String get repGross => 'Gross sales';

  @override
  String get repReturns => 'Returns and cancellations';

  @override
  String get repNetSales => 'NET SALES';

  @override
  String get repCogs => 'Cost of goods sold';

  @override
  String get repGrossMargin => 'GROSS MARGIN';

  @override
  String get repOtherIncome => 'Other income (deposits kept)';

  @override
  String repOfWhich(String nom) {
    return 'of which $nom';
  }

  @override
  String get repLosses => 'Losses (damaged items)';

  @override
  String get repNet => 'NET RESULT';

  @override
  String get repNbSales => 'Number of sales';

  @override
  String get repAvgBasket => 'Average basket';

  @override
  String get repCashedLong => 'Collected (paid at sale)';

  @override
  String get repCreditsLong => 'Credit given (left to pay)';

  @override
  String get repByShopUp => 'BY SHOP';

  @override
  String get repShopSales => 'Net sales / number of sales';

  @override
  String get repShopCash => 'Collected / credit';

  @override
  String get repStockCost => 'Stock (cost price)';

  @override
  String get repBySellerUp => 'BY SELLER';

  @override
  String repSellerLine(String nom, String n) {
    return '$nom ($n sale(s))';
  }

  @override
  String get repTopUp => 'BEST-SELLING PRODUCTS';

  @override
  String get repDormantUp => 'NOT MOVING (in stock, no sale)';

  @override
  String repFull(String periode) {
    return 'Full report $periode';
  }

  @override
  String repFromTo(String debut, String fin) {
    return 'from $debut to $fin';
  }

  @override
  String get repAllShops => 'All shops';

  @override
  String get repIncomeStatement => 'Income statement';

  @override
  String get repExportExcel => 'Export to Excel';

  @override
  String get repPrintPdf => 'Print / PDF';

  @override
  String repExpError(String erreur) {
    return 'Expenses error: $erreur';
  }

  @override
  String repLoadError(String erreur) {
    return 'Could not load the data: $erreur';
  }

  @override
  String get repSearchClient => 'Search a customer';

  @override
  String repPaidAtSale(String devise) {
    return '$devise • paid at sale';
  }

  @override
  String get repCreditsGiven => 'Credit given';

  @override
  String repLeftToPay(String devise) {
    return '$devise • left to pay';
  }

  @override
  String get repTapDetail => 'Tap a line for details';

  @override
  String get repByShop => 'By shop';

  @override
  String get repTop => 'Best-selling products';

  @override
  String get repDormant => 'Not moving';

  @override
  String repAmountsNote(String devise) {
    return 'Amounts in $devise • Compared with the previous period of the same length.';
  }

  @override
  String get repVsPrevNone => '— vs prev. period';

  @override
  String repVsPrev(String pct) {
    return '$pct % vs prev. period';
  }

  @override
  String get repNoActivity => 'No activity in this period';

  @override
  String get repNetMargin => 'Net margin';

  @override
  String get repNetSalesShort => 'Net sales';

  @override
  String get repGrossMarginShort => 'Gross margin';

  @override
  String repBasket(String montant) {
    return 'Basket $montant';
  }

  @override
  String get repDepositsKept => 'Deposits kept';

  @override
  String get repLossesTitle => 'Losses: damaged items';

  @override
  String get repNoData => 'No data in this period';

  @override
  String get repSalesShort => 'Sales';

  @override
  String get repNbShort => 'Sales';

  @override
  String get repCreditsShort => 'Credit';

  @override
  String get repStockShort => 'Stock (cost)';

  @override
  String repNSales(String n) {
    return '$n sale(s)';
  }

  @override
  String repPieces(String n) {
    return '$n piece(s)';
  }

  @override
  String repAndMore(String n) {
    return '… and $n more';
  }

  @override
  String get repAllSold => 'All products in stock have sold 👍';

  @override
  String repTiedUp(String n, String montant) {
    return '$n product(s) • $montant tied up (cost price)';
  }

  @override
  String repStockN(String n) {
    return 'Stock: $n';
  }

  @override
  String get repWhoOwes => 'Who still owes';

  @override
  String get repPeriodSales => 'Sales of the period';

  @override
  String repUnitCost(String montant) {
    return 'Unit cost price: $montant';
  }

  @override
  String get repMarginPerItem => 'Margin per item';

  @override
  String repSaleCost(String vente, String achat) {
    return 'Sale: $vente | Cost: $achat';
  }

  @override
  String get repExpByCat => 'Costs and expenses by category';

  @override
  String repPctOfCosts(String pct) {
    return '$pct % of costs';
  }

  @override
  String get repNetResult => 'Net result';

  @override
  String get repSold => 'Sold';

  @override
  String get repAmount => 'Amount';

  @override
  String get repStockValue => 'Stock / cost value';

  @override
  String get repDormantInfo => 'In stock, no sale';

  @override
  String get repCostsExpenses => 'Costs and expenses';

  @override
  String rateAdjustTip(String devise) {
    return 'Adjust the $devise rate';
  }

  @override
  String rateTitle(String code) {
    return 'Exchange rate (USD → $code)';
  }

  @override
  String rateAdjustInfo(String devise) {
    return 'Adjust the official / market rate for $devise:';
  }

  @override
  String get rateUpdate => 'Update';

  @override
  String get bakTitle => '💾 Full backup';

  @override
  String get bakInfo =>
      'All the data in one file to keep (WhatsApp, Drive). Tip: every week and before a big operation.';

  @override
  String get bakReady => '💾 Backup ready';

  @override
  String bakError(String erreur) {
    return 'Backup failed (internet needed): $erreur';
  }

  @override
  String get shopLabel => 'Shop:';

  @override
  String shopDisabled(String nom) {
    return '$nom (disabled)';
  }

  @override
  String shopMemberMoved(String membre, String boutique) {
    return '$membre now works at « $boutique »';
  }

  @override
  String get shopChoose => 'Choose the shop';

  @override
  String get jrnCardTitle => '📒 Log: who did what';

  @override
  String get jrnCardInfo =>
      'The team\'s actions day by day: sales, returns, stock, debts…';

  @override
  String jrnError(String erreur) {
    return 'Log unreadable: $erreur';
  }

  @override
  String get jrnEmpty => 'No action recorded that day.';

  @override
  String get jrnEveryone => 'Everyone';

  @override
  String get cptMonths =>
      'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String cptSynced(String n) {
    return '$n sales caught up!';
  }

  @override
  String get cptUpToDate => 'Journal cleaned and up to date.';

  @override
  String cptSyncError(String erreur) {
    return 'Synchronisation error: $erreur';
  }

  @override
  String cptCleaned(String n) {
    return 'Cleaning done: $n outdated entry(ies) removed.';
  }

  @override
  String get cptNothingToClean => 'No outdated entry found.';

  @override
  String cptCleanError(String erreur) {
    return 'Cleaning error: $erreur';
  }

  @override
  String get cptExportingPdf => 'Exporting the general ledger PDF…';

  @override
  String get cptExportingCsv => 'Exporting CSV / Excel…';

  @override
  String get cptReversed => 'Entry reversed.';

  @override
  String cptReverseError(String erreur) {
    return 'Reversal error: $erreur';
  }

  @override
  String get cptConfirmDelete => 'Confirm deletion';

  @override
  String get cptDeleteQ =>
      'Do you really want to delete this accounting entry?';

  @override
  String get cptDeleted => 'Entry deleted.';

  @override
  String cptDeleteError(String erreur) {
    return 'Deletion error: $erreur';
  }

  @override
  String get cptTitle => 'SYSCOHADA accounting';

  @override
  String get cptExportPdf => 'Export the general ledger PDF';

  @override
  String get cptSyncTip => 'Sync / catch up sales';

  @override
  String get cptCleanDup => 'Clean duplicates';

  @override
  String get cptExportCsv => 'Export CSV / Excel';

  @override
  String get cptTabJournal => 'Journal';

  @override
  String get cptTabBalance => 'Balance & summary';

  @override
  String cptLoadError(String erreur) {
    return 'Loading error: $erreur';
  }

  @override
  String get cptManual => 'Manual entry (OD)';

  @override
  String get cptSearch => 'Search label, account…';

  @override
  String get cptAcc701 => '701 Sales';

  @override
  String get cptAcc411 => '411 Customers';

  @override
  String get cptAcc419 => '419 Advances';

  @override
  String get cptAcc571 => '571 Cash';

  @override
  String get cptAcc521 => '521 Bank';

  @override
  String get cptAcc6 => 'Class 6 Expenses';

  @override
  String get cptAll => 'All';

  @override
  String get cptAccount => 'Account';

  @override
  String get cptNoMatch => 'No entry matches the criteria.';

  @override
  String get cptCatchUp => 'Catch up past sales';

  @override
  String get cptReverse => 'Reverse (cancel)';

  @override
  String get cptSummary => 'General summary';

  @override
  String get cptCash => 'Total cash (571/521)';

  @override
  String get cptRevenue => 'Revenue / sales (701)';

  @override
  String get cptAdvances => 'Advances and deposits received (419)';

  @override
  String get cptReceivables => 'Customer receivables (411)';

  @override
  String get cptCharges => 'Expenses and purchases (class 6)';

  @override
  String get cptResult => 'Estimated result (sales − expenses)';

  @override
  String get cptBalanceNote =>
      'From the start until today. Finished months are summarised once, to go fast.';

  @override
  String get cptRecompute => 'Recompute the whole balance';

  @override
  String get ecrMin2 => 'An entry needs at least 2 lines.';

  @override
  String get ecrNeedAmount => 'Enter at least one debit or credit amount.';

  @override
  String ecrUnbalanced(String ecart) {
    return 'The entry is not balanced (difference: $ecart).';
  }

  @override
  String get ecrNew => 'New entry';

  @override
  String get ecrEdit => 'Edit the entry';

  @override
  String get ecrDate => 'Entry date';

  @override
  String get ecrRef => 'Document no. / ref.';

  @override
  String get ecrLabel => 'Document label';

  @override
  String get ecrLines => 'Entry lines';

  @override
  String get ecrAddLine => 'Add a line';

  @override
  String get ecrAccount => 'SYSCOHADA account';

  @override
  String get ecrAccountHint => 'e.g. 601100';

  @override
  String get ecrAccountName => 'Account name';

  @override
  String get ecrAccountNameHint => 'e.g. Purchases of goods';

  @override
  String get ecrDebit => 'Debit';

  @override
  String get ecrCredit => 'Credit';

  @override
  String ecrTotalDebit(String montant) {
    return 'Total debit: $montant';
  }

  @override
  String ecrTotalCredit(String montant) {
    return 'Total credit: $montant';
  }

  @override
  String get ecrBalanced => 'Balanced';

  @override
  String ecrGap(String ecart) {
    return 'Difference: $ecart';
  }

  @override
  String get rcNone => 'No customer found';

  @override
  String get rcOther => 'Other customers';

  @override
  String get rcSearch => '🔎 Search a customer';

  @override
  String get rcName => 'Customer name…';

  @override
  String get rcLoading => 'Loading…';

  @override
  String get rcLoadingDebts => 'Loading debts…';

  @override
  String rcOwesTotal(String montant) {
    return 'Owes in total: $montant';
  }

  @override
  String get rcOwesNothing => 'Owes nothing';

  @override
  String get rcPurchasesPeriod => 'Purchases (period)';

  @override
  String get rcPaid => 'Paid';

  @override
  String get rcPurchases => 'Purchases in the period';

  @override
  String get rcNoPurchase => 'No purchase in this period.';

  @override
  String rcLeft(String montant) {
    return 'left $montant';
  }

  @override
  String get rcDebts => 'Debts and payments (all periods)';

  @override
  String get rcNoDebt => 'No debt recorded.';

  @override
  String rcCreditOf(String montant) {
    return 'Credit of $montant';
  }

  @override
  String get rcSettled => 'settled ✔';

  @override
  String get iaTakePhoto => 'Take a photo';

  @override
  String get iaPickImage => 'Choose an image or a screenshot';

  @override
  String iaCameraError(String erreur) {
    return 'Could not open the camera: $erreur';
  }

  @override
  String get iaReading =>
      '🤖 The AI is reading the document…\nA big table can take up to 2 minutes. Keep the app open.';

  @override
  String get iaTimeout =>
      'The AI took too long. Try a photo of part of the table (20 to 25 lines), or a better connection.';

  @override
  String get iaCut =>
      'The internet connection dropped while sending. Try again with a better network.';

  @override
  String iaFailed(String detail) {
    return 'The AI could not read the document. Detail: $detail';
  }

  @override
  String get iaNothing =>
      'The AI found no product. Try a sharper, straight photo.';

  @override
  String get iaOtherCurrency => 'Prices in another currency';

  @override
  String iaRateQ(String devise, String code) {
    return 'The prices in this document are in $devise.\nHow many $code for 1 \$? Prices will be converted to dollars.';
  }

  @override
  String get plImportPhoto => 'Import a photo';

  @override
  String plTargetShop(String boutique) {
    return 'The goods will be added to the shop:\n\n🏬 $boutique\n\nFor another shop, first switch shop in the app.';
  }

  @override
  String get plContinue => 'Continue';

  @override
  String plImported(String n) {
    return '$n product(s) imported or updated.';
  }

  @override
  String plImportError(String erreur) {
    return 'Import error: $erreur';
  }

  @override
  String get plImportFile => 'Import a file';

  @override
  String get impFees => 'Costs (freight, transport, customs…)';

  @override
  String get impReadByAi =>
      '🤖 Read by the AI on the invoice: check before importing';

  @override
  String impInvoiceDate(String date) {
    return 'invoice of $date';
  }

  @override
  String arrFees(String montant) {
    return 'Costs (freight, transport…): $montant';
  }

  @override
  String arrProfitAfterFees(String montant) {
    return 'Profit after costs: $montant';
  }

  @override
  String arrInvoiceDate(String date) {
    return 'Invoice of $date';
  }

  @override
  String get astTitle => '✨ Ask Nguli';

  @override
  String get astIntro =>
      'Hello! I know your shop\'s figures for the last 30 days: sales, stock, credit, expenses. Ask me a question.';

  @override
  String get astLoading => 'Reading the shop\'s figures…';

  @override
  String get astLoadError =>
      'Could not read the figures. Check the internet and try again.';

  @override
  String get astPlaceholder => 'Your question…';

  @override
  String get astSuggest1 => 'How much did I sell yesterday?';

  @override
  String get astSuggest2 => 'Which products should I reorder?';

  @override
  String get astSuggest3 => 'Which seller sells the most?';

  @override
  String get astSuggest4 => 'Who owes me the most money?';

  @override
  String get astNoAnswer => 'I have no answer. Rephrase the question.';

  @override
  String get astTimeout =>
      'The answer is taking too long. Check the internet and try again.';

  @override
  String get astError =>
      'I could not answer (internet or service unavailable). Try again.';

  @override
  String get astDisclaimer =>
      'AI answers based on the last 30 days: check important figures.';

  @override
  String get astMicTip => 'Ask the question out loud';

  @override
  String get astListening => '🎤 Listening… tap ⏹ to send';

  @override
  String get astMicDenied =>
      'Allow the microphone in the phone settings to talk to Nguli.';

  @override
  String get astReadAloud => 'Read aloud';

  @override
  String get astVoiceOn => 'Read the answers aloud';

  @override
  String get astVoiceOff => 'Stop reading the answers';

  @override
  String get astBusy =>
      'Google\'s AI is very busy right now. Try again in a minute.';
}
