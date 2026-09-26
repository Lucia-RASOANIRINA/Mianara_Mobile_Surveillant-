import 'package:flutter/material.dart';

import '../data/app_database.dart';
import 'app_language.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/visitor_home_screen.dart';
import 'widgets/mianara_app_bar.dart';

/// Espace visiteur : tout ce qui est montré tant qu'aucun compte n'est
/// connecté. Volontairement simple (une seule page de découverte) — aucune
/// donnée personnelle n'est accessible ici, seulement une présentation de ce
/// que propose Mianara et deux façons d'aller plus loin : se connecter ou
/// créer un compte.
class VisitorShell extends StatefulWidget {
  const VisitorShell({required this.onLoggedIn, super.key});

  final VoidCallback onLoggedIn;

  @override
  State<VisitorShell> createState() => _VisitorShellState();
}

class _VisitorShellState extends State<VisitorShell> {
  AppLanguage _language = AppLanguage.french;

  @override
  void initState() {
    super.initState();
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

  // Les routes poussées par le Navigator vivent au-dessus de cet écran : elles
  // n'héritent donc pas d'`AppLanguageScope` et doivent le recevoir ici.
  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => AppLanguageScope(
          language: _language,
          child: RegisterScreen(
            onRegistered: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => AppLanguageScope(
          language: _language,
          child: LoginScreen(
            onLoggedIn: () {
              Navigator.of(routeContext).popUntil((route) => route.isFirst);
              widget.onLoggedIn();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppLanguageScope(
    language: _language,
    child: Scaffold(
      appBar: MianaraAppBar(
        language: _language,
        onSelectLanguage: _setLanguage,
      ),
      body: SafeArea(child: VisitorHomeScreen(onStart: _openRegister)),
      bottomNavigationBar: Builder(
        builder: (context) => Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openLogin,
                      child: Text(appText(context, 'Se connecter', 'Hiditra')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _openRegister,
                      child: Text(
                        appText(context, 'Créer un compte', 'Hamorona kaonty'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
