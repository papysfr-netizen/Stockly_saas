import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

import '../core/evaluation.dart';
import '../core/telephone.dart';
import '../models/classe.dart';
import '../models/eleve.dart';
import '../models/scolarite.dart';

/// Import des données de l'école depuis un classeur Excel (modèle fourni).
/// L'analyse ne modifie rien : elle produit un [PlanImport] à confirmer.

const feuilleClasses = 'Classes';
const feuilleBranches = 'Branches';
const feuilleEnseignants = 'Enseignants';
const feuilleEleves = 'Élèves';

const colonnesClasses = ['Nom de la classe *', 'Cycle (Maternelle, Primaire, Secondaire)', 'Niveau', 'Section / option', 'Frais annuels'];
const colonnesBranches = ['Classe *', 'Branche *', 'Maxima par période', 'Coefficient'];
const colonnesEnseignants = ['Nom *', 'Prénom *', 'Téléphone', 'E-mail', 'Spécialité', 'Classes (séparées par ;)'];
const colonnesEleves = [
  'Classe *', 'Nom *', 'Prénom *', 'Sexe (M/F)', 'Date de naissance (JJ/MM/AAAA)', 'Matricule',
  'Nom du parent', 'Téléphone du parent', 'E-mail du parent',
];

// ------------------------------------------------------------------
// Modèle à remplir
// ------------------------------------------------------------------
List<int> modeleImport() {
  final x = Excel.createExcel();
  final gras = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#D9E2F3'));

  final aide = x["Mode d'emploi"];
  for (final l in [
    "Importer les données de l'école",
    '',
    'Remplissez les feuilles Classes, Branches, Enseignants et Élèves, une ligne par élément, à partir de la ligne 2.',
    'Les colonnes marquées * sont obligatoires. Laissez une feuille vide si vous ne l\'utilisez pas.',
    'Les classes déjà créées dans l\'application peuvent être utilisées sans les répéter dans la feuille Classes.',
    '',
    'Classes : Cycle = Maternelle, Primaire ou Secondaire (Primaire par défaut). Frais = montant annuel (ex. 300).',
    'Branches : la classe doit exister. Maxima = points d\'une période (10 par défaut) ; l\'examen vaut le double.',
    'Enseignants : téléphone ou e-mail pour qu\'ils puissent se connecter. Classes : noms séparés par « ; ».',
    'Élèves : Sexe M ou F. Date au format 30/11/2015. Matricule vide = numérotation automatique.',
    "Le téléphone du parent sert aux rappels, aux alertes d'absence et à sa connexion par code SMS.",
    'Numéros : format local accepté (ex. 081 234 5678), l\'indicatif de l\'école est ajouté.',
    '',
    'Exemples :',
    'Classes → 5e A | Primaire | 5e année | | 300',
    'Branches → 5e A | Français | 40 |',
    'Enseignants → KASONGO | Marie | 0812345601 | m.kasongo@ecole.cd | Titulaire | 5e A',
    'Élèves → 5e A | MBUYI | Grâce | F | 14/03/2015 | | M. Mbuyi | 0812345678 |',
  ]) {
    aide.appendRow([TextCellValue(l)]);
  }
  aide.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = CellStyle(bold: true, fontSize: 14);
  aide.setColumnWidth(0, 110);

  for (final (nom, cols) in [
    (feuilleClasses, colonnesClasses),
    (feuilleBranches, colonnesBranches),
    (feuilleEnseignants, colonnesEnseignants),
    (feuilleEleves, colonnesEleves),
  ]) {
    final s = x[nom];
    s.appendRow([for (final c in cols) TextCellValue(c)]);
    for (var i = 0; i < cols.length; i++) {
      s.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = gras;
      s.setColumnWidth(i, cols[i].length < 14 ? 16 : cols[i].length + 4.0);
    }
  }
  x.setDefaultSheet("Mode d'emploi");
  x.delete('Sheet1');
  return x.encode()!;
}

