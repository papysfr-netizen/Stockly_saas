// lib/features/shell/rapport_jour.dart
//
// 📊 RAPPORT DÉTAILLÉ DU JOUR (texte WhatsApp)
//  - chaque vente (heure, client, articles, montant, crédit, vendeur)
//  - produits vendus, par vendeur, par moyen de paiement
//  - dépenses, dettes encaissées, nouveaux crédits (avec motif)
//  - stock à recommander
// Ce fichier ne fait que FABRIQUER le texte : il n'enregistre rien.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:stockly_saas/core/models/depense.dart';
import 'package:stockly_saas/core/services/argent_vente.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

class RapportJour {
  static const String _trait = '━━━━━━━━━━━━━━';
  static const int _maxLignes = 40;

  static double _n(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  static DateTime? _d(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static String _client(AppLocalizations l, Object? nom) {
    final n = (nom ?? '').toString().trim();
    return (n.isEmpty || n == 'Client Divers') ? l.histWalkIn : n;
  }

  /// Un identifiant technique (uid) n'est pas un nom : on ne l'affiche pas.
  static String _personne(Object? v) {
    final s = (v ?? '').toString().trim();
    if (s.length >= 20 && !s.contains(' ')) return '';
    return s;
  }

  /// Ajoute une liste de lignes (au plus 40, puis « …et N autre(s) »)
  static void _lignes(StringBuffer b, AppLocalizations l, List<String> lignes) {
    for (final x in lignes.take(_maxLignes)) {
      b.writeln('• $x');
    }
    if (lignes.length > _maxLignes) b.writeln(l.repMore(lignes.length - _maxLignes));
  }

  static Future<String> detail({
    required AppLocalizations l,
    required String resumeCourt,
    required String entrepriseId,
    required List<Map<String, dynamic>> ventes,
    required List<Depense> depenses,
    required List<Map<String, dynamic>> dettesEncaissees,
    required List<MapEntry<String, num>> stockBas,
    required String Function(double) prix,
    String? boutique, // 🏬 null = toutes les boutiques
  }) async {
    final heure = DateFormat('HH:mm');
    final now = DateTime.now();
    final minuit = DateTime(now.year, now.month, now.day);

    // L'en-tête du résumé court (1re ligne) reste en haut
    final lignesResume = resumeCourt.split('\n');
    final entete = lignesResume.first;
    final totaux = lignesResume.skip(1).join('\n');

    final b = StringBuffer()
      ..writeln(entete)
      ..writeln(_trait);

    // ---------- 🛒 Ventes ----------
    final liste = [...ventes]
      ..sort((a, x) => (_d(a['date']) ?? minuit).compareTo(_d(x['date']) ?? minuit));
    double totalVentes = 0;
    final produits = <String, List<double>>{}; // nom -> [quantité, montant]
    final parVendeur = <String, List<double>>{}; // vendeur -> [montant, nombre]
    final parMoyen = <String, double>{};
    final lignesVentes = <String>[];

    for (final v in liste) {
      final total = _n(v['montantTotal'] ?? v['total']) -
          _n(v['montantRetourne']) -
          _n(v['montantAnnule']);
      final reste = _n(v['resteAPayer']);
      totalVentes += total;

      final articles = (v['articles'] is List ? v['articles'] as List : const [])
          .whereType<Map>()
          .toList();
      final texteArticles = articles
          .map((a) => '${_n(a['quantite']).toInt()} × ${(a['nom'] ?? '').toString()}')
          .join(', ');
      for (final a in articles) {
        final nom = (a['nom'] ?? '').toString();
        final p = produits.putIfAbsent(nom, () => [0, 0]);
        p[0] += _n(a['quantite']);
        p[1] += _n(a['totalItem']);
      }

      final vendeur = _personne(v['vendeurNom']);
      final pv = parVendeur.putIfAbsent(vendeur.isEmpty ? '—' : vendeur, () => [0, 0]);
      pv[0] += total;
      pv[1] += 1;

      // 💵 Même calcul que l'Accueil : argent reçu à la vente (sans monnaie rendue ni compte client)
      final cash = ArgentVente.cashALaVente(v);
      if (cash > 0.005) {
        final moyen =
            (v['methodePaiement'] ?? 'Cash').toString().replaceAll(' + Compte client', '');
        parMoyen[moyen] = (parMoyen[moyen] ?? 0) + cash;
      }
      final parCompte = _n(v['montantCompteClient']);
      if (parCompte > 0.005) {
        parMoyen['Compte client'] = (parMoyen['Compte client'] ?? 0) + parCompte;
      }

      final d = _d(v['date']);
      lignesVentes.add([
        '${d == null ? '' : '${heure.format(d)} '}${_client(l, v['nomClient'])}',
        if (texteArticles.isNotEmpty) texteArticles,
        '${prix(total)}${reste > 0.005 ? ' (${l.repCredit(prix(reste))})' : ''}',
        if (vendeur.isNotEmpty) vendeur,
      ].join(' — '));
    }

    b.writeln('*${l.repSales(liste.length, prix(totalVentes))}*');
    _lignes(b, l, lignesVentes);

    // ---------- 📦 Produits vendus ----------
    if (produits.isNotEmpty) {
      final tri = produits.entries.toList()..sort((a, x) => x.value[1].compareTo(a.value[1]));
      b
        ..writeln()
        ..writeln('*${l.repProducts}*');
      _lignes(b, l, [
        for (final e in tri) '${e.key} : ${e.value[0].toInt()} — ${prix(e.value[1])}',
      ]);
    }

    // ---------- 👤 Par vendeur ----------
    if (parVendeur.isNotEmpty) {
      final tri = parVendeur.entries.toList()..sort((a, x) => x.value[0].compareTo(a.value[0]));
      b
        ..writeln()
        ..writeln('*${l.repBySeller}*');
      _lignes(b, l, [
        for (final e in tri) '${e.key} : ${prix(e.value[0])} (${e.value[1].toInt()})',
      ]);
    }

    // ---------- 💳 Par moyen de paiement ----------
    if (parMoyen.isNotEmpty) {
      final tri = parMoyen.entries.toList()..sort((a, x) => x.value.compareTo(a.value));
      b
        ..writeln()
        ..writeln('*${l.repByMethod}*');
      _lignes(b, l, [for (final e in tri) '${e.key} : ${prix(e.value)}']);
    }

    // ---------- 💸 Dépenses ----------
    if (depenses.isNotEmpty) {
      final tri = [...depenses]..sort((a, x) => a.date.compareTo(x.date));
      final total = tri.fold<double>(0, (s, d) => s + d.montant);
      b
        ..writeln()
        ..writeln('*${l.repExpenses(prix(total))}*');
      _lignes(b, l, [
        for (final d in tri)
          [
            '${heure.format(d.date)} ${d.titre.trim().isEmpty ? d.categorie : d.titre.trim()}'
                '${d.titre.trim().isNotEmpty && d.categorie.trim().isNotEmpty ? ' (${d.categorie})' : ''}',
            prix(d.montant),
            if (_personne(d.enregistrePar).isNotEmpty) _personne(d.enregistrePar),
          ].join(' — '),
      ]);
    }

    // ---------- 💰 Dettes encaissées ----------
    if (dettesEncaissees.isNotEmpty) {
      final tri = [...dettesEncaissees]
        ..sort((a, x) => (_d(a['date']) ?? minuit).compareTo(_d(x['date']) ?? minuit));
      final total = tri.fold<double>(0, (s, e) => s + _n(e['montant']));
      b
        ..writeln()
        ..writeln('*${l.repDebtsCollected(prix(total))}*');
      _lignes(b, l, [
        for (final e in tri)
          [
            '${_d(e['date']) == null ? '' : '${heure.format(_d(e['date'])!)} '}${_client(l, e['nom'])}',
            prix(_n(e['montant'])),
            if (_personne(e['parNom']).isNotEmpty) _personne(e['parNom']),
          ].join(' — '),
      ]);
    }

    // ---------- 📝 Nouveaux crédits (avec motif) ----------
    final credits = <String>[];
    double totalCredits = 0;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('creances')
          .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(minuit))
          .get()
          .timeout(const Duration(seconds: 5));
      for (final doc in snap.docs) {
        final c = doc.data();
        if (boutique != null) { // 🏬 crédit de la boutique affichée
          final b = (c['boutiqueId'] ?? '').toString();
          if ((b.isEmpty ? 'principale' : b) != boutique) continue;
        }
        final initial = _n(c['montantInitial']);
        final reste = _n(c['montantReste']);
        final note = (c['note'] ?? '').toString().trim();
        final motif = note.startsWith('Créance issue de la vente') ? '' : note;
        totalCredits += reste;
        credits.add([
          _client(l, c['nomTiers'] ?? c['nomClient']),
          '${prix(initial)} (${l.accRemaining(prix(reste))})',
          if (motif.isNotEmpty) '« $motif »',
        ].join(' — '));
      }
    } catch (_) {
      // Pas de réseau : on se contente des ventes à crédit du jour (sans motif)
      for (final v in liste) {
        final reste = _n(v['resteAPayer']);
        if (reste <= 0.005) continue;
        totalCredits += reste;
        credits.add('${_client(l, v['nomClient'])} — ${l.accRemaining(prix(reste))}');
      }
    }
    if (credits.isNotEmpty) {
      b
        ..writeln()
        ..writeln('*${l.repNewCredits(prix(totalCredits))}*');
      _lignes(b, l, credits);
    }

    // ---------- ⚠️ À recommander ----------
    if (stockBas.isNotEmpty) {
      final tri = [...stockBas]..sort((a, x) => a.value.compareTo(x.value));
      b
        ..writeln()
        ..writeln('*${l.repToReorder}*');
      _lignes(b, l, [
        for (final e in tri) '${e.key} : ${e.value.toStringAsFixed(e.value % 1 == 0 ? 0 : 1)}',
      ]);
    }

    // ---------- Totaux (le résumé court) ----------
    b
      ..writeln(_trait)
      ..write(totaux);
    return b.toString();
  }
}
