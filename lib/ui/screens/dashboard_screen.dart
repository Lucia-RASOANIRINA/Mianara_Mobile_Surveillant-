import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/candidate.dart';
import '../app_language.dart';
import '../theme.dart';
import '../widgets/fade_slide_in.dart';

const _heroDelay = Duration.zero;
const _promptDelay = Duration(milliseconds: 60);
const _metricsDelay = Duration(milliseconds: 120);
const _parcoursDelay = Duration(milliseconds: 180);
const _revisionsDelay = Duration(milliseconds: 240);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.candidate,
    required this.onOpenProfile,
    required this.onOpenDossier,
    required this.onRefresh,
    super.key,
  });

  final Candidate? candidate;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenDossier;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: Future.wait([
      AppDatabase.instance.loadDossierItems(),
      AppDatabase.instance.loadRevisionSessions(),
    ]),
    builder: (context, snapshot) {
      final items = snapshot.data?[0] ?? <Map<String, Object?>>[];
      final sessions = snapshot.data?[1] ?? <Map<String, Object?>>[];
      final completeItems = items
          .where((item) => item['is_complete'] == 1)
          .length;

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              _greeting(context),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 2),
            Text(
              candidate?.fullName.isNotEmpty == true
                  ? candidate!.fullName
                  : appText(
                      context,
                      'Bienvenue sur Mianara',
                      'Tongasoa eto Mianara',
                    ),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: _heroDelay,
              child: _HeroCard(candidate: candidate),
            ),
            const SizedBox(height: 18),
            if (candidate == null)
              FadeSlideIn(
                delay: _promptDelay,
                child: _ProfilePrompt(onTap: onOpenProfile),
              ),
            if (candidate == null) const SizedBox(height: 18),
            FadeSlideIn(
              delay: _metricsDelay,
              child: Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: appText(
                        context,
                        'Pièces prêtes',
                        'Antontan-taratasy vonona',
                      ),
                      value: '$completeItems/${items.length}',
                      icon: Icons.folder_open_rounded,
                      tint: MianaraColors.green,
                      tintSoft: MianaraColors.greenSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: appText(
                        context,
                        'Révisions',
                        'Famerenana lesona',
                      ),
                      value: '${sessions.length}',
                      icon: Icons.auto_stories_rounded,
                      tint: MianaraColors.red,
                      tintSoft: MianaraColors.redSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: _parcoursDelay,
              child: Text(
                appText(context, 'Votre parcours', 'Ny lalanao'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: _parcoursDelay,
              child: _ActionTile(
                icon: Icons.folder_copy_rounded,
                tint: MianaraColors.green,
                tintSoft: MianaraColors.greenSoft,
                title: appText(
                  context,
                  'Suivre mon dossier',
                  'Hanaraka ny antontan-taratasiko',
                ),
                subtitle: appText(
                  context,
                  'Checklist et état des pièces',
                  'Lisitra sy satan’ny antontan-taratasy',
                ),
                onTap: onOpenDossier,
              ),
            ),
            const SizedBox(height: 10),
            FadeSlideIn(
              delay: _parcoursDelay,
              child: _ActionTile(
                icon: Icons.person_rounded,
                tint: MianaraColors.sun,
                tintSoft: MianaraColors.sunSoft,
                title: appText(
                  context,
                  'Compléter mon profil',
                  'Hameno ny mombamomba ahy',
                ),
                subtitle: appText(
                  context,
                  'Informations candidat et examen',
                  'Mombamomba ny mpiadina sy ny fanadinana',
                ),
                onTap: onOpenProfile,
              ),
            ),
            const SizedBox(height: 26),
            FadeSlideIn(
              delay: _revisionsDelay,
              child: Text(
                appText(
                  context,
                  'Dernières révisions',
                  'Famerenana lesona farany',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              FadeSlideIn(
                delay: _revisionsDelay,
                child: _EmptyCard(
                  icon: Icons.menu_book_outlined,
                  text: appText(
                    context,
                    'Vos sessions de révision apparaîtront ici.',
                    'Hiseho eto ny famerenana lesona nataonao.',
                  ),
                ),
              )
            else
              ...sessions.take(3).toList().asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FadeSlideIn(
                    delay:
                        _revisionsDelay + Duration(milliseconds: 40 * entry.key),
                    child: _ActionTile(
                      icon: Icons.check_circle_rounded,
                      tint: MianaraColors.green,
                      tintSoft: MianaraColors.greenSoft,
                      title: localizedSubject(
                        context,
                        entry.value['subject']! as String,
                      ),
                      subtitle: _formatDate(
                        entry.value['ended_at']! as String,
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final base = hour < 12
        ? appText(context, 'Bonjour', 'Manao ahoana')
        : hour < 18
        ? appText(context, 'Bon après-midi', 'Manao ahoana · tolakandro')
        : appText(context, 'Bonsoir', 'Manao ahoana · hariva');
    return base.toUpperCase();
  }

  String _formatDate(String value) {
    final date = DateTime.parse(value).toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.candidate});

  final Candidate? candidate;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Candidate? get candidate => widget.candidate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? MianaraGradients.heroDark : MianaraGradients.hero,
        borderRadius: BorderRadius.circular(MianaraRadii.xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.scale(
                scale: 1 + _controller.value * 0.08,
                child: child,
              ),
              child: Icon(
                Icons.eco_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate == null
                            ? appText(
                                context,
                                'Votre parcours vers l\'examen',
                                'Ny dianao mankany amin\'ny fanadinana',
                              )
                            : (candidate!.examType == 'Baccalauréat'
                                  ? appText(context, 'Baccalauréat', 'Bakalaorea')
                                  : candidate!.examType),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        candidate == null
                            ? appText(
                                context,
                                'Dossier, révisions et assistance réunis pour vous accompagner jusqu\'au jour J.',
                                'Antontan-taratasy, famerenana lesona ary fanampiana miray hanaraka anao hatramin\'ny andro lehibe.',
                              )
                            : [
                                if (candidate!.examSeries.isNotEmpty)
                                  appText(
                                    context,
                                    'Série ${candidate!.examSeries}',
                                    'Sokajy ${candidate!.examSeries}',
                                  ),
                                if (candidate!.examCenter.isNotEmpty)
                                  candidate!.examCenter,
                                candidate!.candidateStatus == 'Scolaire'
                                    ? appText(context, 'Scolaire', 'Mpianatra')
                                    : appText(
                                        context,
                                        'Candidat libre',
                                        'Mpiadina afaka',
                                      ),
                              ].join(' · '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MianaraColors.sunSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: MianaraColors.sun,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            appText(
              context,
              'Commencez par votre profil',
              'Atombohy amin’ny mombamomba anao',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            appText(
              context,
              'Ajoutez vos informations de candidat pour préparer votre dossier.',
              'Ampidiro ny mombamomba anao amin’ny maha-mpiadina anao hanomanana ny antontan-taratasinao.',
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              appText(
                context,
                'Créer mon profil',
                'Hamorona ny mombamomba ahy',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.tintSoft,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color tintSoft;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tintSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.tint,
    required this.tintSoft,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color tintSoft;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tintSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: MianaraColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}
