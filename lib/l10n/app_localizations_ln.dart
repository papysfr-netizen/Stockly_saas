// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lingala (`ln`).
class AppLocalizationsLn extends AppLocalizations {
  AppLocalizationsLn([String locale = 'ln']) : super(locale);

  @override
  String get appTitle => 'Stockly Pro';

  @override
  String get settings => 'Bibongisi';

  @override
  String get storeInfo => 'Sango ya magazini';

  @override
  String get storeName => 'Nkombo ya magazini';

  @override
  String get address => 'Adresi';

  @override
  String get phone => 'Telefone';

  @override
  String get saveInfo => 'Bomba sango';

  @override
  String get bccSection => 'Motuya ya BCC mpe mbongo';

  @override
  String get bccRate => 'Motuya ya mbongo (BCC)';

  @override
  String get activeCurrency => 'Mbongo ya liboso';

  @override
  String get appLanguage => 'Lokota ya programe';

  @override
  String get reportsExport => 'Kobimisa ba données';

  @override
  String get exportExcel => 'Bimisa biloko na Excel';

  @override
  String get dbMaintenance => 'Kobongisa';

  @override
  String get mergeDuplicates => 'Sangisa biloko oyo ezali mbala mibale';

  @override
  String get teamManagement => 'Ekipi mpe ba ndingisa';

  @override
  String get teamManagementSubtitle =>
      'Bakisa basali mpe bongisa makoki na bango';

  @override
  String get navAccueil => 'Ebandeli';

  @override
  String get navCaisse => 'Kesi';

  @override
  String get navStock => 'Biloko';

  @override
  String get navRapport => 'Lapolo';

  @override
  String get navParametres => 'Mibongiseli';

  @override
  String accHello(String prenom) {
    return 'Mbote $prenom 👋';
  }

  @override
  String get tauxTitle => 'Motuya ya dolare lelo';

  @override
  String get cancel => 'Tika';

  @override
  String get save => 'Kobomba';

  @override
  String get accToday => 'LELO';

  @override
  String get accOfSales => 'ya biteki';

  @override
  String get accCashed => 'Mbongo ezwami';

  @override
  String get accCredit => 'Niongo';

  @override
  String get accExpenses => 'Bibimisi';

  @override
  String accCashInDrawer(String montant) {
    return 'Mbongo na kesi lelo : $montant';
  }

  @override
  String accDiscounts(String montant) {
    return 'Bakitisi talo : $montant';
  }

  @override
  String get accSendSummary => 'Tinda bokuse ya lelo';

  @override
  String get accExpense => 'Mbimisi';

  @override
  String get accSales => 'Biteki';

  @override
  String get accClientAccounts => 'Ba compte ya bakiliya';

  @override
  String get accAccounting => 'Botangi mbongo';

  @override
  String get accHelp => 'Lisalisi';

  @override
  String accTodaySales(int count) {
    return 'Biteki ya lelo ($count)';
  }

  @override
  String get accNoSales =>
      'Naino biteki te lelo.\nFina « Kesi » mpo na kobanda.';

  @override
  String get accClient => 'Mosombi';

  @override
  String accRemaining(String montant) {
    return 'etikali $montant';
  }

  @override
  String get accMainShop => 'Magazini monene';

  @override
  String get resMorning => 'Mbote';

  @override
  String get resAfternoon => 'Mbote';

  @override
  String get resEvening => 'Mbote';

  @override
  String get resNoSales => 'Naino biteki te lelo. Mosala malamu! 💪';

  @override
  String get resTodayPrefix => 'Lelo, ';

