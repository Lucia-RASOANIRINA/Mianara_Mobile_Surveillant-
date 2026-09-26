import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../app_language.dart';
import '../theme.dart';

const _subjects = [
  'Mathématiques',
  'Physique',
  'Français',
  'Histoire',
  'Géographie',
];

const _subjectIcons = {
  'Mathématiques': Icons.functions_rounded,
  'Physique': Icons.science_rounded,
  'Français': Icons.menu_book_rounded,
  'Histoire': Icons.hourglass_bottom_rounded,
  'Géographie': Icons.public_rounded,
};

const _subjectColors = {
  'Mathématiques': MianaraColors.green,
  'Physique': MianaraColors.info,
  'Français': MianaraColors.red,
  'Histoire': MianaraColors.warning,
  'Géographie': MianaraColors.sun,
};

class LearningScreen extends StatefulWidget {
  const LearningScreen({required this.onRefresh, super.key});

  final Future<void> Function() onRefresh;

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  String _selectedSubject = _subjects.first;
  bool _saving = false;

  Future<void> _saveSession() async {
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.addRevisionSession(_selectedSubject);
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appText(
            context,
            'Session de révision enregistrée sur cet appareil.',
            'Voatahiry amin’ity fitaovana ity ny famerenana lesona.',
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MianaraRadii.md),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
    children: [
      Text(
        appText(context, 'Apprendre', 'Mianatra'),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 6),
      Text(
        appText(
          context,
          'Cours, exercices et annales seront disponibles hors ligne après leur synchronisation.',
          'Ho azo ampiasaina tsy misy Internet ny lesona, fanazaran-tena ary laza adina rehefa vita ny fampifandraisana.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MianaraColors.infoSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.download_for_offline_rounded,
                  color: MianaraColors.info,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  appText(
                    context,
                    'Aucun contenu pédagogique n’est installé pour le moment. Le catalogue sera alimenté à partir des cours et annales officiels.',
                    'Mbola tsy misy lesona napetraka. Hofenoina amin’ny lesona sy laza adina ofisialy ny tahiry.',
                  ),
                  style: const TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),
      Text(
        appText(context, 'Mes matières', 'Ny taranjako'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        appText(
          context,
          'Choisissez une matière pour enregistrer une session de révision.',
          'Safidio ny taranja hitahirizana famerenana lesona.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: _subjects
            .map(
              (subject) => _SubjectCard(
                subject: subject,
                selected: subject == _selectedSubject,
                onTap: () => setState(() => _selectedSubject = subject),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 22),
      FilledButton.icon(
        onPressed: _saving ? null : _saveSession,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_rounded),
        label: Text(
          appText(
            context,
            'Enregistrer ma révision de ${localizedSubject(context, _selectedSubject)}',
            'Hitahiry ny famerenana ${localizedSubject(context, _selectedSubject)}',
          ),
        ),
      ),
    ],
  );
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final String subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _subjectColors[subject] ?? MianaraColors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? tint : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(MianaraRadii.lg),
        border: Border.all(
          color: selected ? tint : (Theme.of(context).dividerColor),
          width: selected ? 0 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(MianaraRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _subjectIcons[subject] ?? Icons.menu_book_rounded,
                  color: selected ? Colors.white : tint,
                  size: 26,
                ),
                Text(
                  localizedSubject(context, subject),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
