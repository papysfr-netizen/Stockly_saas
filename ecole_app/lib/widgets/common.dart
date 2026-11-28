import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche le contenu d'un AsyncValue avec chargement et erreur.
class AsyncView<T> extends StatelessWidget {
  const AsyncView(this.value, this.builder, {super.key});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
        data: builder,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur : $e', textAlign: TextAlign.center),
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ]),
        ),
      );
}

void showMessage(BuildContext context, String msg, {bool erreur = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: erreur ? Theme.of(context).colorScheme.error : null,
  ));
}

Future<bool> confirmer(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmer')),
        ],
      ),
    ) ??
    false;

/// Exécute une action asynchrone et affiche l'erreur éventuelle.
Future<bool> run(BuildContext context, Future<void> Function() action, {String? succes}) async {
  try {
    await action();
    if (context.mounted && succes != null) showMessage(context, succes);
    return true;
  } catch (e) {
    if (context.mounted) showMessage(context, 'Erreur : $e', erreur: true);
    return false;
  }
}

String? requis(String? v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.titre, required this.valeur, required this.icon, this.couleur});
  final String titre;
  final String valeur;
  final IconData icon;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final c = couleur ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(backgroundColor: c.withValues(alpha: 0.15), child: Icon(icon, color: c)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titre, style: Theme.of(context).textTheme.bodySmall),
              Text(valeur, style: Theme.of(context).textTheme.titleLarge),
            ]),
          ),
        ]),
      ),
    );
  }
}