  @override
  String resSalesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'biteki $count',
      one: 'eteki 1',
    );
    return '$_temp0';
  }

  @override
  String get resFor => ' ya ';

  @override
  String get resGained => '. Ozwi litomba ya ';

  @override
  String get resLoss => '. Sikawa, bobungisi ya ';

  @override
  String get todoTitle => '📋 Oyo ya kosala lelo';

  @override
  String get todoNothing => '✅ Eloko ya nsoko te. Nyonso ezali malamu!';

  @override
  String todoOwes(String nom, String montant) {
    return '$nom azali na niongo na yo $montant';
  }

  @override
  String todoOtherClients(int count) {
    return '…mpe bakiliya mosusu $count';
  }

  @override
  String todoOut(String nom) {
    return '$nom : esili';
  }

  @override
  String todoLow(int count, String nom) {
    return 'Etikali kaka $count ya $nom';
  }

  @override
  String todoOtherProducts(int count) {
    return '…mpe biloko mosusu $count ya kosomba lisusu';
  }

  @override
  String get actSee => 'Tala';

  @override
  String get actAll => 'Nyonso';

  @override
  String get caisseNoCompany => 'Libunga: kompanyi eponami te.';

  @override
  String caisseOutOfStock(String nom) {
    return '$nom esili na stock!';
  }

  @override
  String caisseStockLimit(int count) {
    return 'Ndelo ya stock ekoki ($count)';
  }

  @override
  String caisseAdded(String nom) {
    return '$nom ebakisami na panier!';
  }

  @override
  String caisseNoBarcode(String code) {
    return 'Eloko moko te na kode : $code';
  }

  @override
  String get caisseSearch => 'Luka eloko…';

  @override
  String get caisseScan => 'Tanga kode-barre';

  @override
  String errorPrefix(String message) {
    return 'Libunga : $message';
  }

  @override
  String get caisseNoProducts =>
      'Biloko ezali te.\nBakisa biloko na yo na « Biloko ».';

  @override
  String get caisseHint =>
      'Simba eloko mpo na kobakisa • simba ntango molai: motango';

  @override
  String get caisseNoMatch => 'Eloko moko te ekokani na oyo olukaki.';

  @override
  String caisseCheckout(String montant) {
    return 'Zwa mbongo $montant';
  }

  @override
  String get caisseNoName => 'Kombo te';

  @override
  String get caisseOut => 'Esili';

  @override
  String get caissePriceNeedsPermission =>
      'Kobongola talo esengeli ndingisa ya « Bakitisi mpe kobimisa ».';

  @override
  String get cartTitle => 'Panier';

  @override
  String get cartEmpty => 'Panier na yo ezali pamba';

  @override
  String cartCount(int count) {
    return 'Panier (biloko $count)';
  }

  @override
  String get cartClear => 'Longola nyonso na panier';

  @override
  String cartNormalPrice(String montant) {
    return 'Talo ya momesano : $montant';
  }

  @override
  String get cartLoss => 'Koteka na bobungisi';

  @override
  String addTitle(String nom) {
    return 'Bakisa $nom';
  }

  @override
  String lossConfirm(String nom) {
    return 'Talo ya $nom ezali na se ya talo ya kosomba.\nOlingi solo koteka na talo oyo?';
  }

  @override
  String get noCorrect => 'Te, bongisa';

  @override
  String get yesSell => 'Iyo, teka';

  @override
  String stockAvailable(int count) {
    return 'Biloko ezali : $count';
  }

  @override
  String unitPrice(String code) {
    return 'Talo ya moko ($code)';
  }

  @override
  String discountPerPiece(String montant) {
    return 'Bokitisi : $montant mpo na moko';
  }

  @override
  String get fixedPrice =>
      'Talo ebongwanaka te (ndingisa ya « Bakitisi mpe kobimisa » esengeli)';

  @override
  String lossWithCost(String montant) {
    return 'Ozali koteka na bobungisi! Talo ya kosomba : $montant';
  }

  @override
  String get lossBelowCost =>
      'Bobungisi: talo oyo ezali na se ya talo ya kosomba.';

  @override
  String get qtyInvalid => 'Motango ebongi te';

  @override
  String maxAvailable(int count) {
    return 'Motango monene : $count';
  }

  @override
  String get quantity => 'Motango';

  @override
  String get subtotal => 'Motango ya ndambo :';

  @override
  String qtyOverStock(int count) {
    return 'Motango eleki stock oyo ezali ($count)';
  }

  @override
  String get outOfStockGeneric => 'Eloko esili!';

  @override
  String get sellAtLoss => 'Teka na bobungisi';

  @override
  String get add => 'Bakisa';

  @override
  String priceFor(String nom) {
    return 'Talo ya $nom';
  }

  @override
  String get agreedPrice => 'Talo ya boyokani (mpo na moko)';

  @override
  String get normalPriceBtn => 'Talo ya momesano';

  @override
  String get validate => 'Ndima';

  @override
  String get payTitle => 'Silisa eteki mpe kofuta';

  @override
  String get payClientName => 'Kombo ya mosombi';

  @override
  String get payPhone => 'Telefone (ndakisa: +243...)';

  @override
  String payClientAccount(String montant) {
    return 'Compte ya mosombi : $montant';
  }

  @override
  String get payUse => 'Salela';

  @override
  String payPaidByAccount(String montant, String solde) {
    return 'Efutami na compte : $montant • Mbongo etikali : $solde';
  }

  @override
  String get payMethod => 'Lolenge';

  @override
  String get payStatus => 'Ezalela';

  @override
  String get payCash => 'Mbongo ya maboko';

  @override
  String get payCard => 'Karte ya banki';

  @override
  String get payTransfer => 'Kotinda na banki';

  @override
  String get payPaid => 'Efutami';

  @override
  String get payDebt => 'Niongo';

  @override
  String get payPartial => 'Kofuta ndambo';

  @override
  String get payInvoiceTotal => 'Motango ya fakture :';

  @override
  String get payPaidByClientAccount => 'Efutami na compte ya mosombi :';

  @override
  String get payToCollect => 'Kozwa sikoyo :';

  @override
  String payAllIn(String code) {
    return 'Nyonso na $code';
  }

  @override
  String payRestIn(String code) {
    return 'Oyo etikali na $code';
  }

  @override
  String payReceived(String code) {
    return 'Mbongo ezwami ($code)';
  }

  @override
  String get payRemaining => 'Oyo etikali kofuta :';

  @override
  String payChange(String code) {
    return 'Mbongo ya kozongisa ($code) :';
  }

  @override
  String get payDelivery => 'Bopesi';

  @override
  String get payDeliveredNow => 'Epesami sikoyo';

  @override
  String get payDeliverLater => 'Ekopesama na nsima';

  @override
  String get payPickupBefore => 'Kozwa liboso ya';

  @override
  String payDeadline(String date) {
    return 'Mokolo ya suka : $date — mosombi akomonana na « Ya kopesa ».';
  }

  @override
  String payDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mikolo $count',
      one: 'mokolo 1',
    );
    return '$_temp0';
  }

  @override
  String get payReceiptActions => 'Makambo ya resi :';

  @override
  String get payPrintReceipt => 'Bimisa resi';

  @override
  String get paySendWhatsApp => 'Tinda na WhatsApp';

  @override
  String get paySendSms => 'Tinda na SMS';

  @override
  String get payValidate => 'Ndima mpe zwa mbongo';

  @override
  String payBalanceChanged(String montant) {
    return 'Mbongo ya mosombi ebongwani (ezali : $montant \$). Kufisa mpe zongisa « Salela » mpo na kotanga lisusu.';
  }

  @override
  String get payNotSaved => 'Eteki EBOMBAMI TE';

  @override
  String payDenied(String code) {
    return 'Serveur eboyi eteki oyo (ndingisa ekoki te).\n\nEloko moko te ebombami: eteki te, stock te, kesi te.\nPesa naino biloko te: yebisa mokambi.\n\nKode : $code';
  }

  @override
  String payNotSavedOther(String detail) {
    return 'Eloko moko te ebombami.\n\n$detail';
  }

  @override
  String get payUnderstood => 'Nayoki';

  @override
  String get paySaved => 'Eteki ebombami malamu!';

  @override
  String paySavedPickup(String date) {
    return 'Eteki ebombami — ezwama liboso ya $date.';
  }

  @override
  String payNewBalance(String montant) {
    return ' Mbongo ya sika ya mosombi : $montant.';
  }

  @override
  String payError(String message) {
    return 'Libunga na tango ya kondima : $message';
  }

  @override
  String get debtNewClient => 'Niongo ya sika ya mosombi';

  @override
  String get debtNewSupplier => 'Niongo ya sika ya mosombisi';

  @override
  String get debtClientName => 'Kombo ya mosombi *';

  @override
  String get debtSupplierName => 'Kombo ya mosombisi *';

  @override
  String get debtInvoiceRef => 'Nimero ya fakture / Référence';

  @override
  String get debtTotal => 'Motango mobimba *';

  @override
  String get debtAlreadyPaid => 'Mbongo esili kofutama (kofuta ndambo)';

  @override
  String get debtPickDueDate => 'Pona mokolo ya kofuta';

  @override
  String debtDueDate(String date) {
    return 'Mokolo ya kofuta : $date';
  }

  @override
  String get debtNote => 'Ntina (soki olingi)';

  @override
  String get debtPaidOverTotal => 'Mbongo efutami eleki motango mobimba.';

  @override
  String debtPaymentTitle(String nom) {
    return 'Kofuta : $nom';
  }

  @override
  String debtInvoiceNo(String numero) {
    return 'Fakture nimero : $numero';
  }

  @override
  String debtRemainingNow(String montant) {
    return 'Oyo etikali kofuta sikoyo : $montant';
  }

  @override
  String get debtPaymentAmount => 'Motango ya kofuta';

  @override
  String debtHelperSurplus(String montant) {
    return 'Etikali : $montant. Oyo eleki ekoki kokende na compte ya mosombi.';
  }

  @override
  String debtMax(String montant) {
    return 'Motango monene : $montant';
  }

  @override
  String get debtPaymentMode => 'Lolenge ya kofuta';

  @override
  String get debtCashDesk => 'Mbongo ya maboko (kesi)';

  @override
  String get debtCheck => 'Chèque';

  @override
  String get debtEnterAmount => 'Koma motango.';

  @override
  String debtTooHighNoPhone(String montant) {
    return 'Eleki mingi. Motango monene : $montant (mosombi azali na nimero te: compte ezali te)';
  }

  @override
  String debtTooHigh(String montant) {
    return 'Eleki mingi. Motango monene : $montant';
  }

  @override
  String get debtGivesMore => 'Mosombi apesi koleka';

  @override
  String debtSurplusQuestion(
      String dette, String donne, String surplus, String nom) {
    return 'Niongo : $dette\nApesi : $donne\n\nTia $surplus na compte ya $nom?\nAkoki kosalela yango mpo na bisombi oyo ekoya.';
  }

  @override
  String get debtYesAccount => 'Iyo, na compte na ye';

  @override
  String debtSettled(String montant, String nom) {
    return 'Niongo esili. $montant etiami na compte ya $nom.';
  }

  @override
  String get debtPendingNet => ' (ekotindama soki internet ezongi)';

  @override
  String debtPaymentSaved(String montant) {
    return 'Kofuta ya $montant ebombami.';
  }

  @override
  String get debtValidatePayment => 'Ndima kofuta';

  @override
  String get debtScreenTitle => 'Ba niongo';

  @override
  String get debtExport => 'Bimisa';

  @override
  String get debtExportExcel => 'Bimisa na Excel';

  @override
  String get debtPrintPdf => 'Bimisa / PDF';

  @override
  String get debtTabClients => 'Bakiliya';

  @override
  String get debtTabSuppliers => 'Basombisi';

  @override
  String debtLoadError(String message) {
    return 'Libunga na kofungola : $message';
  }

  @override
  String get debtAdd => 'Bakisa niongo';

  @override
  String get ageToday => 'Lelo';

  @override
  String get ageYesterday => 'Lobi';

  @override
  String ageDays(int count) {
    return 'Mikolo $count eleki';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sanza $count eleki',
      one: 'Sanza 1 eleki',
    );
    return '$_temp0';
  }

  @override
  String get whatsAppError => 'Ekoki kofungola WhatsApp te na telefone oyo.';

  @override
  String get debtEmptyClients => 'Niongo ya mosombi ezali te';

  @override
  String get debtEmptySuppliers => 'Niongo ya mosombisi ezali te';

  @override
  String get debtEmptyClientsHint =>
      'Biteki na niongo to ya ndambo ekomonana awa yango moko.';

  @override
  String get debtEmptySuppliersHint =>
      'Bakisa awa oyo ozali na niongo epai ya basombisi na bouton « Bakisa niongo ».';

  @override
  String get noResults => 'Eloko moko te';

  @override
  String get noResultsHint => 'Meka filtre mosusu to boluki mosusu.';

  @override
  String get debtToCollect => 'KOZWA (BAKILIYA)';

  @override
  String get debtToPay => 'KOFUTA (BASOMBISI)';

  @override
  String debtOpenFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ba dosie efungwami',
      one: 'dosie efungwami',
    );
    return '$_temp0';
  }

  @override
  String debtClientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'basombi',
      one: 'mosombi',
    );
    return '$_temp0';
  }

  @override
  String debtSuppliersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'basombisi',
      one: 'mosombisi',
    );
    return '$_temp0';
  }

  @override
  String debtLateCount(int count) {
    return 'eleki ntango ($count)';
  }

  @override
  String get debtSearchClients => 'Luka mosombi, fakture, telefone…';

  @override
  String get debtSearchSuppliers => 'Luka mosombisi, fakture…';

  @override
  String get filterOngoing => 'Ezali kokoba';

  @override
  String get filterRecent => 'Ya sika (< mikolo 30)';

  @override
  String get filterLate => 'Eleki ntango';

  @override
  String get filterPartial => 'Ya ndambo';

  @override
  String get filterSettled => 'Esili kofutama';

  @override
  String get statusSettled => 'Efutami';

  @override
  String get statusPartial => 'Ndambo';

  @override
  String get statusUnpaid => 'Efutami te';

  @override
  String invoiceShort(String numero) {
    return 'Fakt. $numero';
  }

  @override
  String paidOf(String paye, String total) {
    return 'Efutami $paye na $total';
  }

  @override
  String lastPayment(String date) {
    return 'Kofuta ya suka $date';
  }

  @override
  String get remind => 'Kundolisa';

  @override
  String get message => 'Nsango';

  @override
  String get collect => 'Zwa';

  @override
  String get pay => 'Futa';

  @override
  String printFailed(String message) {
    return 'Ekoki kobimisa te : $message';
  }

  @override
  String get printerTitle => 'Masini ya kobimisa';

  @override
  String get printerPhoneOnly => 'Mibongiseli ya telefone oyo kaka';

  @override
  String get printerPaperWidth => 'Monene ya papie';

  @override
  String get printer58 => '58 mm (moke)';

  @override
  String get printer80 => '80 mm (monene)';

  @override
  String get printerAfterSale => 'Sima ya eteki, resi…';

  @override
  String get printerPrints => 'Ebimi na papie';

  @override
  String get printerPrintsHint =>
      'Lininisa ya kobimisa ya Android (masini etiami na telefone)';

  @override
  String get printerPdf => 'Etindami lokola PDF';

  @override
  String get printerPdfHint =>
      'WhatsApp, Bluetooth, e-mail… (soki masini ezali te)';

  @override
  String get printerTest => 'Bimisa resi ya komeka';

  @override
  String get crashTest => 'Meka ba lapolo ya mabunga';

  @override
  String get crashDebugOnly =>
      'Ba lapolo etindamaka kaka na APK (na nsinga te).';

  @override
  String get crashSent =>
      'Lapolo ya komeka etindami. Ekomonana na Firebase sima ya miniti mwa moke.';

  @override
  String get guideTitle => 'Litambwisi ya kosalela';

  @override
  String get guideSubtitle => 'Ndenge ya koteka, kozwa niongo, kobimisa…';

  @override
  String get guideSearch => 'Luka: niongo, motuya ya dolare, kobimisa…';

  @override
  String guideNotFound(String mot) {
    return 'Eloko moko te emonani mpo na « $mot ».';
  }

  @override
  String get guideOwnerOnly => 'Nkolo / mokambi';

  @override
  String stockDeleted(String nom) {
    return '« $nom » elongwami.';
  }

  @override
  String stockDeletedOffline(String nom) {
    return '« $nom » elongwami na telefone. Ekotindama soki internet ezongi.';
  }

  @override
  String stockDeleteError(String message) {
    return 'Libunga na tango ya kolongola : $message';
  }

  @override
  String get stockAnalyzing => 'Ezali kotala...';

  @override
  String stockImported(int count) {
    return 'Biloko $count ekotisami to ebongisami!';
  }

  @override
  String stockImportError(String message) {
    return 'Libunga na kokotisa : $message';
  }

  @override
  String stockConnected(String nom) {
    return 'Okoti: $nom';
  }

  @override
  String get stockImportTooltip => 'Kotisa Excel / CSV / Packing List';

  @override
  String get myAccount => 'Compte na ngai';

  @override
  String get changePassword => 'Bongola mot de passe na ngai';

  @override
  String get logout => 'Kobima';

  @override
  String get stockNoProduct => 'Eloko moko te emonani.';

  @override
  String get stockProducts => 'Biloko';

  @override
  String get stockValue => 'Motuya ya stock';

  @override
  String get stockCannotDelete => 'Ekoki kolongolama te';

  @override
  String stockCannotDeleteMsg(String nom, int count) {
    return '« $nom » ezali naino na biloko $count na stock.\n\nTia liboso stock na 0 (botangi to bobungisi), mpo bobungisi emonana na mitango.';
  }

  @override
  String get stockDeleteTitle => 'Longola eloko';

  @override
  String stockDeleteConfirm(String nom) {
    return 'Olingi solo kolongola « $nom »?\n\nEkozonga lisusu te.';
  }

  @override
  String get delete => 'Longola';

  @override
  String get stockNewProduct => 'Eloko ya sika';

  @override
  String stockQty(int count) {
    return 'Stock: $count';
  }

  @override
  String get stockAlert => 'Stock ezali kosila';

  @override
  String get edit => 'Bongisa';

  @override
  String get prodDefaultName => 'Eloko ezali na kombo te';

  @override
  String get prodBarcodeUsed => 'Kode-barre esalelami kala';

  @override
  String prodBarcodeUsedMsg(String nom, String stock, String prix) {
    return 'Kode oyo ezali kala ya:\n\n« $nom »\nStock : $stock  •  Talo : $prix \$\n\nOlingi kofungola eloko oyo mpo na kobongisa yango (ndakisa kobakisa stock)?';
  }

  @override
  String get prodOpenThis => 'Fungola eloko oyo';

  @override
  String get prodNoCompany => 'Kompanyi emonani te. Bima mpe kota lisusu.';

  @override
  String get prodSavedOffline =>
      'Ebombami na telefone. Ekotindama soki internet ezongi.';

  @override
  String get prodUpdated => 'Eloko ebongisami!';

  @override
  String get prodAdded => 'Eloko ebakisami!';

  @override
  String prodSaveError(String message) {
    return 'Libunga na tango ya kobomba : $message';
  }

  @override
  String get prodEditTitle => 'Bongisa eloko';

  @override
  String get prodImportPacking => 'Kotisa Packing List (Excel / CSV)';

  @override
  String get prodOrManual => 'TO KOMA YO MOKO';

  @override
  String get prodImageUrl => 'Lien ya foto';

  @override
  String get prodImageUrlOpt => 'Lien ya foto (soki olingi)';

  @override
  String get prodName => 'Kombo ya eloko *';

  @override
  String get prodNameHint => 'ndakisa: T-Shirt ya coton';

  @override
  String get prodNameRequired => 'Kombo esengeli';

  @override
  String get prodBarcode => 'Kode-barre';

  @override
  String get prodBarcodeHint => 'Tanga / Koma';

  @override
  String get prodCategory => 'Lolenge';

  @override
  String get prodBuyPrice => 'Talo ya kosomba (\$)';

  @override
  String get prodInvalidPrice => 'Talo ebongi te';

  @override
  String get prodSellPrice => 'Talo ya koteka (\$)*';

  @override
  String get prodPriceRequired => 'Talo esengeli';

  @override
  String get prodStock => 'Stock *';

  @override
  String get prodInitialStock => 'Stock ya ebandeli *';

  @override
  String get prodStockRequired => 'Stock esengeli';

  @override
  String get prodWholeNumber => 'Motango mobimba';

  @override
  String get prodAlertLevel => 'Ndelo ya kokebisa';

  @override
  String get prodSaving => 'Ezali kobomba...';

  @override
  String get prodUpdate => 'Bongisa';

  @override
  String get prodSave => 'Bomba eloko';

  @override
  String get msgLanguage => 'Monoko ya nsango';

  @override
  String get sumDays =>
      'Mokolo ya liboso,Mokolo ya mibale,Mokolo ya misato,Mokolo ya minei,Mokolo ya mitano,Mposo,Lomingo';

  @override
  String get sumAllShops => 'Ba magazini nyonso';

  @override
  String sumSales(int count, String montant) {
    return 'Biteki : $count ya $montant';
  }

  @override
  String sumCollected(String montant) {
    return 'Mbongo ezwami : $montant';
  }

  @override
  String sumCredit(String montant) {
    return 'Niongo : $montant';
  }

  @override
  String sumExpenses(String montant) {
    return 'Bibimisi : $montant';
  }

  @override
  String sumCash(String montant) {
    return '💵 Mbongo na kesi : $montant';
  }

  @override
  String sumProfit(String montant) {
    return '📈 Litomba : $montant';
  }

  @override
  String sumRate(String taux) {
    return 'Motuya : 1 \$ = $taux FC';
  }

  @override
  String sumSentBy(String nom) {
    return 'Etindami na $nom — Stockly Pro';
  }

  @override
  String get logoutQuestion => 'Kobima?';

  @override
  String get logoutWarning =>
      'Okozala na kokota lisusu na e-mail mpe mot de passe na yo.';

  @override
  String get exportDone => 'Kobimisa na Excel esili malamu!';

  @override
  String exportError(String message) {
    return 'Libunga na kobimisa : $message';
  }

  @override
  String get attention => 'Keba';

  @override
  String get mergeConfirm =>
      'Olingi solo kosangisa biloko oyo ezali mbala mibale? Ekozonga lisusu te.';

  @override
  String get mergeDone => 'Biloko ya mbala mibale esili kopetolama!';

  @override
  String get confirmBtn => 'Ndima';

  @override
  String get backfillTitle => 'Bongisa motuya ya biteki ya kala';

  @override
  String get backfillExplain =>
      'Biteki ya kala oyo ezali naino na ekomeli « Kobima ya stock » te ekozwa yango, na mokolo na yango ya ebandeli.\n\nMotuya etangami na talo ya kosomba ya SIKOYO ya eloko moko na moko.\n\nOkoki kozongela yango kozanga likama: eteki etangamaka mbala mibale te.';

  @override
  String get launch => 'Banda';

  @override
  String get backfillRunning => 'Ezali kobongisa…';

  @override
  String get backfillNothing => 'Eloko ya kobongisa ezali te';

  @override
  String get backfillDone => 'Kobongisa esili';

  @override
  String backfillAllDone(String count) {
    return 'Biteki nyonso ($count) ezali kala na ekomeli « Kobima ya stock ».';
  }

  @override
  String backfillResult(String nb, String total, String cout) {
    return 'Biteki $nb ebongisami na $total.\n\nMotuya ya biloko ebakisami : $cout \$';
  }

  @override
  String backfillNoPrice(String count) {
    return '⚠️ Biloko $count ezali na talo ya kosomba te: motuya na yango etangami 0. Tia talo ya kosomba sima zongela.';
  }

  @override
  String get backfillOffline =>
      'Ebombami na telefone: ekotindama soki internet ezongi.';

  @override
  String get error => 'Libunga';

  @override
  String backfillFailed(String message) {
    return 'Kobongisa ekokaki kosalema te : $message';
  }

  @override
  String get maintTitle => 'Kobongisa mpe base de données';

  @override
  String get shopTitle => 'Magazini na ngai';

  @override
  String get shopCardSubtitle => 'Salá mpe kamba bisika na yo ya koteka';

  @override
  String get shopNew => 'Magazini ya sika';

  @override
  String get shopEditTitle => 'Bongola magazini';

  @override
  String get shopNameLabel => 'Kombo ya magazini *';

  @override
  String get shopNameHint => 'Ndakisa: Magazini ya Birere';

  @override
  String get shopNameError => 'Koma kombo (ata ba lettre 2)';

  @override
  String get shopAddress => 'Adresi (soki olingi)';

  @override
  String get shopPhone => 'Telefone (soki olingi)';

  @override
  String shopCreated(String nom) {
    return 'Magazini « $nom » esalemi';
  }

  @override
  String get shopUpdated => 'Magazini ebongolami';

  @override
  String shopReactivated(String nom) {
    return '« $nom » efungwami lisusu';
  }

  @override
  String shopDeactivated(String nom) {
    return '« $nom » ekangami';
  }

  @override
  String get shopTransfersTooltip => 'Botindi biloko';

  @override
  String shopLoadError(String message) {
    return 'Ekoki te kofungola magazini : $message';
  }

  @override
  String get shopInfo =>
      'Biloko ya magazini monene = biloko nyonso − biloko ya magazini mosusu. Salela « Tinda biloko » mpo na kotindela magazini biloko, mpe « Talo na magazini moko na moko » mpo na kobongisa talo na zando moko na moko.';

  @override
  String get shopTransferTitle => 'Tinda biloko';

  @override
  String get shopTransferSubtitle =>
      'Tinda biloko uta magazini moko kino na mosusu';

  @override
  String get shopPricesTitle => 'Talo na magazini moko na moko';

  @override
  String get shopPricesSubtitle =>
      'Bongisa talo ya koteka na zando ya magazini moko na moko';

  @override
  String get shopMainBadge => 'Monene';

  @override
  String get shopDisabledBadge => 'Ekangami';

  @override
  String get shopNoAddress => 'Adresi ezali te';

  @override
  String get shopDeactivate => 'Kanga';

  @override
  String get shopReactivate => 'Fungola lisusu';

  @override
  String get teamTitle => 'Bokambi ya ekipe';

  @override
  String get teamOwnerOnly => 'Kaka nkolo ya magazini nde akoki kokota awa.';

  @override
  String get teamNoMembers =>
      'Mosali moko te naino.\nFina « Mosali ya sika » mpo na kosala compte ya kesie to ya mokambi.';

  @override
  String get teamNewMember => 'Mosali ya sika';

  @override
  String get teamAccountCreated => 'Compte esalemi';

  @override
  String teamGiveInfo(String nom) {
    return 'Pesa $nom makambo oyo :';
  }

  @override
  String get teamLogin => 'Kombo ya kokota';

  @override
  String get teamPassword => 'Mot de passe';

  @override
  String get teamNoteNow =>
      'Koma yango sikawa : mot de passe ekomonana lisusu te.';

  @override
  String get teamCopy => 'Kopi';

  @override
  String get teamCopied => 'Ekopiami!';

  @override
  String get teamFullName => 'Kombo mobimba';

  @override
  String get teamNameRequired => 'Kombo esengeli';

  @override
  String get teamLoginLabel => 'Kombo ya kokota (ndakisa: grace)';

  @override
  String teamLoginPreview(String login) {
    return 'Kokota : $login';
  }

  @override
  String get teamLoginMin => 'Ata ba lettre to ba chiffre 3';

  @override
  String get teamPasswordMin => 'Ata ba caractère 6';

  @override
  String get teamRole => 'Mosala';

  @override
  String get teamRoleLabel => 'Mosala:';

  @override
  String get roleOwner => 'Nkolo';

  @override
  String get roleManager => 'Mokambi';

  @override
  String get roleCashier => 'Kesie';

  @override
  String get teamManagerInfo =>
      'Mokambi azali na ndingisa nyonso. Okoki kolongola mosusu sima.';

  @override
  String get teamCashierInfo =>
      'Kesie azali na ndingisa moko te ya sipesiale. Okoki kopesa ye sima.';

  @override
  String get teamCreateAccount => 'Salá compte';

  @override
  String teamYou(String nom) {
    return '$nom (yo)';
  }

  @override
  String get teamOwnerAll => 'Nkolo azali na makoki nyonso.';

  @override
  String get teamRoleChanged => 'Mosala ebongwani';

  @override
  String get teamActive => 'Compte ezali kosala';

  @override
  String get teamCanLogin => 'Akoki kokota';

  @override
  String get teamDisabledInfo => 'Ekangami : akoki kosala lisusu te';

  @override
  String get teamReactivated => 'Compte efungwami lisusu';

  @override
  String get teamDeactivated => 'Compte ekangami';

  @override
  String teamPermissions(int count, int total) {
    return 'Ndingisa ($count/$total)';
  }

  @override
  String get teamManagerDefault => 'Mpo na mokambi : nyonso endimami';

  @override
  String get teamCashierDefault => 'Mpo na kesie : eloko ya sipesiale te';

  @override
  String teamPermGranted(String perm, String nom) {
    return '« $perm » endimami mpo na $nom';
  }

  @override
  String teamPermRemoved(String perm, String nom) {
    return '« $perm » elongolami epai ya $nom';
  }

  @override
  String get permFinances => 'Kotala mbongo';

  @override
  String get permFinancesDesc =>
      'Litomba mpe bobungisi, botangi mbongo, talo ya kosomba mpe matomba.';

  @override
  String get permReturns => 'Bozongisi mpe kolongola';

  @override
  String get permReturnsDesc =>
      'Koma bozongisi to longola eteki oyo biloko ezwami naino te.';

  @override
  String get permStock => 'Kokamba biloko';

  @override
  String get permStockDesc =>
      'Bakisa, bongola, longola biloko, kotisa fichier.';

  @override
  String get permDiscounts => 'Bakitisi mpe kobimisa';

  @override
  String get permDiscountsDesc =>
      'Kobongola talo na kesi mpe kobimisa mbongo na compte ya mosombi.';

  @override
  String get permMaintenance => 'Kobongisa ba données';

  @override
  String get permMaintenanceDesc =>
      'Mibongiseli : kobongisa ba prix ya kosomba, kosangisa biloko mibale.';

  @override
  String get histTitle => 'Lisolo ya biteki';

  @override
  String get histSearch => 'Mosombi, telefone to nimero ya fakture…';

  @override
  String get histToday => 'Lelo';

  @override
  String get hist7Days => 'Mikolo 7';

  @override
  String get hist30Days => 'Mikolo 30';

  @override
  String get histAllTime => 'Nyonso';

  @override
  String histLoadError(String message) {
    return 'Libunga na kofungola : $message';
  }

  @override
  String histSalesOf(String nom) {
    return 'Biteki ya $nom';
  }

  @override
  String get histTotal => 'Nyonso';

  @override
  String get histRemaining => 'Etikali';

  @override
  String get histNoResult => 'Eteki moko te mpo na boluki oyo.';

  @override
  String get histPaid => 'Efutami';

  @override
  String get histPartial => 'Ndambo';

  @override
  String get histDebt => 'Niongo';

  @override
  String get histCancelledSale => 'Elongolami';

  @override
  String get histToDeliver => 'Ya kopesa';

  @override
  String get histDelivered => 'Epesami';

  @override
  String get histPartialCancel => 'Elongolami ndambo';

  @override
  String get histFullReturn => 'Ezongisami nyonso';

  @override
  String get histPartialReturn => 'Ezongisami ndambo';

  @override
  String histInvoice(String numero) {
    return 'Fakture $numero';
  }

  @override
  String get histPrint => 'Kobimisa na papier';

  @override
  String get histShare => 'Kabola (WhatsApp, e-mail…)';

  @override
  String histInvoiceError(String message) {
    return 'Ekoki te kosala fakture : $message';
  }

  @override
  String histDeliveredOn(String date) {
    return 'Epesami mokolo $date';
  }

  @override
  String get histItems => 'Biloko';

  @override
  String histReturnedQty(int count) {
    return '↩ $count ezongisami';
  }

  @override
  String histCancelledQty(int count) {
    return '✕ $count elongolami';
  }

  @override
  String get histReturned => 'Ezongisami';

  @override
  String get histCancelled => 'Elongolami';

  @override
  String get histNetTotal => 'Nyonso ya solo';

  @override
  String get histToPay => 'Etikali kofuta';

  @override
  String get histMethod => 'Lolenge';

  @override
  String get histSoldBy => 'Eteki na';

  @override
  String get histDeliveredBy => 'Epesami na';

  @override
  String get histPdfButton => 'Fakture PDF (kobimisa / WhatsApp)';

  @override
  String get histDeliveryNote => 'Mokanda ya kopesa';

  @override
  String get histReturnGoods => 'Kozongisa biloko';

  @override
  String get histCancelSale => 'Longola eteki (ezwami naino te)';

  @override
  String histArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'biloko $count',
      one: 'eloko 1',
    );
    return '$_temp0';
  }

  @override
  String histBy(String nom) {
    return 'na $nom';
  }

  @override
  String get histWalkIn => 'Mosombi ya nzela';

  @override
  String get ddMotif => 'Ntina';

  @override
  String get ddNoItems => 'Eloko moko te : niongo ebakisami na loboko.';

  @override
  String get ddItemsError => 'Ekoki te kofungola biloko.';

  @override
  String get ddCall => 'Benga';

  @override
  String get ddPdf => 'Fakture PDF';

  @override
  String get ddDetails => 'Makambo';

  @override
  String ddDiscount(String montant) {
    return 'Bakitisi talo : $montant';
  }

  @override
  String ddDate(String date) {
    return 'Mokolo : $date';
  }

  @override
  String get ddPayments => 'Lisolo ya bofuti';

  @override
  String get ddPaidBefore => 'Efutamaki liboso (na eteki to liboso)';

  @override
  String get ddNoPayments => 'Bofuti moko te naino.';

  @override
  String get payMotif => 'Ntina ya niongo (soki olingi)';

  @override
  String get payMotifHint => 'Ndakisa: akofuta mokolo ya mitano sima ya zando';

  @override
  String accDebtsCollected(String montant) {
    return 'Baniongo efutami : $montant';
  }

  @override
  String accDebtsCollectedTitle(int count) {
    return 'Baniongo efutami lelo ($count)';
  }

  @override
  String get repChoiceTitle => 'Bokuse nini otinda?';

  @override
  String get repShort => 'Bokuse ya mokuse';

  @override
  String get repShortHint => 'Ba total ya lelo';

  @override
  String get repDetailed => 'Lapolo ya mobimba';

  @override
  String get repDetailedHint =>
      'Eteki moko moko, biloko, bateki, bibimisi, baniongo, stock';

  @override
  String repSales(int count, String montant) {
    return '🛒 BITEKI ($count) : $montant';
  }

  @override
  String get repProducts => '📦 BILOKO ETEKAMI';

  @override
  String get repBySeller => '👤 NA MOTEKI';

  @override
  String get repByMethod => '💳 NA LOLENGE YA KOFUTA';

  @override
  String repExpenses(String montant) {
    return '💸 BIBIMISI ($montant)';
  }

  @override
  String repDebtsCollected(String montant) {
    return '💰 BANIONGO EFUTAMI ($montant)';
  }

  @override
  String repNewCredits(String montant) {
    return '📝 BANIONGO YA SIKA ($montant)';
  }

  @override
  String get repToReorder => '⚠️ YA KOSOMBA LISUSU';

  @override
  String repCredit(String montant) {
    return 'niongo $montant';
  }

  @override
  String repMore(int count) {
    return '…mpe $count mosusu';
  }

  @override
  String get retCancelTitle => 'Longola eteki';

  @override
  String get retNoCancelRight =>
      'Kaka mokambi mpe nkolo nde bakoki kolongola eteki.';

  @override
  String get retNoReturnRight =>
      'Kaka mokambi mpe nkolo nde bakoki kokoma bozongisi.';

  @override
  String retTooLate(String date, int jours, int limite) {
    return 'Ntango ya kozongisa eleki : eteki ya $date (mikolo $jours eleki, ndelo mikolo $limite).\n\nKaka nkolo nde akoki kondima bozongisi oyo.';
  }

  @override
  String get retNothingToCancel =>
      'Eloko te ya kolongola na eteki oyo.\n\nBiloko nyonso esilaki kopesama na mosombi to kolongolama. Soki azongisi yango, salela « Kozongisa biloko ».';

  @override
  String get retNothingToReturn =>
      'Eloko te ya kozongisa na eteki oyo.\n\nTo nyonso ezongisamaki, to biloko epesami naino te na mosombi (na likambo yango, salela « Longola eteki »).';

  @override
  String get retModeAvoirHint =>
      'Mbongo ebakisami na compte ya mosombi : akoki kosalela yango na kesi.';

  @override
  String get retModeKeepHint =>
      'Magazini ebombi mbongo (avance ezongisami te).';

  @override
  String get retModeCashHint => 'Mbongo ebimi na kesi.';

  @override
  String retSaleOf(String date, String age) {
    return 'Eteki ya $date • $age';
  }

  @override
  String retInvoiceAmount(String montant) {
    return 'Fakture : $montant';
  }

  @override
  String retStillOwes(String montant) {
    return 'Mosombi azali naino na niongo : $montant';
  }

  @override
  String get retCancelInfo =>
      'Biloko mosombi azwaki yango te : ezongi na stock mpe eteki elongolami mpo na biloko oyo.';

  @override
  String retLateAccepted(int jours) {
    return 'Ntango eleki (mikolo $jours) : bozongisi endimami na nkolo lokola likambo ya sipesiale.';
  }

  @override
  String get retItemsToCancel => 'Biloko ya kolongola';

  @override
  String get retItemsReturned => 'Biloko ezongisami';

  @override
  String retPrice(String montant) {
    return 'Talo : $montant';
  }

  @override
  String retNotPicked(int count) {
    return 'ezwami te : $count';
  }

  @override
  String retReturnable(int count) {
    return 'ekoki kozongisama : $count';
  }

  @override
  String retAlreadyReturned(int count) {
    return 'esilaki kozongisama : $count';
  }

  @override
  String get retResell => 'Zongisa na koteka';

  @override
  String get retDamaged => 'Ebebi (bobungisi)';

  @override
  String get retCancelAll => 'Longola nyonso';

  @override
  String get retCancelReason => 'Ntina ya kolongola *';

  @override
  String get retReturnReason => 'Ntina ya kozongisa *';

  @override
  String get retCancelHint => 'Ndakisa : mosombi ayaki te, ntango eleki…';

  @override
  String get retReturnHint => 'Ndakisa : bonene ebongi te, mabe ya kosala…';

  @override
  String retCancelledAmount(String montant) {
    return 'Mbongo elongolami : $montant';
  }

  @override
  String retReturnAmount(String montant) {
    return 'Mbongo ya bozongisi : $montant';
  }

  @override
  String retDeducted(String montant) {
    return 'Elongolami na niongo ya mosombi : $montant';
  }

  @override
  String retAlreadyPaid(String montant) {
    return 'Mosombi asilaki kofuta : $montant';
  }

  @override
  String retToGiveBack(String montant) {
    return 'Ya kozongisela mosombi : $montant';
  }

  @override
  String get retCash => 'Mbongo ya maboko';

  @override
  String get retCredit => 'Avoir';

  @override
  String get retKeep => 'Bomba';

  @override
  String get retPhoneLabel => 'Telefone ya compte ya mosombi *';

  @override
  String get retPhoneError => 'Avoir esengeli telefone ya mosombi';

  @override
  String get retChooseItems => 'Pona biloko';

  @override
  String retValidateCancel(String montant) {
    return 'Ndima bolongoli ($montant)';
  }

  @override
  String retValidateReturn(String montant) {
    return 'Ndima bozongisi ($montant)';
  }

  @override
  String get retNeedReason => 'Koma ntina mpo na kondima.';

  @override
  String get retConfirmCancel => 'Ndima bolongoli';

  @override
  String get retConfirmReturn => 'Ndima bozongisi';

  @override
  String get retDamagedShort => 'ebebi';

  @override
  String retAmount(String montant) {
    return 'Mbongo : $montant';
  }

  @override
  String retDamagedCount(int count) {
    return 'Biloko $count ebebi : ezongi na stock te.';
  }

  @override
  String retCreditTo(String montant, String tel) {
    return 'Avoir ya $montant etiami na compte $tel.';
  }

  @override
  String get retIrreversible => 'Mosala oyo ekoki kozongisama te.';

  @override
  String get retBack => 'Zonga';

  @override
  String get retValidate => 'Ndima';

  @override
  String get retCancelSaved => 'Bolongoli ebombami.';

  @override
  String get retReturnSaved => 'Bozongisi ebombami.';

  @override
  String retGiveCash(String montant) {
    return 'Zongisela mosombi $montant na mbongo ya maboko.';
  }

  @override
  String retCreditAdded(String montant, String solde) {
    return 'Avoir ya $montant ebakisami na compte ya mosombi (solde ya sika : $solde).';
  }

  @override
  String retDepositKept(String montant) {
    return 'Avance ya $montant ebombami na magazini.';
  }

  @override
  String retDebtReduced(String montant) {
    return 'Niongo ya mosombi ekiti na $montant.';
  }

  @override
  String get retOffline => '(ekotindama ntango internet ekozonga)';
}
