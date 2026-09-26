import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/candidate.dart';
import 'app_language.dart';
import 'screens/assistant_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dossier_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';
import 'widgets/lamba_stripe.dart';
import 'widgets/mianara_nav_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

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
      ProfileScreen(onSaved: _refresh),
    ];

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppLanguageScope(
      language: _language,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(_appBarHeight + 4),
          child: Column(
            children: [
              Expanded(
                child: AppBar(
                  toolbarHeight: _appBarHeight,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Colors.transparent,
                  titleSpacing: 20,
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/branding/mianara-symbole.png',
                          width: 34,
                          height: 34,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Mianara',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    _LanguageFlags(
                      language: _language,
                      onSelect: _setLanguage,
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              LambaStripe(height: isDark ? 3 : 4),
            ],
          ),
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

const _appBarHeight = 68.0;

class _LanguageFlags extends StatelessWidget {
  const _LanguageFlags({required this.language, required this.onSelect});

  final AppLanguage language;
  final ValueChanged<AppLanguage> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _FlagButton(
        flag: '🇲🇬',
        tooltip: 'Malagasy',
        active: language == AppLanguage.malagasy,
        onTap: () => onSelect(AppLanguage.malagasy),
      ),
      const SizedBox(width: 6),
      _FlagButton(
        flag: '🇫🇷',
        tooltip: 'Français',
        active: language == AppLanguage.french,
        onTap: () => onSelect(AppLanguage.french),
      ),
    ],
  );
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({
    required this.flag,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final String flag;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: active ? 34 : 28,
          height: active ? 34 : 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? green : MianaraColors.lineStrong.withValues(alpha: 0.35),
              width: active ? 2 : 1,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: active ? 1 : 0.45,
            child: Text(flag, style: TextStyle(fontSize: active ? 16 : 13)),
          ),
        ),
      ),
    );
  }
}
