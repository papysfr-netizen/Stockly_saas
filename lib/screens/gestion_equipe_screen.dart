import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/user_role_provider.dart';
import '../core/services/equipe_service.dart';

/// Membres de la boutique (collection users, même entrepriseId)
final membresEquipeProvider = StreamProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .where('entrepriseId', isEqualTo: entrepriseId)
      .snapshots()
      .map((s) => s.docs);
});

class GestionEquipeScreen extends ConsumerWidget {
  const GestionEquipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Gestion de l\'Équipe')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Gestion de l\'Équipe')),
        body: Center(child: Text('Erreur : $err')),
      ),
      data: (profile) {
        final entrepriseId = profile.entrepriseId;

        if (!profile.role.peutGererEquipe) {
          return Scaffold(
            appBar: AppBar(title: const Text('Gestion de l\'Équipe')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Accès réservé au propriétaire de la boutique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }

        final membresAsync = ref.watch(membresEquipeProvider(entrepriseId));

        return Scaffold(
          appBar: AppBar(title: const Text('Gestion de l\'Équipe')),
          body: membresAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur : $err', textAlign: TextAlign.center),
              ),
            ),
            data: (docs) {
              // Le propriétaire en premier, puis les membres par nom
              final membres = [...docs]..sort((a, b) {
                  final ra = a.data()['role'] == 'owner' ? 0 : 1;
                  final rb = b.data()['role'] == 'owner' ? 0 : 1;
                  if (ra != rb) return ra - rb;
                  return (a.data()['nom'] ?? '').toString().compareTo((b.data()['nom'] ?? '').toString());
                });

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  if (membres.length <= 1)
                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucun employé pour l\'instant.\n'
                          'Appuyez sur « Nouveau membre » pour créer le compte d\'un caissier ou d\'un gérant.',
                        ),
                      ),
                    ),
                  ...membres.map((doc) => _CarteMembre(
                        doc: doc,
                        estMoi: doc.id == profile.uid,
                      )),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Nouveau membre'),
            onPressed: () => _ouvrirCreation(context, entrepriseId),
          ),
        );
      },
    );
  }

  Future<void> _ouvrirCreation(BuildContext context, String entrepriseId) async {
    final login = await showDialog<_CompteCree>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogueCreation(entrepriseId: entrepriseId),
    );
    if (login == null || !context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green.shade700, size: 40),
        title: const Text('Compte créé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donnez ces informations à ${login.nom} :'),
            const SizedBox(height: 16),
            const Text('Identifiant', style: TextStyle(color: Colors.grey)),
            SelectableText(
              login.login,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Mot de passe', style: TextStyle(color: Colors.grey)),
            SelectableText(
              login.motDePasse,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notez-les maintenant : le mot de passe ne sera plus affiché.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copier'),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Stockly\nIdentifiant : ${login.login}\nMot de passe : ${login.motDePasse}',
              ));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Copié !')),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CompteCree {
  final String nom;
  final String login;
  final String motDePasse;
  const _CompteCree(this.nom, this.login, this.motDePasse);
}

// ======================= FENÊTRE DE CRÉATION =======================
class _DialogueCreation extends StatefulWidget {
  final String entrepriseId;
  const _DialogueCreation({required this.entrepriseId});

  @override
  State<_DialogueCreation> createState() => _DialogueCreationState();
}

class _DialogueCreationState extends State<_DialogueCreation> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  String _role = 'caissier';
  bool _voirMotDePasse = false;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final login = await EquipeService.creerMembre(
        entrepriseId: widget.entrepriseId,
        nom: _nom.text,
        identifiant: _identifiant.text,
        motDePasse: _motDePasse.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.pop(context, _CompteCree(_nom.text.trim(), login, _motDePasse.text));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apercu = EquipeService.nettoyer(_identifiant.text).isEmpty
        ? '…'
        : EquipeService.loginPour(_identifiant.text, widget.entrepriseId);

    return AlertDialog(
      title: const Text('Nouveau membre'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _identifiant,
                decoration: InputDecoration(
                  labelText: 'Identifiant (ex : grace)',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  helperText: 'Connexion : $apercu',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = EquipeService.nettoyer(v ?? '');
                  if (n.length < 3) return '3 lettres ou chiffres minimum';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motDePasse,
                obscureText: !_voirMotDePasse,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_voirMotDePasse ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _voirMotDePasse = !_voirMotDePasse),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'caissier', child: Text('Caissier')),
                  DropdownMenuItem(value: 'gerant', child: Text('Gérant')),
                ],
                onChanged: _enCours ? null : (v) => setState(() => _role = v ?? 'caissier'),
              ),
              const SizedBox(height: 8),
              Text(
                _role == 'gerant'
                    ? 'Un gérant a toutes les autorisations par défaut. Vous pourrez en retirer ensuite.'
                    : 'Un caissier n\'a aucune autorisation spéciale par défaut. Vous pourrez en donner ensuite.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enCours ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _enCours ? null : _creer,
          child: _enCours
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Créer le compte'),
        ),
      ],
    );
  }
}

