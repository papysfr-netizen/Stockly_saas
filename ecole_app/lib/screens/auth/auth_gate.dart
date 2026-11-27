import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../home_shell.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final profil = ref.watch(currentUserProvider);
    const loading = Scaffold(body: Center(child: CircularProgressIndicator()));

    if (auth.isLoading) return loading;
    if (auth.valueOrNull == null) return const LoginScreen();
    return profil.when(
      loading: () => loading,
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
      data: (u) {
        // Juste après l'inscription, le profil peut mettre un instant à apparaître.
        if (u == null) return loading;
        return const HomeShell();
      },
    );
  }
}