// ------------------------------------------------------------------
// Compatibilité des fichiers
// ------------------------------------------------------------------
/// Certains logiciels (bibliothèques Python, exports en ligne…) écrivent des
/// variantes valides du format que la lecture Excel ne gère pas :
/// - chemins internes absolus (`/xl/worksheets/sheet1.xml`) → remis en relatif ;
/// - cases vides marquées « texte » sans contenu (`<c t="inlineStr"/>`) → cases vides.
List<int> normaliserXlsx(List<int> octets) {
  final zip = ZipDecoder().decodeBytes(octets);
  final sortie = Archive();
  var modifie = false;
  final caseVide = RegExp(r'<c ([^>]*?)\s*t="inlineStr"([^>]*?)\s*(/>|></c>)');
  for (final f in zip.files) {
    final rels = f.name == 'xl/_rels/workbook.xml.rels';
    final feuille = f.name.startsWith('xl/worksheets/') && f.name.endsWith('.xml');
    if (f.isFile && (rels || feuille)) {
      final texte = utf8.decode(f.content as List<int>);
      final corrige = rels
          ? texte.replaceAll('Target="/xl/', 'Target="')
          : texte.replaceAllMapped(caseVide, (m) => '<c ${m[1]}${m[2]}/>');
      if (corrige != texte) {
        modifie = true;
        final b = utf8.encode(corrige);
        sortie.addFile(ArchiveFile(f.name, b.length, b));
        continue;
      }
    }
    sortie.addFile(f);
  }
  return modifie ? ZipEncoder().encode(sortie)! : octets;
}

// ------------------------------------------------------------------
// Analyse
// ------------------------------------------------------------------
class ProblemeImport {
  const ProblemeImport(this.feuille, this.ligne, this.message);
  final String feuille;
  final int ligne; // numéro de ligne Excel (1 = en-têtes)
  final String message;
  @override
  String toString() => ligne == 0 ? message : '$feuille, ligne $ligne : $message';
}

class EnseignantImport {
  EnseignantImport(this.enseignant, this.classesNoms, this.identifiants);
  final Enseignant enseignant;
  final List<String> classesNoms;
  final List<String> identifiants;
}

class EleveImport {
  EleveImport(this.eleve, this.classeNom, this.identifiantsParent);
  final Eleve eleve;
  final String classeNom;
  final List<String> identifiantsParent;
}

class PlanImport {
  final classes = <Classe>[]; // nouvelles (id vide)
  final branches = <(String classeNom, Matiere matiere)>[];
  final enseignants = <EnseignantImport>[];
  final eleves = <EleveImport>[];
  final erreurs = <ProblemeImport>[];
  final avertissements = <ProblemeImport>[];

  bool get vide => classes.isEmpty && branches.isEmpty && enseignants.isEmpty && eleves.isEmpty;
  bool get importable => erreurs.isEmpty && !vide;
}

String _cle(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _texte(Data? c) {
  final v = c?.value;
  return switch (v) {
    null => '',
    IntCellValue(:final value) => '$value',
    DoubleCellValue(:final value) => value % 1 == 0 ? value.toInt().toString() : '$value',
    DateCellValue(:final year, :final month, :final day) => '$day/$month/$year',
    DateTimeCellValue(:final year, :final month, :final day) => '$day/$month/$year',
    _ => v.toString().trim(),
  };
}

double? _nombre(String s) => s.isEmpty ? null : double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.'));

DateTime? _date(Data? c) {
  final v = c?.value;
  if (v is DateCellValue) return DateTime(v.year, v.month, v.day);
  if (v is DateTimeCellValue) return DateTime(v.year, v.month, v.day);
  final m = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})$').firstMatch(_texte(c));
  if (m == null) return null;
  final d = DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  return d.day == int.parse(m[1]!) && d.month == int.parse(m[2]!) ? d : null; // refuse 31/02
}

/// Lignes non vides d'une feuille, avec leur numéro Excel (en-têtes exclus).
Iterable<(int, List<Data?>)> _lignes(Excel x, String feuille) sync* {
  final s = x.tables[feuille];
  if (s == null) return;
  for (var i = 1; i < s.rows.length; i++) {
    final r = s.rows[i];
    if (r.every((c) => _texte(c).isEmpty)) continue;
    yield (i + 1, r);
  }
}

Data? _col(List<Data?> r, int i) => i < r.length ? r[i] : null;

