import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../app_language.dart';
import '../theme.dart';
import '../widgets/mianara_app_bar.dart';

/// Écran affiché pour toute session dont le rôle n'est pas `candidate`
/// (école, bureau, admin — et un futur espace enseignant). L'application
/// mobile ne couvre pour l'instant que le parcours candidat ; ce n'est pas
/// une erreur de connexion, juste un espace pas encore construit ici.
class StaffPlaceholderScreen extends StatelessWidget {
  const StaffPlaceholderScreen({
    required this.role,
    required this.language,
    required this.onSelectLanguage,
    required this.onLoggedOut,
    super.key,
  });

  final String role;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onSelectLanguage;
  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) => AppLanguageScope(
    language: language,
    child: Scaffold(
      appBar: MianaraAppBar(
        language: language,
        onSelectLanguage: onSelectLanguage,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MianaraColors.sunSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: MianaraColors.sun,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                appText(
                  context,
                  'Espace pas encore disponible sur mobile',
                  'Mbola tsy vita amin\'ny finday ity sehatra ity',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                appText(
                  context,
                  'Votre compte ($role) est bien reconnu, mais l\'application mobile ne couvre pour l\'instant que le parcours candidat.',
                  'Fantatra ny kaontinao ($role), saingy ny lalana mpiadina ihany no efa vita amin\'ity application finday ity ankehitriny.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.instance.logout();
                  onLoggedOut();
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: MianaraColors.danger,
                ),
                label: Text(
                  appText(context, 'Se déconnecter', 'Hivoaka'),
                  style: const TextStyle(color: MianaraColors.danger),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MianaraColors.dangerSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
