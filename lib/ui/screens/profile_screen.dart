import 'package:flutter/material.dart';

import '../app_language.dart';
import '../theme.dart';
import '../widgets/candidate_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.onSaved,
    required this.onLogout,
    super.key,
  });

  final Future<void> Function() onSaved;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
    children: [
      Text(
        appText(context, 'Mon profil', 'Ny mombamomba ahy'),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 6),
      Text(
        appText(
          context,
          'Vos informations restent sur cet appareil et peuvent être modifiées.',
          'Voatahiry amin’ity fitaovana ity ny mombamomba anao ary azonao ovaina.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 22),
      CandidateForm(onSaved: onSaved),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded, color: MianaraColors.danger),
        label: Text(
          appText(context, 'Se déconnecter', 'Hivoaka'),
          style: const TextStyle(color: MianaraColors.danger),
        ),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: MianaraColors.dangerSoft)),
      ),
    ],
  );
}