PlanImport analyserImport(
  List<int> octets, {
  required List<Classe> classesExistantes,
  required List<Matiere> branchesExistantes,
  required List<Enseignant> enseignantsExistants,
  required List<Eleve> elevesExistants,
  String indicatif = '+243',
}) {
  final plan = PlanImport();
  late final Excel x;
  try {
    x = Excel.decodeBytes(normaliserXlsx(octets));
  } catch (_) {
    plan.erreurs.add(const ProblemeImport('Fichier', 0, "Ce fichier n'est pas un classeur Excel (.xlsx) lisible."));
    return plan;
  }
  if (![feuilleClasses, feuilleBranches, feuilleEnseignants, feuilleEleves].any(x.tables.containsKey)) {
    plan.erreurs.add(const ProblemeImport('Fichier', 0,
        'Aucune feuille Classes, Branches, Enseignants ou Élèves : utilisez le modèle fourni par l\'application.'));
    return plan;
  }
  void err(String f, int l, String m) => plan.erreurs.add(ProblemeImport(f, l, m));
  void avert(String f, int l, String m) => plan.avertissements.add(ProblemeImport(f, l, m));

  // Classes connues (existantes + nouvelles), par nom normalisé.
  final classes = {for (final c in classesExistantes) _cle(c.nom): c.nom};

  // ---- Classes
  for (final (l, r) in _lignes(x, feuilleClasses)) {
    final nom = _texte(_col(r, 0));
    if (nom.isEmpty) {
      err(feuilleClasses, l, 'nom de la classe manquant');
      continue;
    }
    if (classes.containsKey(_cle(nom))) {
      final dejaDansFichier = plan.classes.any((c) => _cle(c.nom) == _cle(nom));
      dejaDansFichier
          ? err(feuilleClasses, l, '« $nom » apparaît deux fois')
          : avert(feuilleClasses, l, '« $nom » existe déjà : elle est conservée telle quelle');
      continue;
    }
    final cycleTexte = _cle(_texte(_col(r, 1)));
    final cycle = cycleTexte.isEmpty
        ? Cycle.primaire
        : Cycle.values.where((c) => _cle(c.label) == cycleTexte || c.name == cycleTexte).firstOrNull;
    if (cycle == null) {
      err(feuilleClasses, l, 'cycle « ${_texte(_col(r, 1))} » inconnu (Maternelle, Primaire ou Secondaire)');
      continue;
    }
    final fraisTexte = _texte(_col(r, 4));
    final frais = fraisTexte.isEmpty ? 0.0 : _nombre(fraisTexte);
    if (frais == null || frais < 0) {
      err(feuilleClasses, l, 'frais « $fraisTexte » invalides');
      continue;
    }
    classes[_cle(nom)] = nom;
    plan.classes.add(Classe(
      id: '',
      nom: nom,
      cycle: cycle,
      niveau: _texte(_col(r, 2)),
      section: cycle == Cycle.secondaire ? _texte(_col(r, 3)) : '',
      fraisScolarite: frais,
    ));
  }

  String? classeConnue(String feuille, int l, String nom) {
    if (nom.isEmpty) {
      err(feuille, l, 'classe manquante');
      return null;
    }
    final c = classes[_cle(nom)];
    if (c == null) err(feuille, l, 'classe « $nom » inconnue (ajoutez-la dans la feuille Classes)');
    return c;
  }

  // ---- Branches
  final idsClassesExistantes = {for (final c in classesExistantes) c.id: _cle(c.nom)};
  final branchesConnues = {
    for (final m in branchesExistantes) '${idsClassesExistantes[m.classeId]}|${_cle(m.nom)}',
  };
  for (final (l, r) in _lignes(x, feuilleBranches)) {
    final classe = classeConnue(feuilleBranches, l, _texte(_col(r, 0)));
    final nom = _texte(_col(r, 1));
    if (nom.isEmpty) err(feuilleBranches, l, 'nom de la branche manquant');
    final maxTexte = _texte(_col(r, 2)), coefTexte = _texte(_col(r, 3));
    final maxima = maxTexte.isEmpty ? 10.0 : _nombre(maxTexte);
    final coef = coefTexte.isEmpty ? 1.0 : _nombre(coefTexte);
    if (maxima == null || maxima <= 0) err(feuilleBranches, l, 'maxima « $maxTexte » invalide');
    if (coef == null || coef <= 0) err(feuilleBranches, l, 'coefficient « $coefTexte » invalide');
    if (classe == null || nom.isEmpty || maxima == null || maxima <= 0 || coef == null || coef <= 0) continue;
    final cle = '${_cle(classe)}|${_cle(nom)}';
    if (branchesConnues.contains(cle)) {
      avert(feuilleBranches, l, '« $nom » existe déjà en $classe : ignorée');
      continue;
    }
    branchesConnues.add(cle);
    plan.branches.add((classe, Matiere(id: '', classeId: '', nom: nom, maxima: maxima, coefficient: coef)));
  }

  // ---- Enseignants
  final enseignantsConnus = {for (final e in enseignantsExistants) _cle('${e.nom} ${e.prenom}')};
  for (final (l, r) in _lignes(x, feuilleEnseignants)) {
    final nom = _texte(_col(r, 0)).toUpperCase(), prenom = _texte(_col(r, 1));
    if (nom.isEmpty || prenom.isEmpty) {
      err(feuilleEnseignants, l, 'nom ou prénom manquant');
      continue;
    }
    final telTexte = _texte(_col(r, 2)), mail = _texte(_col(r, 3)).toLowerCase();
    final tel = telTexte.isEmpty ? null : normaliserTelephone(telTexte, indicatif: indicatif);
    if (telTexte.isNotEmpty && tel == null) err(feuilleEnseignants, l, 'téléphone « $telTexte » invalide');
    if (mail.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      err(feuilleEnseignants, l, 'e-mail « $mail » invalide');
    }
    final noms = _texte(_col(r, 5)).split(RegExp('[;,]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
    final classesEns = <String>[];
    for (final n in noms) {
      final c = classeConnue(feuilleEnseignants, l, n);
      if (c != null) classesEns.add(c);
    }
    if (enseignantsConnus.contains(_cle('$nom $prenom'))) {
      avert(feuilleEnseignants, l, '$prenom $nom existe déjà : ignoré');
      continue;
    }
    enseignantsConnus.add(_cle('$nom $prenom'));
    if (telTexte.isNotEmpty && tel == null) continue;
    plan.enseignants.add(EnseignantImport(
      Enseignant(id: '', nom: nom, prenom: prenom, telephone: telTexte, email: mail, specialite: _texte(_col(r, 4))),
      classesEns,
      [if (mail.isNotEmpty) mail, if (tel != null) tel],
    ));
  }

  // ---- Élèves
  final matricules = {for (final e in elevesExistants) _cle(e.matricule)}..remove('');
  final idsClasses = {for (final c in classesExistantes) c.id: _cle(c.nom)};
  final elevesConnus = {for (final e in elevesExistants) '${idsClasses[e.classeId]}|${_cle(e.nom)}|${_cle(e.prenom)}'};
  for (final (l, r) in _lignes(x, feuilleEleves)) {
    final classe = classeConnue(feuilleEleves, l, _texte(_col(r, 0)));
    final nom = _texte(_col(r, 1)).toUpperCase(), prenom = _texte(_col(r, 2));
    if (nom.isEmpty || prenom.isEmpty) err(feuilleEleves, l, 'nom ou prénom manquant');
    final sexeTexte = _cle(_texte(_col(r, 3)));
    final sexe = switch (sexeTexte) {
      '' || 'm' || 'g' || 'garçon' || 'garcon' || 'masculin' => 'M',
      'f' || 'fille' || 'féminin' || 'feminin' => 'F',
      _ => null,
    };
    if (sexe == null) err(feuilleEleves, l, 'sexe « ${_texte(_col(r, 3))} » : indiquez M ou F');
    final dateTexte = _texte(_col(r, 4));
    final naissance = dateTexte.isEmpty ? null : _date(_col(r, 4));
    if (dateTexte.isNotEmpty && naissance == null) {
      err(feuilleEleves, l, 'date de naissance « $dateTexte » invalide (format 30/11/2015)');
    }
    final matricule = _texte(_col(r, 5));
    if (matricule.isNotEmpty && matricules.contains(_cle(matricule))) {
      err(feuilleEleves, l, 'matricule « $matricule » déjà utilisé');
    }
    final telTexte = _texte(_col(r, 7)), mail = _texte(_col(r, 8)).toLowerCase();
    final tel = telTexte.isEmpty ? null : normaliserTelephone(telTexte, indicatif: indicatif);
    if (telTexte.isNotEmpty && tel == null) err(feuilleEleves, l, 'téléphone du parent « $telTexte » invalide');
    if (mail.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      err(feuilleEleves, l, 'e-mail du parent « $mail » invalide');
    }
    if (classe == null || nom.isEmpty || prenom.isEmpty || sexe == null) continue;
    final cle = '${_cle(classe)}|${_cle(nom)}|${_cle(prenom)}';
    if (elevesConnus.contains(cle)) {
      avert(feuilleEleves, l, '$nom $prenom est déjà inscrit(e) en $classe : ignoré(e)');
      continue;
    }
    elevesConnus.add(cle);
    if (matricule.isNotEmpty) matricules.add(_cle(matricule));
    plan.eleves.add(EleveImport(
      Eleve(
        id: '',
        matricule: matricule,
        nom: nom,
        prenom: prenom,
        classeId: '',
        sexe: sexe,
        dateNaissance: naissance,
        parentNom: _texte(_col(r, 6)),
        parentTelephone: telTexte,
        parentEmail: mail,
      ),
      classe,
      [if (mail.isNotEmpty) mail, if (tel != null) tel],
    ));
  }
  return plan;
}
