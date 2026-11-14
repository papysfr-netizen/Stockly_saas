// lib/features/debts/controllers/debt_controller.dart

import 'dart:async';
import 'package:stockly_saas/features/comptes_clients/compte_client_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/core/services/journal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'package:stockly_saas/core/services/utilisateur_service.dart';

import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/core/models/payment_method.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/core/models/dette.dart';

// ============================================================================
// PROVIDERS RIVERPOD
// ============================================================================

/// Flux temps réel combinant 'creances' (clients) et 'dettes' (fournisseurs)
final dettesStreamProvider =
    StreamProvider.family<List<Dette>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value([]);

  final db = FirebaseFirestore.instance;

  // 💸 On ne relit pas tout l'historique :
  //   - toutes les dettes EN COURS (reste à payer) ;
  //   - les dettes soldées ou créées depuis moins de 6 mois (filtre « Soldées »).
  final il6Mois = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 183)));
  Stream<List<Dette>> lire(String nomCollection) {
    final col = db.collection('entreprises').doc(entrepriseId).collection(nomCollection);
    List<Dette> versListe(QuerySnapshot<Map<String, dynamic>> s) =>
        s.docs.map((doc) => Dette.fromDocument(doc)).toList();
    return Rx.combineLatest3<List<Dette>, List<Dette>, List<Dette>, List<Dette>>(
      col.where('montantReste', isGreaterThan: 0).snapshots().map(versListe),
      col.where('dernierPaiement', isGreaterThanOrEqualTo: il6Mois).snapshots().map(versListe),
      col.where('dateCreation', isGreaterThanOrEqualTo: il6Mois).snapshots().map(versListe),
      (enCours, payees, recentes) {
        // Une même dette peut venir de plusieurs listes : on la garde une fois
        final parId = <String, Dette>{};
        for (final d in [...enCours, ...payees, ...recentes]) {
          parId[d.id] = d;
        }
        return parId.values.toList();
      },
    );
  }

  // Stream 1 : Créances clients
  final creancesStream = lire('creances');

  // Stream 2 : Dettes fournisseurs
  final dettesStream = lire('dettes');

  // Fusion et tri sécurisé
  return Rx.combineLatest2<List<Dette>, List<Dette>, List<Dette>>(
    creancesStream,
    dettesStream,
    (creances, dettes) {
      final combined = [...creances, ...dettes];
      combined.sort((a, b) {
        final bDate = b.dateCreation;
        final aDate = a.dateCreation;
        return bDate.compareTo(aDate);
      });
      return combined;
    },
  );
});

/// Controller gérant les mutations de dettes/créances et la synchronisation comptable
final debtControllerProvider =
    AsyncNotifierProvider.family<DebtController, void, String>(
  DebtController.new,
);

// ============================================================================
// DEBT CONTROLLER (FamilyAsyncNotifier)
// ============================================================================

