import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/auth_service.dart';
import '../models/candidate.dart';
import 'app_language.dart';
import 'screens/assistant_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dossier_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/mianara_app_bar.dart';
import 'widgets/mianara_nav_bar.dart';

/// Espace candidat, accessible uniquement une fois connecté (voir
/// `RootGate`). Rien ici ne devrait pouvoir s'afficher sans une session
/// active — c'est `RootGate` qui en est le garant, pas cet écran.
class AppShell extends StatefulWidget {
  const AppShell({required this.onLoggedOut, super.key});

  final VoidCallback onLoggedOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  Candidate? _candidate;
  AppLanguage _language = AppLanguage.french;

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await AppDatabase.instance.loadAppLanguage();
    if (!mounted) return;
    setState(() {
      _language = language == 'mg' ? AppLanguage.malagasy : AppLanguage.french;
    });
  }

  Future<void> _setLanguage(AppLanguage language) async {
    if (language == _language) return;
    await AppDatabase.instance.saveAppLanguage(
      language == AppLanguage.malagasy ? 'mg' : 'fr',
    );
    if (mounted) setState(() => _language = language);
  }

  Future<void> _refresh() async {
    final candidate = await AppDatabase.instance.loadCandidate();
    if (!mounted) return;
    setState(() => _candidate = candidate);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        candidate: _candidate,
        onOpenProfile: () => setState(() => _selectedIndex = 4),
        onOpenDossier: () => setState(() => _selectedIndex = 2),
        onRefresh: _refresh,
      ),
      AssistantScreen(candidate: _candidate),
      DossierScreen(candidate: _candidate, onRefresh: _refresh),
      LearningScreen(onRefresh: _refresh),
      ProfileScreen(onSaved: _refresh, onLogout: _logout),
    ];

    return AppLanguageScope(
      language: _language,
      child: Scaffold(
        appBar: MianaraAppBar(
          language: _language,
          onSelectLanguage: _setLanguage,
        ),
        body: SafeArea(child: pages[_selectedIndex]),
        bottomNavigationBar: MianaraNavBar(
          selectedIndex: _selectedIndex,
          onSelect: (index) {
            setState(() => _selectedIndex = index);
            _refresh();
          },
          items: [
            MianaraNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: _language == AppLanguage.malagasy
                  ? 'Fandraisana'
                  : 'Accueil',
            ),
            MianaraNavItem(
              icon: Icons.smart_toy_outlined,
              selectedIcon: Icons.smart_toy_rounded,
              label: _language == AppLanguage.malagasy
                  ? 'Mpanampy'
                  : 'Assistant',
            ),
            MianaraNavItem(
              icon: Icons.folder_outlined,
              selectedIcon: Icons.folder,
              label: _language == AppLanguage.malagasy
                  ? 'Antontan-taratasy'
                  : 'Dossier',
            ),
            MianaraNavItem(
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              label: _language == AppLanguage.malagasy
                  ? 'Mianatra'
                  : 'Apprendre',
            ),
            MianaraNavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: _language == AppLanguage.malagasy
                  ? 'Mombamomba'
                  : 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
