import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/auth_service.dart';
import 'app_language.dart';
import 'app_shell.dart';
import 'screens/staff_placeholder_screen.dart';
import 'visitor_shell.dart';

/// Point d'entrée de l'application : décide, une seule fois au démarrage
/// puis à chaque connexion/déconnexion, lequel de ces trois espaces afficher
/// — visiteur (aucune session), candidat (`AppShell`), ou l'espace des
/// autres rôles (école/bureau/admin — pas encore construit sur mobile).
/// Aucune donnée personnelle ne doit être accessible en dehors du deuxième
/// cas.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

enum _GateState { loading, visitor, candidate, otherRole }

class _RootGateState extends State<RootGate> {
  _GateState _state = _GateState.loading;
  String _role = '';
  AppLanguage _language = AppLanguage.french;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final language = await AppDatabase.instance.loadAppLanguage();
    final session = await AuthService.instance.restore();
    if (!mounted) return;
    setState(() {
      _language = language == 'mg' ? AppLanguage.malagasy : AppLanguage.french;
      if (session == null) {
        _state = _GateState.visitor;
      } else if (session.isCandidate) {
        _state = _GateState.candidate;
      } else {
        _role = session.role;
        _state = _GateState.otherRole;
      }
    });
  }

  Future<void> _setLanguage(AppLanguage language) async {
    await AppDatabase.instance.saveAppLanguage(
      language == AppLanguage.malagasy ? 'mg' : 'fr',
    );
    if (mounted) setState(() => _language = language);
  }

  void _onLoggedIn() {
    final session = AuthService.instance.session;
    setState(() {
      if (session != null && session.isCandidate) {
        _state = _GateState.candidate;
      } else if (session != null) {
        _role = session.role;
        _state = _GateState.otherRole;
      }
    });
  }

  void _onLoggedOut() {
    setState(() => _state = _GateState.visitor);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _GateState.visitor:
        return VisitorShell(onLoggedIn: _onLoggedIn);
      case _GateState.candidate:
        return const AppShell();
      case _GateState.otherRole:
        return StaffPlaceholderScreen(
          role: _role,
          language: _language,
          onSelectLanguage: _setLanguage,
          onLoggedOut: _onLoggedOut,
        );
    }
  }
}