class DebtController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  /// Arrondi financier à 2 décimales
  double _roundMoney(double value) => (value * 100).roundToDouble() / 100;

  /// Nom de la personne connectée (pour l'historique des paiements)
  Future<String> _nomConnecte() async {
    try {
      final dynamic n = await nomUtilisateurConnecte();
      final s = (n ?? '').toString().trim();
      return s == 'null' ? '' : s;
    } catch (_) {
      return '';
    }
  }

  /// Une ligne de l'historique des paiements
  Map<String, dynamic> _lignePaiement(
      DateTime date, double montant, PaymentMethod methode, String parNom) {
    return {
      'date': Timestamp.fromDate(date),
      'montant': montant,
      'methode': methode.name,
      'parNom': parNom,
      'parUid': FirebaseAuth.instance.currentUser?.uid ?? '',
    };
  }

  /// Détermine le code de journal selon le moyen de paiement (SYSCOHADA)
  String _getJournalCodeForPayment(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'CA'; // Caisse
      case PaymentMethod.bankTransfer:
      case PaymentMethod.check:
        return 'BQ'; // Banque
      default:
        return 'TR'; // Trésorerie générale / Mobile Money
    }
  }

  /// Sélectionne la collection cible selon le type
  CollectionReference _getTargetRef(String entrepriseId, TypeDette type) {
    final collectionName = type == TypeDette.client ? 'creances' : 'dettes';
    return FirebaseFirestore.instance
        .collection('entreprises')
        .doc(entrepriseId)
        .collection(collectionName);
  }

  CollectionReference _ecrituresRef(String entrepriseId) {
    return FirebaseFirestore.instance
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables');
  }

  /// Ajoute une nouvelle dette/créance avec écritures comptables d'engagement et d'acompte
  Future<void> ajouterDette({
    required String nomTiers,
    String telephone = '', // 📵 obligatoire pour une créance client
    required String numeroFacture,
    required double montantTotal,
    required double acompte,
    required TypeDette type,
    required String note,
    DateTime? dateEcheance,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String boutiqueId = 'principale', // 🏬
  }) async {
    final entrepriseId = arg;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cleanNom = nomTiers.trim();
      final cleanFacture = numeroFacture.trim();

      if (entrepriseId.isEmpty) {
        throw ArgumentError("L'identifiant de l'entreprise est manquant.");
      }
      if (cleanNom.isEmpty) {
        throw ArgumentError('Le nom du tiers est obligatoire.');
      }
      if (type == TypeDette.client &&
          !CompteClientService.telephoneValide(telephone)) {
        throw ArgumentError(
            'Le téléphone du client est obligatoire pour un crédit (au moins 9 chiffres).');
      }
      if (cleanFacture.isEmpty) {
        throw ArgumentError('Le numéro de facture est obligatoire.');
      }
      if (montantTotal <= 0) {
        throw ArgumentError('Le montant total doit être strictement supérieur à zéro.');
      }

      final parNom = await _nomConnecte();
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final targetRef = _getTargetRef(entrepriseId, type).doc();
      final now = DateTime.now();

      final double totalArrondi = _roundMoney(montantTotal);
      final double pureAcompte = _roundMoney(acompte.clamp(0.0, totalArrondi));
      final double montantReste = _roundMoney(totalArrondi - pureAcompte);

      String statutInitial = 'non_paye';
      if (montantReste <= 0) {
        statutInitial = 'paye';
      } else if (pureAcompte > 0) {
        statutInitial = 'partiel';
      }

      final bool isClient = type == TypeDette.client;

      // 1. Enregistrement du document Dette/Créance
      final dette = Dette(
        id: targetRef.id,
        boutiqueId: boutiqueId,
        nomTiers: cleanNom,
        telephone: telephone.trim(),
        numeroFacture: cleanFacture,
        montantInitial: totalArrondi,
        acomptePaye: pureAcompte,
        montantReste: montantReste,
        type: type,
        statut: statutInitial,
        note: note.trim(),
        dateCreation: now,
        dateEcheance: dateEcheance,
        entrepriseId: entrepriseId,
        comptabilise: true,
      );

      batch.set(targetRef, {
        ...dette.toFirestore(),
        // 🧾 Historique : l'acompte versé à la création
        if (pureAcompte > 0)
          'paiements': [_lignePaiement(now, pureAcompte, paymentMethod, parNom)],
        // 💵 Argent reçu aujourd'hui : visible par l'accueil et la clôture de caisse
        if (pureAcompte > 0) 'dernierPaiement': Timestamp.fromDate(now),
      });

      // 2. Écriture d'engagement comptable (SYSCOHADA)
      final ecritureEngagementRef = _ecrituresRef(entrepriseId).doc();
      final String codeDebit = isClient ? '411000' : '601000';
      final String codeCredit = isClient ? '701000' : '401000';

      final String labelDebit = isClient
          ? 'Clients - $cleanNom'
          : JournalEntry.getAccountLabel('601000');
      final String labelCredit = isClient
          ? JournalEntry.getAccountLabel('701000')
          : 'Fournisseurs - $cleanNom';

      final engagementEntry = JournalEntry(
        id: ecritureEngagementRef.id,
        entrepriseId: entrepriseId,
        date: now,
        reference: targetRef.id,
        journalCode: isClient ? 'VT' : 'HA',
        description: isClient
            ? 'Créance Client : $cleanNom (Facture $cleanFacture)'
            : 'Dette Fournisseur : $cleanNom (Facture $cleanFacture)',
        lines: [
          JournalEntryLine(
            accountCode: codeDebit,
            accountLabel: labelDebit,
            debit: totalArrondi,
            credit: 0.0,
          ),
          JournalEntryLine(
            accountCode: codeCredit,
            accountLabel: labelCredit,
            debit: 0.0,
            credit: totalArrondi,
          ),
        ],
      );

      batch.set(ecritureEngagementRef,
          {...engagementEntry.toFirestore(), 'boutiqueId': boutiqueId}); // 🏬 compta

      // 3. Écriture d'acompte comptable
      if (pureAcompte > 0) {
        final ecritureAcompteRef = _ecrituresRef(entrepriseId).doc();
        final String codeTresorerie =
            AccountingJournalService.getAccountCodeForPayment(paymentMethod);

        final String acompteDebit = isClient ? codeTresorerie : '401000';
        final String acompteCredit = isClient ? '411000' : codeTresorerie;

        final String acompteDebitLabel = isClient
            ? JournalEntry.getAccountLabel(codeTresorerie)
            : 'Fournisseurs - $cleanNom';
        final String acompteCreditLabel = isClient
            ? 'Clients - $cleanNom'
            : JournalEntry.getAccountLabel(codeTresorerie);

        final acompteEntry = JournalEntry(
          id: ecritureAcompteRef.id,
          entrepriseId: entrepriseId,
          date: now,
          reference: targetRef.id,
          journalCode: _getJournalCodeForPayment(paymentMethod),
          description: isClient
              ? 'Paiement partiel client : $cleanNom (Facture $cleanFacture)'
              : 'Paiement partiel fournisseur : $cleanNom (Facture $cleanFacture)',
          lines: [
            JournalEntryLine(
              accountCode: acompteDebit,
              accountLabel: acompteDebitLabel,
              debit: pureAcompte,
              credit: 0.0,
            ),
            JournalEntryLine(
              accountCode: acompteCredit,
              accountLabel: acompteCreditLabel,
              debit: 0.0,
              credit: pureAcompte,
            ),
          ],
          montantEncaisse: isClient ? pureAcompte : 0.0,
        );

        batch.set(ecritureAcompteRef,
            {...acompteEntry.toFirestore(), 'boutiqueId': boutiqueId}); // 🏬 compta
      }

      await batch.commit();
    });
  }

  /// 📶 Le serveur répond-il ? (lecture rapide, 5 secondes maximum)
  Future<bool> _serveurJoignable(String entrepriseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 📴 Paiement SANS internet : calculé avec la copie du téléphone,
  /// écrit avec des « increments » et envoyé au retour du réseau.
  Future<({String info, double montant, String boutique})> _paiementHorsLigne({
    required String entrepriseId,
    required String detteId,
    required TypeDette? type,
    required double montantPaye,
    required PaymentMethod paymentMethod,
    required String parNom,
  }) async {
    const cache = GetOptions(source: Source.cache);
    DocumentReference docRef;
    DocumentSnapshot? snapshot;

    Future<DocumentSnapshot?> lireCache(DocumentReference r) async {
      try {
        return await r.get(cache);
      } catch (_) {
        return null;
      }
    }

    if (type != null) {
      docRef = _getTargetRef(entrepriseId, type).doc(detteId);
      snapshot = await lireCache(docRef);
    } else {
      final creanceRef = _getTargetRef(entrepriseId, TypeDette.client).doc(detteId);
      final s = await lireCache(creanceRef);
      if (s != null && s.exists) {
        docRef = creanceRef;
        snapshot = s;
      } else {
        docRef = _getTargetRef(entrepriseId, TypeDette.fournisseur).doc(detteId);
        snapshot = await lireCache(docRef);
      }
    }

    if (snapshot == null || !snapshot.exists) {
      throw StateError(
          "Pas d'internet, et cette dette n'est pas encore dans le téléphone. Réessayez avec internet.");
    }

    final dette = Dette.fromDocument(snapshot);
    if (dette.montantReste <= 0) {
      throw StateError('Cette créance/dette est déjà entièrement soldée.');
    }

    final double montantEffectif = _roundMoney(
      montantPaye > dette.montantReste ? dette.montantReste : montantPaye,
    );
    final double nouveauReste = _roundMoney(dette.montantReste - montantEffectif);
    final String nouveauStatut = nouveauReste <= 0 ? 'paye' : 'partiel';
    final now = DateTime.now();
    final bool isClient = dette.type == TypeDette.client;
    final data = snapshot.data();
    final aMontantRestant = data is Map && data.containsKey('montantRestant');

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    batch.update(docRef, {
      // « increment » : juste, même si un autre paiement arrive en même temps
      'montantReste': FieldValue.increment(-montantEffectif),
      'montantRestant':
          aMontantRestant ? FieldValue.increment(-montantEffectif) : nouveauReste,
      'acomptePaye': FieldValue.increment(montantEffectif),
      'statut': nouveauStatut,
      'dernierPaiement': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // 🧾 Historique des paiements
      'paiements': FieldValue.arrayUnion([
        _lignePaiement(now, montantEffectif, paymentMethod, parNom),
      ]),
    });

    final ecritureRef = _ecrituresRef(entrepriseId).doc();
    final String codeTresorerie =
        AccountingJournalService.getAccountCodeForPayment(paymentMethod);
    final String debitCode = isClient ? codeTresorerie : '401000';
    final String creditCode = isClient ? '411000' : codeTresorerie;

    final journalEntry = JournalEntry(
      id: ecritureRef.id,
      entrepriseId: entrepriseId,
      date: now,
      reference: detteId,
      journalCode: _getJournalCodeForPayment(paymentMethod),
      description: isClient
          ? 'Règlement créance client : ${dette.nomTiers}'
          : 'Règlement dette fournisseur : ${dette.nomTiers}',
      lines: [
        JournalEntryLine(
          accountCode: debitCode,
          accountLabel: isClient
              ? JournalEntry.getAccountLabel(codeTresorerie)
              : 'Fournisseurs - ${dette.nomTiers}',
          debit: montantEffectif,
          credit: 0.0,
        ),
        JournalEntryLine(
          accountCode: creditCode,
          accountLabel: isClient
              ? 'Clients - ${dette.nomTiers}'
              : JournalEntry.getAccountLabel(codeTresorerie),
          debit: 0.0,
          credit: montantEffectif,
        ),
      ],
      montantEncaisse: isClient ? montantEffectif : 0.0,
    );

    final boutique = dette.boutiqueId.isEmpty ? 'principale' : dette.boutiqueId;
    batch.set(ecritureRef, {
      ...journalEntry.toFirestore(),
      'boutiqueId': boutique, // 🏬 compta
    });

    try {
      await batch.commit().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // Hors ligne : gardé sur le téléphone, envoyé au retour d'internet
    }

    final info = '${isClient ? 'Client' : 'Fournisseur'} ${dette.nomTiers} · '
        'payé ${montantEffectif.toStringAsFixed(2)} \$ · '
        '${nouveauReste <= 0 ? 'soldé' : 'reste ${nouveauReste.toStringAsFixed(2)} \$'} · '
        '${JournalEntry.getAccountLabel(codeTresorerie)} · hors ligne';
    return (info: info, montant: montantEffectif, boutique: boutique);
  }

  /// Enregistre un règlement partiel ou total de manière atomique (Transaction)
  Future<void> enregistrerPaiement({
    required String detteId,
    required double montantPaye,
    TypeDette? type,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    final entrepriseId = arg;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (entrepriseId.isEmpty || detteId.trim().isEmpty) {
        throw ArgumentError("Paramètres d'identification invalides.");
      }
      if (montantPaye <= 0) {
        throw ArgumentError('Le montant payé doit être strictement positif.');
      }

      final parNom = await _nomConnecte();
      final db = FirebaseFirestore.instance;

      // 📒 Remplis dans la transaction, utilisés pour le journal ensuite
      String? infoJournal;
      double montantJournal = 0;
      String boutiqueJournal = 'principale';

      // 📴 Pas d'internet : paiement gardé sur le téléphone, envoyé plus tard
      if (!await _serveurJoignable(entrepriseId)) {
        final r = await _paiementHorsLigne(
          entrepriseId: entrepriseId,
          detteId: detteId,
          type: type,
          montantPaye: montantPaye,
          paymentMethod: paymentMethod,
          parNom: parNom,
        );
        unawaited(noterJournal(
          entrepriseId: entrepriseId,
          action: ActionsJournal.paiementDette,
          details: r.info,
          boutiqueId: r.boutique,
          montant: r.montant,
          reference: detteId,
        ));
        return;
      }

      await db.runTransaction((transaction) async {
        DocumentReference docRef;
        DocumentSnapshot snapshot;

        if (type != null) {
          docRef = _getTargetRef(entrepriseId, type).doc(detteId);
          snapshot = await transaction.get(docRef);
        } else {
          final creanceRef = _getTargetRef(entrepriseId, TypeDette.client).doc(detteId);
          final creanceSnap = await transaction.get(creanceRef);

          if (creanceSnap.exists) {
            docRef = creanceRef;
            snapshot = creanceSnap;
          } else {
            docRef = _getTargetRef(entrepriseId, TypeDette.fournisseur).doc(detteId);
            snapshot = await transaction.get(docRef);
          }
        }

        if (!snapshot.exists) {
          throw StateError('Dette ou Créance introuvable dans Firestore.');
        }

        final dette = Dette.fromDocument(snapshot);

        if (dette.montantReste <= 0) {
          throw StateError('Cette créance/dette est déjà entièrement soldée.');
        }

        final double montantEffectif = _roundMoney(
          montantPaye > dette.montantReste ? dette.montantReste : montantPaye,
        );
        final double nouveauReste = _roundMoney(dette.montantReste - montantEffectif);
        final double acompteCumule = _roundMoney(dette.acomptePaye + montantEffectif);
        final String nouveauStatut = nouveauReste <= 0 ? 'paye' : 'partiel';
        final now = DateTime.now();
        final bool isClient = dette.type == TypeDette.client;

        infoJournal = '${isClient ? 'Client' : 'Fournisseur'} ${dette.nomTiers} · '
            'payé ${montantEffectif.toStringAsFixed(2)} \$ · '
            '${nouveauReste <= 0 ? 'soldé' : 'reste ${nouveauReste.toStringAsFixed(2)} \$'} · '
            '${JournalEntry.getAccountLabel(AccountingJournalService.getAccountCodeForPayment(paymentMethod))}';
        montantJournal = montantEffectif;
        boutiqueJournal = dette.boutiqueId.isEmpty ? 'principale' : dette.boutiqueId;

        transaction.update(docRef, {
          'montantReste': nouveauReste,
          'montantRestant': nouveauReste,
          'acomptePaye': acompteCumule,
          'statut': nouveauStatut,
          'dernierPaiement': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // 🧾 Historique des paiements
          'paiements': FieldValue.arrayUnion([
            _lignePaiement(now, montantEffectif, paymentMethod, parNom),
          ]),
        });

        final ecritureRef = _ecrituresRef(entrepriseId).doc();
        final String codeTresorerie =
            AccountingJournalService.getAccountCodeForPayment(paymentMethod);

        final String debitCode = isClient ? codeTresorerie : '401000';
        final String creditCode = isClient ? '411000' : codeTresorerie;

        final journalEntry = JournalEntry(
          id: ecritureRef.id,
          entrepriseId: entrepriseId,
          date: now,
          reference: detteId,
          journalCode: _getJournalCodeForPayment(paymentMethod),
          description: isClient
              ? 'Règlement créance client : ${dette.nomTiers}'
              : 'Règlement dette fournisseur : ${dette.nomTiers}',
          lines: [
            JournalEntryLine(
              accountCode: debitCode,
              accountLabel: isClient
                  ? JournalEntry.getAccountLabel(codeTresorerie)
                  : 'Fournisseurs - ${dette.nomTiers}',
              debit: montantEffectif,
              credit: 0.0,
            ),
            JournalEntryLine(
              accountCode: creditCode,
              accountLabel: isClient
                  ? 'Clients - ${dette.nomTiers}'
                  : JournalEntry.getAccountLabel(codeTresorerie),
              debit: 0.0,
              credit: montantEffectif,
            ),
          ],
          montantEncaisse: isClient ? montantEffectif : 0.0,
        );

        transaction.set(ecritureRef, {
          ...journalEntry.toFirestore(),
          'boutiqueId': dette.boutiqueId.isEmpty ? 'principale' : dette.boutiqueId, // 🏬 compta
        });
      });

      // 📒 Journal « qui a fait quoi » (n'empêche jamais le paiement)
      final info = infoJournal;
      if (info != null) {
        unawaited(noterJournal(
          entrepriseId: entrepriseId,
          action: ActionsJournal.paiementDette,
          details: info,
          boutiqueId: boutiqueJournal,
          montant: montantJournal,
          reference: detteId,
        ));
      }
    });
  }
}