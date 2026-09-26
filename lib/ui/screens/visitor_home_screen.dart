import 'package:flutter/material.dart';

import '../app_language.dart';
import '../theme.dart';

/// Contenu de découverte affiché tant qu'aucun compte n'est connecté :
/// présente ce que propose Mianara sans jamais exposer de données
/// personnelles (dossier, profil, notes, assistant personnel...), qui
/// nécessitent toutes une connexion.
class VisitorHomeScreen extends StatefulWidget {
  const VisitorHomeScreen({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  State<VisitorHomeScreen> createState() => _VisitorHomeScreenState();
}

class _VisitorHomeScreenState extends State<VisitorHomeScreen> {
  final _discoverKey = GlobalKey();

  void _scrollToDiscover() {
    final target = _discoverKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    children: [
      Text(
        appText(
          context,
          'Un accompagnement à chaque étape',
          'Fanampiana amin\'ny dingana rehetra',
        ),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        appText(
          context,
          'Mianara vous accompagne avant, pendant et après vos examens : dossier, révisions et orientation réunis au même endroit.',
          'Manaraka anao i Mianara alohan\'ny, mandritra ny ary aorian\'ny fanadinana: antontan-taratasy, famerenana lesona ary fitarihana miray toerana.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: widget.onStart,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          appText(context, 'Commencer mon parcours', 'Atombohy ny diako'),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _scrollToDiscover,
        icon: const Icon(Icons.explore_outlined),
        label: Text(
          appText(
            context,
            'Découvrir comment ça marche',
            'Fantaro ny fomba fiasany',
          ),
        ),
      ),
      const SizedBox(height: 28),
      KeyedSubtree(
        key: _discoverKey,
        child: _SectionTitle(
          appText(context, 'Découvrir Mianara', 'Fahafantarana an\'i Mianara'),
        ),
      ),
      const SizedBox(height: 10),
      const _JourneySteps(),
      const SizedBox(height: 28),
      _SectionTitle(appText(context, 'Démarches', 'Fikarakarana')),
      const SizedBox(height: 10),
      _PreviewGrid(
        tint: MianaraColors.green,
        tintSoft: MianaraColors.greenSoft,
        items: [
          (
            Icons.school_outlined,
            appText(context, 'Inscription scolaire', 'Fisoratana anarana'),
          ),
          (
            Icons.badge_outlined,
            appText(context, 'Examens nationaux', 'Fanadinam-pirenena'),
          ),
          (
            Icons.emoji_events_outlined,
            appText(context, 'Concours', 'Fifaninanana'),
          ),
          (
            Icons.description_outlined,
            appText(
              context,
              'Documents administratifs',
              'Antontan-taratasy',
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
      _SectionTitle(appText(context, 'Apprendre', 'Mianatra')),
      const SizedBox(height: 10),
      _PreviewGrid(
        tint: MianaraColors.red,
        tintSoft: MianaraColors.redSoft,
        items: [
          (Icons.menu_book_outlined, appText(context, 'Cours', 'Lesona')),
          (
            Icons.auto_stories_outlined,
            appText(context, 'Révisions', 'Famerenana'),
          ),
          (
            Icons.history_edu_outlined,
            appText(context, 'Annales', 'Laza adina'),
          ),
          (
            Icons.sports_esports_outlined,
            appText(context, 'Mini-jeux', 'Lalao kely'),
          ),
        ],
      ),
      const SizedBox(height: 28),
      _SectionTitle(
        appText(context, 'Examens & Concours', 'Fanadinana sy Fifaninanana'),
      ),
      const SizedBox(height: 10),
      _PreviewGrid(
        tint: MianaraColors.sun,
        tintSoft: MianaraColors.sunSoft,
        items: const [
          (Icons.looks_one_outlined, 'CEPE'),
          (Icons.looks_two_outlined, 'BEPC'),
          (Icons.school_outlined, 'Bac'),
          (Icons.account_balance_outlined, 'Concours'),
        ],
      ),
      const SizedBox(height: 28),
      _SectionTitle(appText(context, 'Orientation', 'Fitarihana')),
      const SizedBox(height: 10),
      Text(
        appText(
          context,
          'Après le bac, découvrez les filières possibles selon votre série : économie, informatique, santé, droit, lettres, ingénierie...',
          'Aorian\'ny bakalaorea, fantaro ny sehatra azo idirana araka ny sokajinao: toekarena, informatika, fahasalamana, lalàna, haisoratra, jeniorina...',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 28),
      _SectionTitle(appText(context, 'Assistant', 'Mpanampy')),
      const SizedBox(height: 10),
      Text(
        appText(
          context,
          'Une fois connecté, un assistant répond à vos questions sur votre dossier, votre centre d\'examen et votre orientation.',
          'Rehefa tafiditra, misy mpanampy mamaly ny fanontanianao momba ny antontan-taratasinao, ny foibem-panadinanao ary ny fitarihana anao.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 28),
      _SectionTitle(appText(context, 'Aide', 'Fanampiana')),
      const SizedBox(height: 10),
      _FaqTile(
        question: appText(
          context,
          'Ai-je besoin d\'un compte pour tout voir ?',
          'Mila kaonty ve aho hahitana ny zavatra rehetra?',
        ),
        answer: appText(
          context,
          'Non : vous pouvez découvrir Mianara librement. Un compte n\'est nécessaire que pour accéder à votre dossier, vos révisions et votre assistant personnels.',
          'Tsia: azonao jerena malalaka i Mianara. Ilaina ny kaonty raha te hahazo ny antontan-taratasinao, ny famerenanao lesona ary ny mpanampinao manokana ihany.',
        ),
      ),
      const SizedBox(height: 8),
      _FaqTile(
        question: appText(
          context,
          'Mes données sont-elles en sécurité ?',
          'Voaaro ve ny angoko?',
        ),
        answer: appText(
          context,
          'Vos informations personnelles ne sont accessibles qu\'après connexion à votre compte.',
          'Ny mombamombanao manokana dia azo idirana rehefa tafiditra amin\'ny kaontinao ihany.',
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}

class _JourneySteps extends StatelessWidget {
  const _JourneySteps();

  @override
  Widget build(BuildContext context) {
    final steps = [
      appText(context, 'Avant l\'examen', 'Alohan\'ny fanadinana'),
      appText(context, 'Démarches', 'Fikarakarana'),
      appText(context, 'Préparation', 'Fiomanana'),
      appText(context, 'Jour de l\'examen', 'Andro fanadinana'),
      appText(context, 'Résultats', 'Valiny'),
      appText(context, 'Orientation', 'Fitarihana'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < steps.length; i++)
          Chip(
            label: Text('${i + 1}. ${steps[i]}'),
            backgroundColor: MianaraColors.greenSoft,
            side: BorderSide.none,
            labelStyle: const TextStyle(
              color: MianaraColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({
    required this.tint,
    required this.tintSoft,
    required this.items,
  });

  final Color tint;
  final Color tintSoft;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 2.6,
    children: items
        .map(
          (item) => Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tintSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$1, color: tint, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(answer, style: Theme.of(context).textTheme.bodyMedium)],
    ),
  );
}
