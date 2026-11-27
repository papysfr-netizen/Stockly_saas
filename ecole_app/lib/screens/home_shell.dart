import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/providers.dart';
import 'classes/classes_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'eleves/eleves_screen.dart';
import 'emploi_du_temps/emploi_du_temps_screen.dart';
import 'enseignants/enseignants_screen.dart';
import 'remplacements/remplacements_screen.dart';
import 'notes/notes_screen.dart';
import 'paiements/paiements_screen.dart';
import 'parents/parent_screen.dart';
import 'presences/presences_screen.dart';
import 'settings/settings_screen.dart';

class _Section {
  const _Section(this.titre, this.icon, this.page);
  final String titre;
  final IconData icon;
  final Widget page;
}

List<_Section> _sectionsPour(AppUser u) => [
      if (u.role != Role.parent && u.role != Role.enseignant)
        const _Section('Tableau de bord', Icons.dashboard_outlined, DashboardScreen()),
      if (u.role == Role.parent) const _Section('Mes enfants', Icons.family_restroom, ParentScreen()),
      if (u.role != Role.parent) const _Section('Élèves', Icons.groups_outlined, ElevesScreen()),
      if (u.role != Role.parent) const _Section('Classes', Icons.class_outlined, ClassesScreen()),
      if (u.canManagePaiements)
        const _Section('Frais de scolarité', Icons.payments_outlined, PaiementsScreen()),
      if (u.canSaisirNotes) const _Section('Notes & bulletins', Icons.grading, NotesScreen()),
      if (u.role != Role.parent)
        const _Section('Emploi du temps', Icons.calendar_view_week_outlined, EmploiDuTempsScreen()),
      if (u.canManageEleves)
        const _Section('Absences & remplacements', Icons.swap_horiz, RemplacementsScreen()),
      if (u.canFairePresences) const _Section('Présences', Icons.fact_check_outlined, PresencesScreen()),
      if (u.isAdmin) const _Section('Enseignants', Icons.co_present_outlined, EnseignantsScreen()),
      const _Section('Paramètres', Icons.settings_outlined, SettingsScreen()),
    ];

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final ecole = ref.watch(ecoleProvider).valueOrNull;
    final sections = _sectionsPour(me);
    final index = _index.clamp(0, sections.length - 1);
    final large = MediaQuery.sizeOf(context).width >= 900;

    final menu = NavigationDrawer(
      selectedIndex: index,
      onDestinationSelected: (i) {
        setState(() => _index = i);
        if (!large) Navigator.pop(context);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 16, 4),
          child: Text(ecole?.nom ?? '', style: Theme.of(context).textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 16, 12),
          child: Text('${me.nom} · ${me.role.label}', style: Theme.of(context).textTheme.bodySmall),
        ),
        for (final s in sections) NavigationDrawerDestination(icon: Icon(s.icon), label: Text(s.titre)),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(sections[index].titre)),
      drawer: large ? null : menu,
      body: large
          ? Row(children: [
              SizedBox(width: 280, child: menu),
              const VerticalDivider(width: 1),
              Expanded(child: sections[index].page),
            ])
          : sections[index].page,
    );
  }
}