// ======================= CARTE D'UN MEMBRE =======================
class _CarteMembre extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool estMoi;
  const _CarteMembre({required this.doc, required this.estMoi});

  static const Map<String, IconData> _icones = {
    Permissions.voirFinances: Icons.bar_chart,
    Permissions.retours: Icons.assignment_return,
    Permissions.gererStock: Icons.inventory_2_outlined,
    Permissions.remisesRetraits: Icons.price_change_outlined,
    Permissions.maintenance: Icons.cleaning_services_outlined,
  };

  Future<void> _action(BuildContext context, Future<void> Function() action, String succes) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(succes), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }

  /// Valeur actuelle d'une autorisation : choix du patron, sinon valeur par défaut du rôle.
  /// L'ancien interrupteur « remises » (canGiveDiscount) compte pour « Remises et retraits ».
  bool _valeur(Map<String, dynamic> permissions, String cle, UserRole role) {
    final v = permissions[cle];
    if (v is bool) return v;
    if (cle == Permissions.remisesRetraits && permissions['canGiveDiscount'] == true) {
      return true;
    }
    return UserProfile.valeurParDefaut(role, cle);
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final nom = (data['nom'] ?? 'Sans nom').toString();
    final role = UserRole.fromString(data['role']?.toString());
    final login = (data['identifiant'] ?? data['email'] ?? '').toString();
    final actif = data['estActif'] as bool? ?? true;
    final permissions = (data['permissions'] as Map<String, dynamic>?) ?? {};

    final couleur = role.isOwner
        ? Colors.amber.shade700
        : (role.isGerant ? Colors.indigo : Colors.teal);

    final nbAutorisees =
        Permissions.toutes.where((cle) => _valeur(permissions, cle, role)).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: actif ? couleur : Colors.grey,
                  child: Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estMoi ? '$nom (vous)' : nom,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (login.isNotEmpty)
                        Text(login, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(role.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: actif ? couleur : Colors.grey,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (role.isOwner)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Le propriétaire a tous les droits.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              )
            else ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Text('Rôle :'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: role.isGerant ? 'gerant' : 'caissier',
                    items: const [
                      DropdownMenuItem(value: 'caissier', child: Text('Caissier')),
                      DropdownMenuItem(value: 'gerant', child: Text('Gérant')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      _action(context, () => EquipeService.changerRole(doc.id, v), 'Rôle modifié');
                    },
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Compte actif'),
                subtitle: Text(actif ? 'Peut se connecter' : 'Désactivé : ne peut plus travailler'),
                value: actif,
                onChanged: (v) => _action(
                  context,
                  () => EquipeService.changerActif(doc.id, v),
                  v ? 'Compte réactivé' : 'Compte désactivé',
                ),
              ),

              // 🔐 AUTORISATIONS
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  leading: Icon(Icons.verified_user_outlined, color: couleur),
                  title: Text(
                    'Autorisations ($nbAutorisees/${Permissions.toutes.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    role.isGerant
                        ? 'Par défaut pour un gérant : tout est autorisé'
                        : 'Par défaut pour un caissier : rien de spécial',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  children: [
                    for (final cle in Permissions.toutes)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        secondary: Icon(_icones[cle], size: 22),
                        title: Text(Permissions.titres[cle] ?? cle),
                        subtitle: Text(
                          Permissions.descriptions[cle] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _valeur(permissions, cle, role),
                        onChanged: (v) => _action(
                          context,
                          () => EquipeService.changerPermission(doc.id, cle, v),
                          v
                              ? '« ${Permissions.titres[cle]} » autorisé pour $nom'
                              : '« ${Permissions.titres[cle]} » retiré à $nom',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
