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
  String get debtNote => 'Maloba (soki olingi)';

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
}
