import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vente.dart';
import '../providers/cart_provider.dart';
import '../services/compta_service.dart';

class VenteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Accès direct aux collections racines selon votre console Firestore
  CollectionReference get _ventesRef => _firestore.collection('ventes');
  CollectionReference get _produitsRef => _firestore.collection('produits');

  /// Enregistre une vente avec décrémentation de stock et comptabilisation atomique (WriteBatch)
  Future<void> enregistrerVente({
    required Vente vente,
    required List<CartItem> cartItems,
    required String entrepriseId,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    // 1. Création de la vente dans /ventes
    final venteDocRef = _ventesRef.doc();

    final venteData = vente.toJson();
    venteData['id'] = venteDocRef.id;
    venteData['entrepriseId'] = entrepriseId;
    venteData['comptabilise'] = true;
    venteData['createdAt'] = FieldValue.serverTimestamp();
    venteData['createdBy'] = userId;

    batch.set(venteDocRef, venteData);

    // 2. Décrémentation de stock dans la collection racine /produits (ex: ent_01_t03)
    for (final item in cartItems) {
      final produitRef = _produitsRef.doc(item.id);
      
      batch.set(
        produitRef,
        {
          'quantite': FieldValue.increment(-item.quantite),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // 3. Écritures comptables immutables
    final String client = (vente.clientNom != null && vente.clientNom!.isNotEmpty)
        ? vente.clientNom!
        : 'Client Divers';

    if (vente.montantPaye > 0) {
      ComptaService.ajouterEcritureDansBatch(
        batch: batch,
        entrepriseId: entrepriseId,
        libelle: 'Vente en caisse - $client',
        compteDebit: '531000',
        compteCredit: '701000',
        montant: vente.montantPaye,
        date: vente.date,
        pieceRef: venteDocRef.id,
      );
    }

    if (vente.resteAPayer > 0) {
      ComptaService.ajouterEcritureDansBatch(
        batch: batch,
        entrepriseId: entrepriseId,
        libelle: 'Créance vente - Client : $client',
        compteDebit: '411000',
        compteCredit: '701000',
        montant: vente.resteAPayer,
        date: vente.date,
        pieceRef: venteDocRef.id,
      );
    }

    await batch.commit();
  }

  /// Historique des ventes filtré par entrepriseId
  Stream<List<Vente>> getVentes(String entrepriseId) {
    return _ventesRef
        .where('entrepriseId', isEqualTo: entrepriseId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vente.fromJson({
          ...(doc.data() as Map<String, dynamic>),
          'id': doc.id,
        });
      }).toList();
    });
  }

  /// Récupération des dettes actives filtrées par entrepriseId
  Stream<List<Vente>> getDettes(String entrepriseId) {
    return _ventesRef
        .where('entrepriseId', isEqualTo: entrepriseId)
        .where('resteAPayer', isGreaterThan: 0)
        .orderBy('resteAPayer', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vente.fromJson({
          ...(doc.data() as Map<String, dynamic>),
          'id': doc.id,
        });
      }).toList();
    });
  }

  /// Règlement de créance atomique
  Future<void> reglerDette({
    required String entrepriseId,
    required String venteId,
    required double montantAcompte,
    required String userId,
  }) async {
    final batch = _firestore.batch();
    final venteDocRef = _ventesRef.doc(venteId);

    final snapshot = await venteDocRef.get();
    if (!snapshot.exists) {
      throw Exception('Vente introuvable');
    }

    final data = snapshot.data() as Map<String, dynamic>;
    final String client = data['clientNom'] ?? data['nomClient'] ?? 'Client';
    final double montantPayeActuel = (data['montantPaye'] as num?)?.toDouble() ?? 0.0;
    final double total = (data['total'] as num?)?.toDouble() ?? 0.0;

    final double nouveauMontantPaye = montantPayeActuel + montantAcompte;
    final double nouveauReste = total - nouveauMontantPaye;
    final String nouveauStatut = nouveauReste <= 0 ? 'Payé' : 'Acompte';

    batch.set(
      venteDocRef,
      {
        'montantPaye': nouveauMontantPaye,
        'resteAPayer': nouveauReste < 0 ? 0.0 : nouveauReste,
        'statutPaiement': nouveauStatut,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      },
      SetOptions(merge: true),
    );

    if (montantAcompte > 0) {
      ComptaService.ajouterEcritureDansBatch(
        batch: batch,
        entrepriseId: entrepriseId,
        libelle: 'Règlement créance - $client',
        compteDebit: '531000',
        compteCredit: '411000',
        montant: montantAcompte,
        date: DateTime.now(),
        pieceRef: venteId,
      );
    }

    await batch.commit();
  }
}