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
}
