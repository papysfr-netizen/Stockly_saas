// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'Stockly Pro';

  @override
  String get settings => 'Mipangilio';

  @override
  String get storeInfo => 'Taarifa za duka';

  @override
  String get storeName => 'Jina la duka';

  @override
  String get address => 'Anwani';

  @override
  String get phone => 'Simu';

  @override
  String get saveInfo => 'Hifadhi taarifa';

  @override
  String get bccSection => 'Kiwango cha BCC na sarafu';

  @override
  String get bccRate => 'Kiwango cha kubadilisha fedha (BCC)';

  @override
  String get activeCurrency => 'Sarafu kuu';

  @override
  String get appLanguage => 'Lugha ya programu';

  @override
  String get reportsExport => 'Kuhamisha data';

  @override
  String get exportExcel => 'Hamisha bidhaa kwenda Excel';

  @override
  String get dbMaintenance => 'Matengenezo';

  @override
  String get mergeDuplicates => 'Unganisha bidhaa zilizorudiwa';

  @override
  String get teamManagement => 'Timu na ruhusa';

  @override
  String get teamManagementSubtitle => 'Ongeza washirika na usimamie haki zao';

  @override
  String get navAccueil => 'Mwanzo';

  @override
  String get navCaisse => 'Malipo';

  @override
  String get navStock => 'Bidhaa';

  @override
  String get navRapport => 'Ripoti';

  @override
  String get navParametres => 'Mipangilio';

  @override
  String accHello(String prenom) {
    return 'Jambo $prenom 👋';
  }

  @override
  String get tauxTitle => 'Bei ya dola leo';

  @override
  String get cancel => 'Ghairi';

  @override
  String get save => 'Hifadhi';

  @override
  String get accToday => 'LEO';

  @override
  String get accOfSales => 'ya mauzo';

  @override
  String get accCashed => 'Imepokelewa';

  @override
  String get accCredit => 'Mkopo';

  @override
  String get accExpenses => 'Matumizi';

  @override
  String accCashInDrawer(String montant) {
    return 'Pesa ya kasha leo : $montant';
  }

  @override
  String accDiscounts(String montant) {
    return 'Punguzo lililotolewa : $montant';
  }

  @override
  String get accSendSummary => 'Tuma muhtasari wa leo';

  @override
  String get accExpense => 'Matumizi';

  @override
  String get accSales => 'Mauzo';

  @override
  String get accClientAccounts => 'Akaunti za wateja';

  @override
  String get accAccounting => 'Uhasibu';

  @override
  String get accHelp => 'Msaada';

  @override
  String accTodaySales(int count) {
    return 'Mauzo ya leo ($count)';
  }

  @override
  String get accNoSales => 'Bado hakuna mauzo leo.\nBonyeza « Malipo » kuanza.';

  @override
  String get accClient => 'Mteja';

  @override
  String accRemaining(String montant) {
    return 'imebaki $montant';
  }

  @override
  String get accMainShop => 'Duka kuu';

  @override
  String get resMorning => 'Habari za asubuhi';

  @override
  String get resAfternoon => 'Habari za mchana';

  @override
  String get resEvening => 'Habari za jioni';

  @override
  String get resNoSales => 'Bado hakuna mauzo leo. Kazi njema! 💪';

  @override
  String get resTodayPrefix => 'Leo, ';

  @override
  String resSalesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mauzo $count',
      one: 'mauzo 1',
    );
    return '$_temp0';
  }

  @override
  String get resFor => ' ya ';

  @override
  String get resGained => '. Umepata faida ya ';

  @override
  String get resLoss => '. Kwa sasa, hasara ya ';

  @override
  String get todoTitle => '📋 Ya kufanya leo';

  @override
  String get todoNothing => '✅ Hakuna cha haraka. Kila kitu kiko sawa!';

  @override
  String todoOwes(String nom, String montant) {
    return '$nom anakudai $montant';
  }

  @override
  String todoOtherClients(int count) {
    return '…na wateja wengine $count';
  }

  @override
  String todoOut(String nom) {
    return '$nom : imeisha';
  }

  @override
  String todoLow(int count, String nom) {
    return 'Zimebaki $count tu za $nom';
  }

  @override
  String todoOtherProducts(int count) {
    return '…na bidhaa nyingine $count za kuagiza';
  }

  @override
  String get actSee => 'Ona';

  @override
  String get actAll => 'Zote';

  @override
  String get caisseNoCompany => 'Kosa: hakuna kampuni iliyochaguliwa.';

  @override
  String caisseOutOfStock(String nom) {
    return '$nom imeisha!';
  }

  @override
  String caisseStockLimit(int count) {
    return 'Kikomo cha bidhaa kimefikiwa ($count)';
  }

  @override
  String caisseAdded(String nom) {
    return '$nom imeongezwa kwenye kikapu!';
  }

  @override
  String caisseNoBarcode(String code) {
    return 'Hakuna bidhaa ya msimbo : $code';
  }

  @override
  String get caisseSearch => 'Tafuta bidhaa…';

  @override
  String get caisseScan => 'Soma msimbo pau';

  @override
  String errorPrefix(String message) {
    return 'Kosa : $message';
  }

  @override
  String get caisseNoProducts =>
      'Hakuna bidhaa bado.\nOngeza bidhaa zako kwenye « Bidhaa ».';

  @override
  String get caisseHint => 'Gusa bidhaa kuiongeza • bonyeza kwa muda: idadi';

  @override
  String get caisseNoMatch => 'Hakuna bidhaa inayolingana na utafutaji wako.';

  @override
  String caisseCheckout(String montant) {
    return 'Lipisha $montant';
  }

  @override
  String get caisseNoName => 'Bila jina';

  @override
  String get caisseOut => 'Imeisha';

  @override
  String get caissePriceNeedsPermission =>
      'Kubadilisha bei kunahitaji ruhusa ya « Punguzo na utoaji ».';

  @override
  String get cartTitle => 'Kikapu';

  @override
  String get cartEmpty => 'Kikapu chako ni tupu';

  @override
  String cartCount(int count) {
    return 'Kikapu (bidhaa $count)';
  }

  @override
  String get cartClear => 'Futa kikapu';

  @override
  String cartNormalPrice(String montant) {
    return 'Bei ya kawaida : $montant';
  }

  @override
  String get cartLoss => 'Kuuza kwa hasara';

  @override
  String addTitle(String nom) {
    return 'Ongeza $nom';
  }

  @override
  String lossConfirm(String nom) {
    return 'Bei ya $nom iko chini ya bei ya kununua.\nUnataka kweli kuuza kwa bei hii?';
  }

  @override
  String get noCorrect => 'Hapana, rekebisha';

  @override
  String get yesSell => 'Ndiyo, uza';

  @override
  String stockAvailable(int count) {
    return 'Bidhaa zilizopo : $count';
  }

  @override
  String unitPrice(String code) {
    return 'Bei ya kipande ($code)';
  }

  @override
  String discountPerPiece(String montant) {
    return 'Punguzo : $montant kwa kipande';
  }

  @override
  String get fixedPrice =>
      'Bei isiyobadilika (ruhusa ya « Punguzo na utoaji » inahitajika)';

  @override
  String lossWithCost(String montant) {
    return 'Unauza kwa hasara! Bei ya kununua : $montant';
  }

  @override
  String get lossBelowCost => 'Hasara: bei hii iko chini ya bei ya kununua.';

  @override
  String get qtyInvalid => 'Idadi si sahihi';

  @override
  String maxAvailable(int count) {
    return 'Kiwango cha juu : $count';
  }

  @override
  String get quantity => 'Idadi';

  @override
  String get subtotal => 'Jumla ndogo :';

  @override
  String qtyOverStock(int count) {
    return 'Idadi inazidi bidhaa zilizopo ($count)';
  }

  @override
  String get outOfStockGeneric => 'Bidhaa imeisha!';

  @override
  String get sellAtLoss => 'Uza kwa hasara';

  @override
  String get add => 'Ongeza';

  @override
  String priceFor(String nom) {
    return 'Bei ya $nom';
  }

  @override
  String get agreedPrice => 'Bei iliyokubaliwa (kwa kipande)';

  @override
  String get normalPriceBtn => 'Bei ya kawaida';

  @override
  String get validate => 'Thibitisha';

  @override
  String get payTitle => 'Maliza mauzo na malipo';

  @override
  String get payClientName => 'Jina la mteja';

  @override
  String get payPhone => 'Simu (mfano: +243...)';

  @override
  String payClientAccount(String montant) {
    return 'Akaunti ya mteja : $montant';
  }

  @override
  String get payUse => 'Tumia';

  @override
  String payPaidByAccount(String montant, String solde) {
    return 'Imelipwa kwa akaunti : $montant • Salio jipya : $solde';
  }

  @override
  String get payMethod => 'Njia';

  @override
  String get payStatus => 'Hali';

  @override
  String get payCash => 'Pesa taslimu';

  @override
  String get payCard => 'Kadi ya benki';

  @override
  String get payTransfer => 'Uhamisho wa benki';

  @override
  String get payPaid => 'Imelipwa';

  @override
  String get payDebt => 'Deni';

  @override
  String get payPartial => 'Malipo ya sehemu';

  @override
  String get payInvoiceTotal => 'Jumla ya ankara :';

  @override
  String get payPaidByClientAccount => 'Imelipwa kwa akaunti ya mteja :';

  @override
  String get payToCollect => 'Kupokea sasa :';

  @override
  String payAllIn(String code) {
    return 'Yote kwa $code';
  }

  @override
  String payRestIn(String code) {
    return 'Kilichobaki kwa $code';
  }

  @override
  String payReceived(String code) {
    return 'Kiasi kilichopokelewa ($code)';
  }

  @override
  String get payRemaining => 'Kinachodaiwa :';

  @override
  String payChange(String code) {
    return 'Chenji ya kurudisha ($code) :';
  }

  @override
  String get payDelivery => 'Utoaji';

  @override
  String get payDeliveredNow => 'Imetolewa sasa';

  @override
  String get payDeliverLater => 'Itatolewa baadaye';

  @override
  String get payPickupBefore => 'Ichukuliwe kabla ya';

  @override
  String payDeadline(String date) {
    return 'Tarehe ya mwisho : $date — mteja ataonekana kwenye « Za kutoa ».';
  }

  @override
  String payDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'siku $count',
      one: 'siku 1',
    );
    return '$_temp0';
  }

  @override
  String get payReceiptActions => 'Chaguo za risiti :';

  @override
  String get payPrintReceipt => 'Chapisha risiti';

  @override
  String get paySendWhatsApp => 'Tuma kwa WhatsApp';

  @override
  String get paySendSms => 'Tuma kwa SMS';

  @override
  String get payValidate => 'Thibitisha na pokea';

  @override
  String payBalanceChanged(String montant) {
    return 'Salio la mteja limebadilika (lipo : $montant \$). Zima kisha washa « Tumia » ili kuhesabu upya.';
  }

  @override
  String get payNotSaved => 'Mauzo HAYAJAHIFADHIWA';

  @override
  String payDenied(String code) {
    return 'Seva imekataa mauzo haya (ruhusa haitoshi).\n\nHakuna kilichohifadhiwa: wala mauzo, wala bidhaa, wala kasha.\nUsitoe bidhaa bado: mjulishe msimamizi.\n\nMsimbo : $code';
  }

  @override
  String payNotSavedOther(String detail) {
    return 'Hakuna kilichohifadhiwa.\n\n$detail';
  }

  @override
  String get payUnderstood => 'Nimeelewa';

  @override
  String get paySaved => 'Mauzo yamehifadhiwa!';

  @override
  String paySavedPickup(String date) {
    return 'Mauzo yamehifadhiwa — ichukuliwe kabla ya $date.';
  }

  @override
  String payNewBalance(String montant) {
    return ' Salio jipya la mteja : $montant.';
  }

  @override
  String payError(String message) {
    return 'Kosa wakati wa kuthibitisha : $message';
  }

  @override
  String get debtNewClient => 'Mkopo mpya wa mteja';

  @override
  String get debtNewSupplier => 'Deni jipya la msambazaji';

  @override
  String get debtClientName => 'Jina la mteja *';

  @override
  String get debtSupplierName => 'Jina la msambazaji *';

  @override
  String get debtInvoiceRef => 'Namba ya ankara / Rejea';

  @override
  String get debtTotal => 'Jumla ya kiasi *';

  @override
  String get debtAlreadyPaid => 'Kiasi kilicholipwa tayari (malipo ya sehemu)';

  @override
  String get debtPickDueDate => 'Chagua tarehe ya kulipa';

  @override
  String debtDueDate(String date) {
    return 'Tarehe ya kulipa : $date';
  }

  @override
  String get debtNote => 'Sababu (si lazima)';

  @override
  String get debtPaidOverTotal => 'Kiasi kilicholipwa kinazidi jumla.';

  @override
  String debtPaymentTitle(String nom) {
    return 'Malipo : $nom';
  }

  @override
  String debtInvoiceNo(String numero) {
    return 'Ankara Na. : $numero';
  }

  @override
  String debtRemainingNow(String montant) {
    return 'Kiasi kinachodaiwa sasa : $montant';
  }

  @override
  String get debtPaymentAmount => 'Kiasi cha malipo';

  @override
  String debtHelperSurplus(String montant) {
    return 'Kinachodaiwa : $montant. Ziada inaweza kwenda kwenye akaunti ya mteja.';
  }

  @override
  String debtMax(String montant) {
    return 'Kiwango cha juu : $montant';
  }

  @override
  String get debtPaymentMode => 'Njia ya malipo';

  @override
  String get debtCashDesk => 'Pesa taslimu (kasha)';

  @override
  String get debtCheck => 'Hundi';

  @override
  String get debtEnterAmount => 'Andika kiasi.';

  @override
  String debtTooHighNoPhone(String montant) {
    return 'Kiasi kikubwa mno. Kiwango cha juu : $montant (mteja hana namba: hakuna akaunti)';
  }

  @override
  String debtTooHigh(String montant) {
    return 'Kiasi kikubwa mno. Kiwango cha juu : $montant';
  }

  @override
  String get debtGivesMore => 'Mteja anatoa zaidi';

  @override
  String debtSurplusQuestion(
      String dette, String donne, String surplus, String nom) {
    return 'Deni : $dette\nAmetoa : $donne\n\nWeka $surplus kwenye akaunti ya $nom?\nAtatumia kwa manunuzi yajayo.';
  }

  @override
  String get debtYesAccount => 'Ndiyo, kwenye akaunti yake';

  @override
  String debtSettled(String montant, String nom) {
    return 'Deni limelipwa. $montant imewekwa kwenye akaunti ya $nom.';
  }

  @override
  String get debtPendingNet => ' (itatumwa mtandao ukirudi)';

  @override
  String debtPaymentSaved(String montant) {
    return 'Malipo ya $montant yamehifadhiwa.';
  }

  @override
  String get debtValidatePayment => 'Thibitisha malipo';

  @override
  String get debtScreenTitle => 'Mikopo na Madeni';

  @override
  String get debtExport => 'Hamisha';

  @override
  String get debtExportExcel => 'Hamisha kwa Excel';

  @override
  String get debtPrintPdf => 'Chapisha / PDF';

  @override
  String get debtTabClients => 'Wateja';

  @override
  String get debtTabSuppliers => 'Wasambazaji';

  @override
  String debtLoadError(String message) {
    return 'Kosa la kupakia : $message';
  }

  @override
  String get debtAdd => 'Ongeza deni';

  @override
  String get ageToday => 'Leo';

  @override
  String get ageYesterday => 'Jana';

  @override
  String ageDays(int count) {
    return 'Siku $count zilizopita';
  }

  @override
  String ageMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Miezi $count iliyopita',
      one: 'Mwezi 1 uliopita',
    );
    return '$_temp0';
  }

  @override
  String get whatsAppError =>
      'Haiwezekani kufungua WhatsApp kwenye kifaa hiki.';

  @override
  String get debtEmptyClients => 'Hakuna mkopo wa mteja';

  @override
  String get debtEmptySuppliers => 'Hakuna deni la msambazaji';

  @override
  String get debtEmptyClientsHint =>
      'Mauzo ya mkopo au ya sehemu yataonekana hapa yenyewe.';

  @override
  String get debtEmptySuppliersHint =>
      'Ongeza hapa unachodaiwa na wasambazaji kwa kitufe « Ongeza deni ».';

  @override
  String get noResults => 'Hakuna matokeo';

  @override
  String get noResultsHint => 'Jaribu kichujio au utafutaji mwingine.';

  @override
  String get debtToCollect => 'KUDAI (WATEJA)';

  @override
  String get debtToPay => 'KULIPA (WASAMBAZAJI)';

  @override
  String debtOpenFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faili wazi',
      one: 'faili wazi',
    );
    return '$_temp0';
  }

  @override
  String debtClientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wateja',
      one: 'mteja',
    );
    return '$_temp0';
  }

  @override
  String debtSuppliersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wasambazaji',
      one: 'msambazaji',
    );
    return '$_temp0';
  }

  @override
  String debtLateCount(int count) {
    return 'zimechelewa ($count)';
  }

  @override
  String get debtSearchClients => 'Tafuta mteja, ankara, simu…';

  @override
  String get debtSearchSuppliers => 'Tafuta msambazaji, ankara…';

  @override
  String get filterOngoing => 'Zinazoendelea';

  @override
  String get filterRecent => 'Za karibuni (< siku 30)';

  @override
  String get filterLate => 'Zimechelewa';

  @override
  String get filterPartial => 'Za sehemu';

  @override
  String get filterSettled => 'Zimelipwa';

  @override
  String get statusSettled => 'Imelipwa';

  @override
  String get statusPartial => 'Sehemu';

  @override
  String get statusUnpaid => 'Haijalipwa';

  @override
  String invoiceShort(String numero) {
    return 'Ankara $numero';
  }

  @override
  String paidOf(String paye, String total) {
    return 'Imelipwa $paye kati ya $total';
  }

  @override
  String lastPayment(String date) {
    return 'Malipo ya mwisho $date';
  }

  @override
  String get remind => 'Kumbusha';

  @override
  String get message => 'Ujumbe';

  @override
  String get collect => 'Pokea';

  @override
  String get pay => 'Lipa';

  @override
  String printFailed(String message) {
    return 'Imeshindwa kuchapisha : $message';
  }

  @override
  String get printerTitle => 'Printa';

  @override
  String get printerPhoneOnly => 'Mipangilio ya simu hii tu';

  @override
  String get printerPaperWidth => 'Upana wa karatasi';

  @override
  String get printer58 => '58 mm (ndogo)';

  @override
  String get printer80 => '80 mm (kubwa)';

  @override
  String get printerAfterSale => 'Baada ya mauzo, risiti…';

  @override
  String get printerPrints => 'Inachapishwa';

  @override
  String get printerPrintsHint =>
      'Dirisha la kuchapisha la Android (printa iliyowekwa kwenye simu)';

  @override
  String get printerPdf => 'Inatumwa kama PDF';

  @override
  String get printerPdfHint =>
      'WhatsApp, Bluetooth, barua pepe… (wakati hakuna printa)';

  @override
  String get printerTest => 'Chapisha risiti ya majaribio';

  @override
  String get crashTest => 'Jaribu ripoti za makosa';

  @override
  String get crashDebugOnly =>
      'Ripoti zinatumwa tu kutoka kwa APK (si kwa waya).';

  @override
  String get crashSent =>
      'Ripoti ya majaribio imetumwa. Itaonekana kwenye Firebase baada ya dakika chache.';

  @override
  String get guideTitle => 'Mwongozo wa matumizi';

  @override
  String get guideSubtitle => 'Jinsi ya kuuza, kupokea deni, kuchapisha…';

  @override
  String get guideSearch => 'Tafuta: deni, bei ya dola, chapisha…';

  @override
  String guideNotFound(String mot) {
    return 'Hakuna kilichopatikana kwa « $mot ».';
  }

  @override
  String get guideOwnerOnly => 'Mmiliki / meneja';

  @override
  String stockDeleted(String nom) {
    return '« $nom » imefutwa.';
  }

  @override
  String stockDeletedOffline(String nom) {
    return '« $nom » imefutwa kwenye simu. Itatumwa mtandao ukirudi.';
  }

  @override
  String stockDeleteError(String message) {
    return 'Kosa wakati wa kufuta : $message';
  }

  @override
  String get stockAnalyzing => 'Inachambua...';

  @override
  String stockImported(int count) {
    return 'Bidhaa $count zimeingizwa au kusasishwa!';
  }

  @override
  String stockImportError(String message) {
    return 'Kosa la kuingiza : $message';
  }

  @override
  String stockConnected(String nom) {
    return 'Umeingia: $nom';
  }

  @override
  String get stockImportTooltip => 'Ingiza Excel / CSV / Packing List';

  @override
  String get myAccount => 'Akaunti yangu';

  @override
  String get changePassword => 'Badilisha nenosiri langu';

  @override
  String get logout => 'Toka';

  @override
  String get stockNoProduct => 'Hakuna bidhaa iliyopatikana.';

  @override
  String get stockProducts => 'Bidhaa';

  @override
  String get stockValue => 'Thamani ya bidhaa';

  @override
  String get stockCannotDelete => 'Haiwezi kufutwa';

  @override
  String stockCannotDeleteMsg(String nom, int count) {
    return '« $nom » bado ina vipande $count kwenye stoo.\n\nKwanza weka stoo kuwa 0 (hesabu au hasara), ili hasara ionekane kwenye hesabu.';
  }

  @override
  String get stockDeleteTitle => 'Futa bidhaa';

  @override
  String stockDeleteConfirm(String nom) {
    return 'Unataka kweli kufuta « $nom »?\n\nHatua hii haiwezi kurudishwa.';
  }

  @override
  String get delete => 'Futa';

  @override
  String get stockNewProduct => 'Bidhaa mpya';

  @override
  String stockQty(int count) {
    return 'Stoo: $count';
  }

  @override
  String get stockAlert => 'Stoo inaisha';

  @override
  String get edit => 'Hariri';

  @override
  String get prodDefaultName => 'Bidhaa bila jina';

  @override
  String get prodBarcodeUsed => 'Msimbo pau tayari unatumika';

  @override
  String prodBarcodeUsedMsg(String nom, String stock, String prix) {
    return 'Msimbo huu tayari ni wa:\n\n« $nom »\nStoo : $stock  •  Bei : $prix \$\n\nUnataka kufungua bidhaa hii kuihariri (kwa mfano kuongeza stoo)?';
  }

  @override
  String get prodOpenThis => 'Fungua bidhaa hii';

  @override
  String get prodNoCompany => 'Kampuni haipatikani. Toka kisha ingia tena.';

  @override
  String get prodSavedOffline =>
      'Imehifadhiwa kwenye simu. Itatumwa mtandao ukirudi.';

  @override
  String get prodUpdated => 'Bidhaa imesasishwa!';

  @override
  String get prodAdded => 'Bidhaa imeongezwa!';

  @override
  String prodSaveError(String message) {
    return 'Kosa wakati wa kuhifadhi : $message';
  }

  @override
  String get prodEditTitle => 'Hariri bidhaa';

  @override
  String get prodImportPacking => 'Ingiza Packing List (Excel / CSV)';

  @override
  String get prodOrManual => 'AU ANDIKA MWENYEWE';

  @override
  String get prodImageUrl => 'Kiungo cha picha';

  @override
  String get prodImageUrlOpt => 'Kiungo cha picha (si lazima)';

  @override
  String get prodName => 'Jina la bidhaa *';

  @override
  String get prodNameHint => 'mfano: Fulana ya pamba';

  @override
  String get prodNameRequired => 'Jina linahitajika';

  @override
  String get prodBarcode => 'Msimbo pau';

  @override
  String get prodBarcodeHint => 'Soma / Andika';

  @override
  String get prodCategory => 'Aina';

  @override
  String get prodBuyPrice => 'Bei ya kununua (\$)';

  @override
  String get prodInvalidPrice => 'Bei si sahihi';

  @override
  String get prodSellPrice => 'Bei ya kuuza (\$)*';

  @override
  String get prodPriceRequired => 'Bei inahitajika';

  @override
  String get prodStock => 'Stoo *';

  @override
  String get prodInitialStock => 'Stoo ya mwanzo *';

  @override
  String get prodStockRequired => 'Stoo inahitajika';

  @override
  String get prodWholeNumber => 'Namba kamili';

  @override
  String get prodAlertLevel => 'Kiwango cha tahadhari';

  @override
  String get prodSaving => 'Inahifadhi...';

  @override
  String get prodUpdate => 'Sasisha';

  @override
  String get prodSave => 'Hifadhi bidhaa';

  @override
  String get msgLanguage => 'Lugha ya ujumbe';

  @override
  String get sumDays =>
      'Jumatatu,Jumanne,Jumatano,Alhamisi,Ijumaa,Jumamosi,Jumapili';

  @override
  String get sumAllShops => 'Maduka yote';

  @override
  String sumSales(int count, String montant) {
    return 'Mauzo : $count ya $montant';
  }

  @override
  String sumCollected(String montant) {
    return 'Imepokelewa : $montant';
  }

  @override
  String sumCredit(String montant) {
    return 'Mkopo : $montant';
  }

  @override
  String sumExpenses(String montant) {
    return 'Matumizi : $montant';
  }

  @override
  String sumCash(String montant) {
    return '💵 Pesa ya kasha : $montant';
  }

  @override
  String sumProfit(String montant) {
    return '📈 Faida : $montant';
  }

  @override
  String sumRate(String taux) {
    return 'Bei ya dola : 1 \$ = $taux FC';
  }

  @override
  String sumSentBy(String nom) {
    return 'Imetumwa na $nom — Stockly Pro';
  }

  @override
  String get logoutQuestion => 'Ungependa kutoka?';

  @override
  String get logoutWarning =>
      'Utahitaji kuingia tena kwa barua pepe na nenosiri lako.';

  @override
  String get exportDone => 'Uhamishaji wa Excel umekamilika!';

  @override
  String exportError(String message) {
    return 'Kosa la kuhamisha : $message';
  }

  @override
  String get attention => 'Tahadhari';

  @override
  String get mergeConfirm =>
      'Unataka kweli kuunganisha bidhaa zilizorudiwa? Hatua hii haiwezi kurudishwa.';

  @override
  String get mergeDone => 'Bidhaa zilizorudiwa zimesafishwa!';

  @override
  String get confirmBtn => 'Thibitisha';

  @override
  String get backfillTitle => 'Rekebisha gharama ya mauzo ya zamani';

  @override
  String get backfillExplain =>
      'Mauzo ya zamani yasiyo na maandishi ya « Kutoka kwa stoo » yatapewa moja, kwa tarehe yake ya asili.\n\nGharama inahesabiwa kwa bei ya kununua ya SASA ya kila bidhaa.\n\nUnaweza kurudia bila hatari: mauzo hayahesabiwi mara mbili.';

  @override
  String get launch => 'Anza';

  @override
  String get backfillRunning => 'Inarekebisha…';

  @override
  String get backfillNothing => 'Hakuna cha kurekebisha';

  @override
  String get backfillDone => 'Urekebishaji umekamilika';

  @override
  String backfillAllDone(String count) {
    return 'Mauzo yote ($count) tayari yana maandishi ya « Kutoka kwa stoo ».';
  }

  @override
  String backfillResult(String nb, String total, String cout) {
    return 'Mauzo $nb yamerekebishwa kati ya $total.\n\nGharama ya bidhaa iliyoongezwa : $cout \$';
  }

  @override
  String backfillNoPrice(String count) {
    return '⚠️ Bidhaa $count hazina bei ya kununua: gharama yake inahesabiwa 0. Jaza bei ya kununua kisha rudia.';
  }

  @override
  String get backfillOffline =>
      'Imehifadhiwa kwenye simu: itatumwa mtandao ukirudi.';

  @override
  String get error => 'Kosa';

  @override
  String backfillFailed(String message) {
    return 'Urekebishaji haukuweza kufanyika : $message';
  }

  @override
  String get maintTitle => 'Matengenezo na hifadhidata';

  @override
  String get shopTitle => 'Maduka yangu';

  @override
  String get shopCardSubtitle => 'Unda na usimamie maduka yako';

  @override
  String get shopNew => 'Duka jipya';

  @override
  String get shopEditTitle => 'Hariri duka';

  @override
  String get shopNameLabel => 'Jina la duka *';

  @override
  String get shopNameHint => 'Mfano: Duka la Birere';

  @override
  String get shopNameError => 'Andika jina (herufi 2 angalau)';

  @override
  String get shopAddress => 'Anwani (si lazima)';

  @override
  String get shopPhone => 'Simu (si lazima)';

  @override
  String shopCreated(String nom) {
    return 'Duka « $nom » limeundwa';
  }

  @override
  String get shopUpdated => 'Duka limehaririwa';

  @override
  String shopReactivated(String nom) {
    return '« $nom » limewashwa tena';
  }

  @override
  String shopDeactivated(String nom) {
    return '« $nom » limezimwa';
  }

  @override
  String get shopTransfersTooltip => 'Uhamisho wa bidhaa';

  @override
  String shopLoadError(String message) {
    return 'Imeshindwa kupakia maduka : $message';
  }

  @override
  String get shopInfo =>
      'Bidhaa za duka kuu = bidhaa zote − bidhaa za maduka mengine. Tumia « Hamisha bidhaa » kupeleka bidhaa dukani, na « Bei kwa kila duka » kurekebisha bei kwa kila soko.';

  @override
  String get shopTransferTitle => 'Hamisha bidhaa';

  @override
  String get shopTransferSubtitle =>
      'Peleka bidhaa kutoka duka moja hadi jingine';

  @override
  String get shopPricesTitle => 'Bei kwa kila duka';

  @override
  String get shopPricesSubtitle =>
      'Rekebisha bei za kuuza kulingana na soko la kila duka';

  @override
  String get shopMainBadge => 'Kuu';

  @override
  String get shopDisabledBadge => 'Imezimwa';

  @override
  String get shopNoAddress => 'Hakuna anwani';

  @override
  String get shopDeactivate => 'Zima';

  @override
  String get shopReactivate => 'Washa tena';

  @override
  String get teamTitle => 'Usimamizi wa timu';

  @override
  String get teamOwnerOnly => 'Ruhusa ni ya mmiliki wa duka pekee.';

  @override
  String get teamNoMembers =>
      'Bado hakuna mfanyakazi.\nBonyeza « Mwanachama mpya » kuunda akaunti ya keshia au meneja.';

  @override
  String get teamNewMember => 'Mwanachama mpya';

  @override
  String get teamAccountCreated => 'Akaunti imeundwa';

  @override
  String teamGiveInfo(String nom) {
    return 'Mpe $nom taarifa hizi :';
  }

  @override
  String get teamLogin => 'Jina la kuingia';

  @override
  String get teamPassword => 'Nenosiri';

  @override
  String get teamNoteNow => 'Ziandike sasa: nenosiri halitaonyeshwa tena.';

  @override
  String get teamCopy => 'Nakili';

  @override
  String get teamCopied => 'Imenakiliwa!';

  @override
  String get teamFullName => 'Jina kamili';

  @override
  String get teamNameRequired => 'Jina linahitajika';

  @override
  String get teamLoginLabel => 'Jina la kuingia (mfano: grace)';

  @override
  String teamLoginPreview(String login) {
    return 'Kuingia : $login';
  }

  @override
  String get teamLoginMin => 'Herufi au namba 3 angalau';

  @override
  String get teamPasswordMin => 'Herufi 6 angalau';

  @override
  String get teamRole => 'Kazi';

  @override
  String get teamRoleLabel => 'Kazi:';

  @override
  String get roleOwner => 'Mmiliki';

  @override
  String get roleManager => 'Meneja';

  @override
  String get roleCashier => 'Keshia';

  @override
  String get teamManagerInfo =>
      'Meneja ana ruhusa zote kwa kawaida. Unaweza kuondoa baadhi baadaye.';

  @override
  String get teamCashierInfo =>
      'Keshia hana ruhusa maalum kwa kawaida. Unaweza kumpa baadaye.';

  @override
  String get teamCreateAccount => 'Unda akaunti';

  @override
  String teamYou(String nom) {
    return '$nom (wewe)';
  }

  @override
  String get teamOwnerAll => 'Mmiliki ana haki zote.';

  @override
  String get teamRoleChanged => 'Kazi imebadilishwa';

  @override
  String get teamActive => 'Akaunti hai';

  @override
  String get teamCanLogin => 'Anaweza kuingia';

  @override
  String get teamDisabledInfo => 'Imezimwa: hawezi kufanya kazi tena';

  @override
  String get teamReactivated => 'Akaunti imewashwa tena';

  @override
  String get teamDeactivated => 'Akaunti imezimwa';

  @override
  String teamPermissions(int count, int total) {
    return 'Ruhusa ($count/$total)';
  }

  @override
  String get teamManagerDefault =>
      'Kwa kawaida kwa meneja: kila kitu kinaruhusiwa';

  @override
  String get teamCashierDefault => 'Kwa kawaida kwa keshia: hakuna maalum';

  @override
  String teamPermGranted(String perm, String nom) {
    return '« $perm » imeruhusiwa kwa $nom';
  }

  @override
  String teamPermRemoved(String perm, String nom) {
    return '« $perm » imeondolewa kwa $nom';
  }

  @override
  String get permFinances => 'Kuona fedha';

  @override
  String get permFinancesDesc =>
      'Faida na hasara, uhasibu, bei za kununua na faida.';

  @override
  String get permReturns => 'Marejesho na kufuta';

  @override
  String get permReturnsDesc =>
      'Andika marejesho au futa mauzo ambayo bidhaa hazijachukuliwa.';

  @override
  String get permStock => 'Kusimamia bidhaa';

  @override
  String get permStockDesc => 'Ongeza, hariri, futa bidhaa, leta faili.';

  @override
  String get permDiscounts => 'Punguzo na utoaji';

  @override
  String get permDiscountsDesc =>
      'Kubadilisha bei kwenye malipo na kutoa pesa kwenye akaunti ya mteja.';

  @override
  String get permMaintenance => 'Matengenezo ya data';

  @override
  String get permMaintenanceDesc =>
      'Mipangilio: rekebisha gharama, unganisha nakala.';

  @override
  String get histTitle => 'Historia ya mauzo';

  @override
  String get histSearch => 'Mteja, simu au namba ya ankara…';

  @override
  String get histToday => 'Leo';

  @override
  String get hist7Days => 'Siku 7';

  @override
  String get hist30Days => 'Siku 30';

  @override
  String get histAllTime => 'Zote';

  @override
  String histLoadError(String message) {
    return 'Kosa la kupakia : $message';
  }

  @override
  String histSalesOf(String nom) {
    return 'Mauzo ya $nom';
  }

  @override
  String get histTotal => 'Jumla';

  @override
  String get histRemaining => 'Baki';

  @override
  String get histNoResult => 'Hakuna mauzo kwa utafutaji huu.';

  @override
  String get histPaid => 'Imelipwa';

  @override
  String get histPartial => 'Sehemu';

  @override
  String get histDebt => 'Deni';

  @override
  String get histCancelledSale => 'Imefutwa';

  @override
  String get histToDeliver => 'Ya kupeleka';

  @override
  String get histDelivered => 'Imepelekwa';

  @override
  String get histPartialCancel => 'Imefutwa sehemu';

  @override
  String get histFullReturn => 'Imerudishwa yote';

  @override
  String get histPartialReturn => 'Imerudishwa sehemu';

  @override
  String histInvoice(String numero) {
    return 'Ankara $numero';
  }

  @override
  String get histPrint => 'Chapisha';

  @override
  String get histShare => 'Shiriki (WhatsApp, barua pepe…)';

  @override
  String histInvoiceError(String message) {
    return 'Imeshindwa kuunda ankara : $message';
  }

  @override
  String histDeliveredOn(String date) {
    return 'Imepelekwa tarehe $date';
  }

  @override
  String get histItems => 'Bidhaa';

  @override
  String histReturnedQty(int count) {
    return '↩ $count imerudishwa';
  }

  @override
  String histCancelledQty(int count) {
    return '✕ $count imefutwa';
  }

  @override
  String get histReturned => 'Imerudishwa';

  @override
  String get histCancelled => 'Imefutwa';

  @override
  String get histNetTotal => 'Jumla halisi';

  @override
  String get histToPay => 'Baki ya kulipa';

  @override
  String get histMethod => 'Njia';

  @override
  String get histSoldBy => 'Imeuzwa na';

  @override
  String get histDeliveredBy => 'Imepelekwa na';

  @override
  String get histPdfButton => 'Ankara PDF (chapisha / WhatsApp)';

  @override
  String get histDeliveryNote => 'Hati ya kupeleka';

  @override
  String get histReturnGoods => 'Rudisha bidhaa';

  @override
  String get histCancelSale => 'Futa mauzo (hayajachukuliwa)';

  @override
  String histArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bidhaa $count',
      one: 'bidhaa 1',
    );
    return '$_temp0';
  }

  @override
  String histBy(String nom) {
    return 'na $nom';
  }

  @override
  String get histWalkIn => 'Mteja wa kawaida';

  @override
  String get ddMotif => 'Sababu';

  @override
  String get ddNoItems => 'Hakuna bidhaa: deni liliongezwa kwa mkono.';

  @override
  String get ddItemsError => 'Imeshindwa kupakia bidhaa.';

  @override
  String get ddCall => 'Piga simu';

  @override
  String get ddPdf => 'Ankara PDF';

  @override
  String get ddDetails => 'Maelezo';

  @override
  String ddDiscount(String montant) {
    return 'Punguzo : $montant';
  }

  @override
  String ddDate(String date) {
    return 'Tarehe : $date';
  }

  @override
  String get ddPayments => 'Historia ya malipo';

  @override
  String get ddPaidBefore => 'Ililipwa mapema (wakati wa mauzo au kabla)';

  @override
  String get ddNoPayments => 'Bado hakuna malipo.';

  @override
  String get payMotif => 'Sababu ya mkopo (si lazima)';

  @override
  String get payMotifHint => 'Mfano: atalipa Ijumaa baada ya soko';

  @override
  String accDebtsCollected(String montant) {
    return 'Madeni yaliyolipwa : $montant';
  }

  @override
  String accDebtsCollectedTitle(int count) {
    return 'Madeni yaliyolipwa leo ($count)';
  }

  @override
  String get repChoiceTitle => 'Tuma muhtasari upi?';

  @override
  String get repShort => 'Muhtasari mfupi';

  @override
  String get repShortHint => 'Jumla za leo';

  @override
  String get repDetailed => 'Ripoti kamili';

  @override
  String get repDetailedHint =>
      'Kila mauzo, bidhaa, wauzaji, matumizi, madeni, akiba';

  @override
  String repSales(int count, String montant) {
    return '🛒 MAUZO ($count) : $montant';
  }

  @override
  String get repProducts => '📦 BIDHAA ZILIZOUZWA';

  @override
  String get repBySeller => '👤 KWA MUUZAJI';

  @override
  String get repByMethod => '💳 KWA NJIA YA MALIPO';

  @override
  String repExpenses(String montant) {
    return '💸 MATUMIZI ($montant)';
  }

  @override
  String repDebtsCollected(String montant) {
    return '💰 MADENI YALIYOLIPWA ($montant)';
  }

  @override
  String repNewCredits(String montant) {
    return '📝 MIKOPO MIPYA ($montant)';
  }

  @override
  String get repToReorder => '⚠️ YA KUAGIZA';

  @override
  String repCredit(String montant) {
    return 'mkopo $montant';
  }

  @override
  String repMore(int count) {
    return '…na $count zaidi';
  }

  @override
  String get retCancelTitle => 'Futa mauzo';

  @override
  String get retNoCancelRight =>
      'Meneja na mmiliki pekee ndio wanaweza kufuta mauzo.';

  @override
  String get retNoReturnRight =>
      'Meneja na mmiliki pekee ndio wanaweza kuandika marejesho.';

  @override
  String retTooLate(String date, int jours, int limite) {
    return 'Muda wa kurudisha umepita: mauzo ya $date (siku $jours zilizopita, kikomo siku $limite).\n\nMmiliki pekee ndiye anaweza kukubali marejesho haya.';
  }

  @override
  String get retNothingToCancel =>
      'Hakuna cha kufuta kwenye mauzo haya.\n\nBidhaa zote zimeshakabidhiwa kwa mteja au kufutwa. Akizirudisha, tumia « Rudisha bidhaa ».';

  @override
  String get retNothingToReturn =>
      'Hakuna cha kurudisha kwenye mauzo haya.\n\nAma kila kitu kimeshirudishwa, ama bidhaa bado hazijakabidhiwa kwa mteja (hapo, tumia « Futa mauzo »).';

  @override
  String get retModeAvoirHint =>
      'Kiasi kinaongezwa kwenye akaunti ya mteja: ataweza kukitumia kwenye malipo.';

  @override
  String get retModeKeepHint =>
      'Duka linabaki na pesa (malipo ya awali hayarudishwi).';

  @override
  String get retModeCashHint => 'Pesa zinatoka kwenye kasha.';

  @override
  String retSaleOf(String date, String age) {
    return 'Mauzo ya $date • $age';
  }

  @override
  String retInvoiceAmount(String montant) {
    return 'Ankara : $montant';
  }

  @override
  String retStillOwes(String montant) {
    return 'Mteja bado anadaiwa : $montant';
  }

  @override
  String get retCancelInfo =>
      'Bidhaa hazikuchukuliwa kamwe na mteja: zinarudi kwenye akiba na mauzo yanafutwa kwa bidhaa hizi.';

  @override
  String retLateAccepted(int jours) {
    return 'Muda umepita (siku $jours): marejesho yamekubaliwa kipekee na mmiliki.';
  }

  @override
  String get retItemsToCancel => 'Bidhaa za kufuta';

  @override
  String get retItemsReturned => 'Bidhaa zilizorudishwa';

  @override
  String retPrice(String montant) {
    return 'Bei : $montant';
  }

  @override
  String retNotPicked(int count) {
    return 'haijachukuliwa : $count';
  }

  @override
  String retReturnable(int count) {
    return 'inarudishika : $count';
  }

  @override
  String retAlreadyReturned(int count) {
    return 'imeshirudishwa : $count';
  }

  @override
  String get retResell => 'Rudisha sokoni';

  @override
  String get retDamaged => 'Imeharibika (hasara)';

  @override
  String get retCancelAll => 'Futa zote';

  @override
  String get retCancelReason => 'Sababu ya kufuta *';

  @override
  String get retReturnReason => 'Sababu ya kurudisha *';

  @override
  String get retCancelHint => 'Mfano: mteja hakuja, muda umepita…';

  @override
  String get retReturnHint => 'Mfano: saizi isiyofaa, kasoro ya utengenezaji…';

  @override
  String retCancelledAmount(String montant) {
    return 'Kiasi kilichofutwa : $montant';
  }

  @override
  String retReturnAmount(String montant) {
    return 'Kiasi cha marejesho : $montant';
  }

  @override
  String retDeducted(String montant) {
    return 'Kimetolewa kwenye deni la mteja : $montant';
  }

  @override
  String retAlreadyPaid(String montant) {
    return 'Tayari kimelipwa na mteja : $montant';
  }

  @override
  String retToGiveBack(String montant) {
    return 'Kumrudishia mteja : $montant';
  }

  @override
  String get retCash => 'Pesa taslimu';

  @override
  String get retCredit => 'Salio';

  @override
  String get retKeep => 'Baki nazo';

  @override
  String get retPhoneLabel => 'Simu ya akaunti ya mteja *';

  @override
  String get retPhoneError => 'Salio linahitaji simu ya mteja';

  @override
  String get retChooseItems => 'Chagua bidhaa';

  @override
  String retValidateCancel(String montant) {
    return 'Thibitisha kufuta ($montant)';
  }

  @override
  String retValidateReturn(String montant) {
    return 'Thibitisha marejesho ($montant)';
  }

  @override
  String get retNeedReason => 'Andika sababu ili kuthibitisha.';

  @override
  String get retConfirmCancel => 'Thibitisha kufuta';

  @override
  String get retConfirmReturn => 'Thibitisha marejesho';

  @override
  String get retDamagedShort => 'imeharibika';

  @override
  String retAmount(String montant) {
    return 'Kiasi : $montant';
  }

  @override
  String retDamagedCount(int count) {
    return 'Vipande $count vilivyoharibika: havirudi kwenye akiba.';
  }

  @override
  String retCreditTo(String montant, String tel) {
    return 'Salio la $montant limewekwa kwenye akaunti $tel.';
  }

  @override
  String get retIrreversible => 'Operesheni hii haiwezi kutenduliwa.';

  @override
  String get retBack => 'Rudi';

  @override
  String get retValidate => 'Thibitisha';

  @override
  String get retCancelSaved => 'Kufuta kumehifadhiwa.';

  @override
  String get retReturnSaved => 'Marejesho yamehifadhiwa.';

  @override
  String retGiveCash(String montant) {
    return 'Mrudishie mteja $montant pesa taslimu.';
  }

  @override
  String retCreditAdded(String montant, String solde) {
    return 'Salio la $montant limeongezwa kwenye akaunti ya mteja (salio jipya : $solde).';
  }

  @override
  String retDepositKept(String montant) {
    return 'Malipo ya awali ya $montant yamebaki dukani.';
  }

  @override
  String retDebtReduced(String montant) {
    return 'Deni la mteja limepunguzwa kwa $montant.';
  }

  @override
  String get retOffline => '(itatumwa intaneti ikirudi)';

  @override
  String get caisseNoShopProducts =>
      'Hakuna bidhaa zilizopo katika duka hili.\nOngeza bidhaa (kununua au kuhamisha kutoka duka kuu).';

  @override
  String stockShowOut(int count) {
    return 'Ona zilizoisha ($count)';
  }

  @override
  String get stockShowInStock => 'Rudi kwa bidhaa zilizopo';

  @override
  String get livTitle => 'Ya kukabidhi';

  @override
  String livButtonLate(int count) {
    return 'Ya kukabidhi ($count zimechelewa)';
  }

  @override
  String get livNoneTitle => 'Hakuna bidhaa zinazosubiri kukabidhiwa';

  @override
  String get livNoneSub => 'Wateja wote wamepokea bidhaa zao.';

  @override
  String livWaitingLate(int count, int late) {
    return 'Wateja $count wanasubiri — $late wamechelewa';
  }

  @override
  String livWaiting(int count) {
    return 'Wateja $count wanasubiri bidhaa zao';
  }

  @override
  String get livNoWhatsapp => 'Imeshindikana kufungua WhatsApp.';

  @override
  String get livHandOverTitle => 'Kabidhi bidhaa';

  @override
  String livClient(String nom) {
    return 'Mteja : $nom';
  }

  @override
  String get livWhatNow => 'Onyesha mteja anachukua nini sasa :';

  @override
  String get livAllGiven => 'Kila kitu kimeshakabidhiwa.';

  @override
  String livRemainDone(int reste, int deja) {
    return 'Imebaki $reste (imeshakabidhiwa : $deja)';
  }

  @override
  String livToHand(int count) {
    return 'Ya kukabidhi : $count';
  }

  @override
  String get livChooseOne => 'Chagua angalau kipande kimoja cha kukabidhi.';

  @override
  String livPartialAfter(int count) {
    return 'Utoaji wa sehemu : vipande $count vitabaki kuchukuliwa.';
  }

  @override
  String get livComplete => 'Ukabidhi kamili : kila kitu kimekabidhiwa.';

  @override
  String livWarnUnpaid(String montant) {
    return 'Tahadhari : imebaki $montant kulipa.';
  }

  @override
  String get livValidateExit => 'Thibitisha utoaji';

  @override
  String get livAllDelivered => 'Ndiyo, vyote vimekabidhiwa';

  @override
  String get livSavedOffline =>
      'Utoaji umeandikwa kwenye simu. Utatumwa intaneti ikirudi.';

  @override
  String livCompleteSaved(String client) {
    return 'Ukabidhi kamili umeandikwa kwa $client.';
  }

  @override
  String livPartialSaved(int count) {
    return 'Utoaji wa sehemu umeandikwa : vimebaki vipande $count kuchukuliwa.';
  }

  @override
  String livLatePassed(String date) {
    return 'Muda umepita (kikomo : $date)';
  }

  @override
  String livLateDays(int jours, String date) {
    return 'Muda umepita kwa siku $jours (kikomo : $date)';
  }

  @override
  String livPickToday(String date) {
    return 'Ya kuchukua leo (kikomo : $date)';
  }

  @override
  String livPickTomorrow(String date) {
    return 'Ya kuchukua kabla ya kesho jioni ($date)';
  }

  @override
  String livPickBefore(String date, int jours) {
    return 'Ya kuchukua kabla ya $date (siku $jours zimebaki)';
  }

  @override
  String livCall(String tel) {
    return 'Piga simu $tel';
  }

  @override
  String get livPartial => 'Imekabidhiwa sehemu';

  @override
  String livSoldOn(String date) {
    return 'Imeuzwa tarehe $date';
  }

  @override
  String livSoldOnBy(String date, String vendeur) {
    return 'Imeuzwa tarehe $date na $vendeur';
  }

  @override
  String get livStillToHand => 'Bado kukabidhi :';

  @override
  String get livToHandColon => 'Ya kukabidhi :';

  @override
  String get livNothingToHand => 'hakuna cha kukabidhi';

  @override
  String livOutOf(String count) {
    return '(kati ya $count)';
  }

  @override
  String livHanded(int count) {
    return 'imekabidhiwa : $count';
  }

  @override
  String livCancelled(int count) {
    return '$count imefutwa';
  }

  @override
  String get livAlreadyOut => 'Tayari imetoka :';

  @override
  String livUnpaid(String montant) {
    return 'Kiasi kilichobaki : $montant — kilipwe kabla ya kukabidhi';
  }

  @override
  String get livRemind => 'Kumbusha';

  @override
  String get livMarkDelivered => 'Weka kama imekabidhiwa';

  @override
  String livBy(String nom) {
    return '(na $nom)';
  }

  @override
  String get ccDepositTitle => 'Amana ya mteja';

  @override
  String get ccWithdrawTitle => 'Mteja kutoa pesa';

  @override
  String get ccPhoneLabel => 'Simu ya mteja *';

  @override
  String get ccPhoneShort => 'Namba fupi mno';

  @override
  String get ccNameLabel => 'Jina la mteja';

  @override
  String get ccAmountLabel => 'Kiasi (USD) *';

  @override
  String get ccMoreThanBalance => 'Zaidi ya salio lililopo';

  @override
  String ccAvailable(String montant) {
    return 'Salio lililopo : $montant';
  }

  @override
  String get ccCash => 'Pesa taslimu';

  @override
  String get ccSaveDeposit => 'Hifadhi amana';

  @override
  String get ccSaveWithdraw => 'Hifadhi utoaji';

  @override
  String ccDepositSaved(String montant) {
    return 'Amana ya $montant imehifadhiwa.';
  }

  @override
  String ccWithdrawSaved(String montant) {
    return 'Utoaji wa $montant umehifadhiwa.';
  }

  @override
  String get ccNewDeposit => 'Amana mpya';

  @override
  String get ccSearchHint => 'Jina au simu…';

  @override
  String ccCount(int count) {
    return 'Wateja $count wenye akaunti';
  }

  @override
  String ccTotalKept(String montant) {
    return 'Pesa za wateja zilizohifadhiwa : $montant';
  }

  @override
  String get ccNone =>
      'Hakuna akaunti ya mteja.\nBonyeza « Amana mpya » kuunda moja.';

  @override
  String get ccAccountTitle => 'Akaunti ya mteja';

  @override
  String get ccAvailableLabel => 'Salio lililopo';

  @override
  String get ccDeposit => 'Amana';

  @override
  String get ccWithdraw => 'Kutoa';

  @override
  String get ccSendStatement => 'Tuma taarifa kwa WhatsApp';

  @override
  String get ccHistory => 'Historia';

  @override
  String get ccNoMovement => 'Hakuna miamala.';

  @override
  String ccDateBy(String date, String nom) {
    return '$date • na $nom';
  }

  @override
  String ccBalanceAfter(String montant) {
    return 'Salio : $montant';
  }

  @override
  String get depSearchHint => 'Tafuta gharama...';

  @override
  String get depTitle => 'Gharama na Matumizi';

  @override
  String get depTabAll => 'Gharama zote';

  @override
  String get depTabByCat => 'Kwa aina';

  @override
  String get depExport => 'Hamisha';

  @override
  String get depColDate => 'Tarehe';

  @override
  String get depColTitle => 'Kichwa / Sababu';

  @override
  String get depColCategory => 'Aina';

  @override
  String get depColAmount => 'Kiasi';

  @override
  String get depColAuthor => 'Mwandishi';

  @override
  String get depColNote => 'Maelezo';

  @override
  String get depReportTitle => 'Ripoti ya Gharama na Matumizi';

  @override
  String get depToExcel => 'Hamisha kwa Excel';

  @override
  String get depPrintPdf => 'Chapisha / PDF';

  @override
  String get depTotalAll => 'Jumla kuu ya matumizi';

  @override
  String depTotalFor(String categorie) {
    return 'Jumla ya : $categorie';
  }

  @override
  String depNoResult(String recherche) {
    return 'Hakuna matokeo ya « $recherche »';
  }

  @override
  String get depNone => 'Hakuna gharama iliyoandikwa.';

  @override
  String depNote(String note) {
    return 'Maelezo : $note';
  }

  @override
  String get depEdit => 'Hariri';

  @override
  String get depDelete => 'Futa';

  @override
  String get depAdd => 'Ongeza gharama';

  @override
  String get depDeleteTitle => 'Futa gharama';

  @override
  String get depDeleteConfirm => 'Una uhakika unataka kufuta gharama hii?';

  @override
  String get depInvalidAmount => 'Tafadhali weka kiasi sahihi (> 0)';

  @override
  String get depEdited => 'Gharama imehaririwa!';

  @override
  String get depSaved => 'Gharama imehifadhiwa!';

  @override
  String depSaveError(String erreur) {
    return 'Hitilafu wakati wa kuhifadhi : $erreur';
  }

  @override
  String get depFormEdit => 'Hariri gharama';

  @override
  String get depFormNew => 'Andika gharama';

  @override
  String get depReasonRequired => 'Sababu inahitajika';

  @override
  String get depReasonLabel => 'Sababu / Kichwa';

  @override
  String get depReasonHint => 'mf: Kodi ya nyumba, Umeme...';

  @override
  String get depAmountRequired => 'Kiasi kinahitajika';

  @override
  String get depAmountInvalid => 'Kiasi si sahihi';

  @override
  String get depCategoryLabel => 'Aina ya gharama';

  @override
  String depDate(String date) {
    return 'Tarehe : $date';
  }

  @override
  String get depNoteLabel => 'Maelezo (si lazima)';

  @override
  String get depSaveChanges => 'Hifadhi mabadiliko';

  @override
  String get depSaveExpense => 'Hifadhi gharama';

  @override
  String get depCatAll => 'Zote';

  @override
  String get depCatRent => 'Kodi ya nyumba';

  @override
  String get depCatSalaries => 'Mishahara';

  @override
  String get depCatUtilities => 'Umeme na Maji';

  @override
  String get depCatTransport => 'Usafiri / Mafuta';

  @override
  String get depCatTaxes => 'Ushuru na Kodi';

  @override
  String get depCatMaintenance => 'Matengenezo';

  @override
  String get depCatMarketing => 'Matangazo';

  @override
  String get depCatOther => 'Nyingine';

  @override
  String get blTraceTitle => 'Ufuatiliaji unahitajika';

  @override
  String blTraceMsg(String montant, String seuil) {
    return 'Hati hii ya ukabidhi ni $montant USD (zaidi ya kikomo cha $seuil USD).\n\nKwa usalama wa fedha na ufuatiliaji, jina halali la mteja na namba ya simu vinahitajika.';
  }

  @override
  String get blTitle => 'Hati ya ukabidhi';

  @override
  String get blPrint => 'Chapisha';

  @override
  String get blShare => 'Shiriki (WhatsApp, barua pepe…)';

  @override
  String blPdfError(String erreur) {
    return 'Imeshindikana kuunda PDF : $erreur';
  }

  @override
  String get blPrintShare => 'Chapisha / Shiriki';

  @override
  String get blMyShop => 'Duka langu';

  @override
  String blPhoneShort(String tel) {
    return 'Simu : $tel';
  }

  @override
  String get blDeliveredTo => 'AMEKABIDHIWA :';

  @override
  String get blCounterClient => 'Mteja wa kaunta';

  @override
  String blAddress(String adresse) {
    return 'Anwani : $adresse';
  }

  @override
  String get blNotSpecified => 'Haijatajwa';

  @override
  String blPhone(String tel) {
    return 'Simu : $tel';
  }

  @override
  String get blColItem => 'Bidhaa';

  @override
  String get blColQty => 'Idadi';

  @override
  String get blColUnit => 'Bei';

  @override
  String get blColTotal => 'Jumla';

  @override
  String get blGrandTotal => 'JUMLA KUU : ';

  @override
  String get blDeliverer => 'Mkabidhi / Mtumaji';

  @override
  String get blCustomerSign => 'Mteja (amekubali)';
}
