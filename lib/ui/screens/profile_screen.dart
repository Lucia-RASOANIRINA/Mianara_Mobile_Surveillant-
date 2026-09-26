import 'package:flutter/material.dart';

import '../app_language.dart';
import '../widgets/candidate_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.onSaved, super.key});

  final Future<void> Function() onSaved;

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
    ],
  );
}
