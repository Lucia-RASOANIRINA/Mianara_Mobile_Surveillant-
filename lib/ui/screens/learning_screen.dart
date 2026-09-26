import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../app_language.dart';
import '../theme.dart';
import '../widgets/learning_content_section.dart';

const _subjectIcons = {
  'MATH': Icons.functions_rounded,
  'PC': Icons.science_rounded,
  'SVT': Icons.eco_rounded,
  'FRA': Icons.menu_book_rounded,
  'HG': Icons.public_rounded,
  'SES': Icons.insights_rounded,
};

const _subjectColors = {
  'MATH': MianaraColors.green,
  'PC': MianaraColors.info,
  'SVT': MianaraColors.green,
  'FRA': MianaraColors.red,
  'HG': MianaraColors.warning,
  'SES': MianaraColors.sun,
};

class LearningScreen extends StatefulWidget {
  const LearningScreen({required this.onRefresh, super.key});

  final Future<void> Function() onRefresh;

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  String? _selectedSubjectCode;
  String _selectedSubjectFrench = '';
  String _selectedSubjectMalagasy = '';
  bool _saving = false;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  late Future<List<Map<String, Object?>>> _sessions;
  late Future<List<Map<String, Object?>>> _subjectCatalog;

  @override
  void initState() {
    super.initState();
    _sessions = AppDatabase.instance.loadRevisionSessions();
    _subjectCatalog = AppDatabase.instance.loadMobileSubjects();
  }

  @override
  void didUpdateWidget(covariant LearningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subjectCatalog = AppDatabase.instance.loadMobileSubjects();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    final startedAt = DateTime.now();
    setState(() {
      _startedAt = startedAt;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(startedAt));
    });
  }

  Future<void> _saveSession() async {
    final startedAt = _startedAt;
    final subjectCode = _selectedSubjectCode;
    if (startedAt == null || subjectCode == null) return;
    final endedAt = DateTime.now();
    _timer?.cancel();
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.addRevisionSession(
        subjectCode,
        startedAt: startedAt,
        endedAt: endedAt,
      );
      _sessions = AppDatabase.instance.loadRevisionSessions();
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _startedAt = null;
          _elapsed = Duration.zero;
        });
      }
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
          'Apprends une notion, entraîne-toi et avance chaque jour vers ton Baccalauréat.',
          'Mianara, manaova fanazarana ary mandrosoa isan’andro hanatratra ny Bakalaorea.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 18),
      FutureBuilder<List<Map<String, Object?>>>(
        future: _sessions,
        builder: (context, snapshot) {
          final now = DateTime.now();
          final weekStart = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1));
          final weeklySessions =
              snapshot.data
                  ?.where(
                    (session) =>
                        DateTime.parse(session['ended_at']! as String)
                            .isAfter(weekStart),
                  )
                  .length ??
              0;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: MianaraColors.sun,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          appText(
                            context,
                            'Mon objectif cette semaine',
                            'Tanjoko amin’ity herinandro ity',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (weeklySessions / 3).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: MianaraColors.greenSoft,
                    color: MianaraColors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appText(
                      context,
                      '$weeklySessions/3 séances de révision cette semaine',
                      '$weeklySessions/3 famerenana lesona tamin’ity herinandro ity',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      const LearningContentSection(),
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
      FutureBuilder<List<Map<String, Object?>>>(
        future: _subjectCatalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              appText(
                context,
                'Impossible de lire les matières synchronisées.',
                'Tsy afaka mamaky ny taranja nampifandraisina.',
              ),
            );
          }
          final subjects = snapshot.data ?? const [];
          if (subjects.isEmpty) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  appText(
                    context,
                    'Connectez-vous puis synchronisez pour charger les matières officielles de votre série.',
                    'Midira ary ampifandraiso mba hampidirana ny taranja ofisialy amin’ny sokajinao.',
                  ),
                ),
              ),
            );
          }
          final selectedCode =
              subjects.any((subject) => subject['code'] == _selectedSubjectCode)
              ? _selectedSubjectCode!
              : subjects.first['code']! as String;
          if (_selectedSubjectCode != selectedCode) {
            final selected = subjects.firstWhere(
              (subject) => subject['code'] == selectedCode,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _selectedSubjectCode = selectedCode;
                _selectedSubjectFrench = selected['name']! as String;
                _selectedSubjectMalagasy = selected['nameMg']! as String;
              });
            });
          }
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: subjects.map((subject) {
              final code = subject['code']! as String;
              return _SubjectCard(
                code: code,
                label: _subjectLabel(context, subject),
                selected: code == selectedCode,
                onTap: _startedAt == null
                    ? () => setState(() {
                        _selectedSubjectCode = code;
                        _selectedSubjectFrench = subject['name']! as String;
                        _selectedSubjectMalagasy = subject['nameMg']! as String;
                      })
                    : null,
              );
            }).toList(),
          );
        },
      ),
      const SizedBox(height: 22),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                appText(
                  context,
                  'Une séance à la fois',
                  'Indray mandeha isaky ny lesona',
                ),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                appText(
                  context,
                  'Choisissez une matière et lancez une séance. Votre progression est gardée sur cet appareil, même hors ligne.',
                  'Misafidiana taranja ary atombohy ny famerenana. Voatahiry amin’ity fitaovana ity ny fandrosoanao, na tsy misy Internet aza.',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Text(
                _formatDuration(_elapsed),
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : _startedAt == null
                      ? _selectedSubjectCode == null
                            ? null
                            : _startSession
                      : _saveSession,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _startedAt == null
                              ? Icons.play_arrow_rounded
                              : Icons.check_rounded,
                        ),
                  label: Text(
                    appText(
                      context,
                      _startedAt == null
                          ? 'Commencer ${_selectedSubjectLabel()}'
                          : 'Terminer et enregistrer',
                      _startedAt == null
                          ? 'Hanomboka ${_selectedSubjectLabel(malagasy: true)}'
                          : 'Hamarana sy hitahiry',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _selectedSubjectLabel({bool malagasy = false}) {
    return malagasy ? _selectedSubjectMalagasy : _selectedSubjectFrench;
  }

  String _subjectLabel(BuildContext context, Map<String, Object?> subject) =>
      AppLanguageScope.of(context).language == AppLanguage.malagasy
      ? subject['nameMg']! as String
      : subject['name']! as String;
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _subjectColors[code] ?? MianaraColors.green;
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
                  _subjectIcons[code] ?? Icons.menu_book_rounded,
                  color: selected ? Colors.white : tint,
                  size: 26,
                ),
                Text(
                  label,
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
