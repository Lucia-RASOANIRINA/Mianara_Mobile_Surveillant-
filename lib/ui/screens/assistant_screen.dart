import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/candidate.dart';
import '../app_language.dart';
import '../theme.dart';

/// Assistant administratif local : répond à un petit nombre de questions
/// courantes à partir des données déjà enregistrées sur l'appareil (profil,
/// checklist). Il ne s'agit pas d'un modèle de langage : les réponses sont
/// construites par des règles simples, sans connexion réseau.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({required this.candidate, super.key});

  final Candidate? candidate;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _Message {
  const _Message({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  bool _thinking = false;
  bool _greeted = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ensureGreeting(BuildContext context) {
    if (_greeted) return;
    _greeted = true;
    _messages.add(
      _Message(
        isUser: false,
        text: appText(
          context,
          'Bonjour ! Je peux répondre à quelques questions sur votre dossier : les pièces à fournir, votre centre d’examen ou les délais. Réponses locales, sans connexion.',
          'Manao ahoana! Afaka mamaly fanontaniana vitsivitsy momba ny antontan-taratasinao aho: ny antontan-taratasy ilaina, ny foibem-panadinana na ny fe-potoana. Valiny eto an-toerana, tsy misy Internet.',
        ),
      ),
    );
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    _controller.clear();
    setState(() {
      _messages.add(_Message(isUser: true, text: text));
      _thinking = true;
    });
    _scrollToEnd();

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final q = text.toLowerCase();
    bool has(List<String> words) => words.any(q.contains);
    final String answer;
    if (has([
      'pièce',
      'piece',
      'document',
      'fournir',
      'dossier',
      'antontan-taratasy',
      'antontan taratasy',
      'taratasy',
    ])) {
      answer = await _dossierAnswer();
    } else if (has(['centre', 'lieu', 'adresse', 'foibe'])) {
      answer = _centerAnswer(context);
    } else if (has([
      'date',
      'délai',
      'delai',
      'limite',
      'échéance',
      'echeance',
      'daty',
      'fe-potoana',
      'fe potoana',
      'fetra',
    ])) {
      answer = appText(
        context,
        'Les dates limites officielles ne sont pas encore disponibles ici : elles s’afficheront dès que la plateforme sera connectée au calendrier du ministère.',
        'Mbola tsy azo atao eto ny daty fara-fetiny ofisialy: hiseho izy io rehefa mifandray amin’ny fandaharam-potoan’ny ministera ny sehatra.',
      );
    } else if (has(['malagasy', 'teny'])) {
      answer = appText(
        context,
        'Je peux déjà répondre en malagasy, comme maintenant. L’explication des cours dans les deux langues arrivera avec le module pédagogique.',
        'Afaka mamaly amin’ny teny malagasy toy izao aho. Ho tonga miaraka amin’ny sehatra fanabeazana ny fanazavan-desona amin’ny fiteny roa.',
      );
    } else if (has([
      'orientation',
      'après le bac',
      'apres le bac',
      'concours',
      'fonction publique',
      'université',
      'universite',
      'école publique',
      'ecole publique',
      'taorian',
      'fifaninanana',
    ])) {
      answer = _orientationAnswer(context);
    } else {
      answer = appText(
        context,
        'Je ne suis pas encore certain de la réponse. Cette version locale connaît seulement les questions sur les pièces du dossier, le centre d’examen et les délais.',
        'Mbola tsy azoko antoka ny valiny. Ity dikany eto an-toerana ity dia mahafantatra fotsiny ny fanontaniana momba ny antontan-taratasy, ny foibem-panadinana ary ny fe-potoana.',
      );
    }

    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages.add(_Message(isUser: false, text: answer));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _dossierAnswer() async {
    if (widget.candidate == null) {
      return appText(
        context,
        'Complétez d’abord votre profil dans l’onglet Dossier : je pourrai ensuite générer votre liste de pièces.',
        'Fenoy aloha ny mombamombanao ao amin’ny Antontan-taratasy: afaka hamorona ny lisitry ny antontan-taratasy ilaina aho avy eo.',
      );
    }
    final items = await AppDatabase.instance.loadDossierItems();
    if (!mounted) return '';
    if (items.isEmpty) {
      return appText(
        context,
        'Aucune pièce n’est encore définie pour votre profil actuel.',
        'Mbola tsy misy antontan-taratasy voafaritra ho an’ny mombamombanao ankehitriny.',
      );
    }
    final missing = items
        .where((item) => item['is_complete'] != 1)
        .map(
          (item) => localizedRequirementLabel(
            context,
            item['id']! as String,
            item['label']! as String,
          ),
        )
        .toList();
    if (missing.isEmpty) {
      return appText(
        context,
        'D’après votre dossier, toutes les pièces sont déjà marquées comme prêtes !',
        'Araka ny antontan-taratasinao, vonona daholo ny antontan-taratasy!',
      );
    }
    final list = missing.map((label) => '• $label').join('\n');
    return appText(
      context,
      'D’après votre dossier, il reste à fournir :\n$list',
      'Araka ny antontan-taratasinao, mbola ilaina:\n$list',
    );
  }

  String _centerAnswer(BuildContext context) {
    final center = widget.candidate?.examCenter ?? '';
    if (center.isEmpty) {
      return appText(
        context,
        'Aucun centre d’examen n’est renseigné dans votre profil pour le moment.',
        'Tsy mbola misy foibem-panadinana voarakitra ao amin’ny mombamombanao.',
      );
    }
    return appText(
      context,
      'Votre centre d’examen enregistré est : $center. L’itinéraire et les horaires seront ajoutés une fois la plateforme connectée aux données officielles.',
      'Ny foibem-panadinana voarakitra ao aminao dia: $center. Hampidirina ny lalana sy ny ora rehefa mifandray amin’ny angona ofisialy ny sehatra.',
    );
  }

  String _orientationAnswer(BuildContext context) {
    final series = widget.candidate?.examSeries ?? '';
    String tip = '';
    if (['S', 'C', 'D'].contains(series)) {
      tip = appText(
        context,
        ' Avec une série scientifique, les concours à dominante scientifique, technique ou de santé sont souvent accessibles.',
        ' Amin’ny sokajy siantifika, matetika azo idirana ny fifaninanana miompana amin’ny siansa, ny teknika na ny fahasalamana.',
      );
    } else if (series == 'OSE') {
      tip = appText(
        context,
        ' Avec la série OSE, les concours à dominante économique, gestion ou administrative sont souvent accessibles.',
        ' Amin’ny sokajy OSE, matetika azo idirana ny fifaninanana miompana amin’ny toekarena, ny fitantanana na ny fitantanam-panjakana.',
      );
    } else if (['L', 'A'].contains(series)) {
      tip = appText(
        context,
        ' Avec une série littéraire, les concours à dominante littéraire, juridique ou administrative sont souvent accessibles.',
        ' Amin’ny sokajy haisoratra, matetika azo idirana ny fifaninanana miompana amin’ny haisoratra, ny lalàna na ny fitantanam-panjakana.',
      );
    }

    return appText(
      context,
      'La plupart des concours de la fonction publique malgache demandent le Baccalauréat comme diplôme minimum ; ils sont organisés par le Ministère de la Fonction Publique avec des comités par secteur selon le ministère concerné. Quelques exemples accessibles dès le bac : écoles militaires ou de police, École Nationale de l’Enseignement Maritime, instituts universitaires publics recrutant sur concours. Attention : certaines grandes écoles comme l’ENAM demandent un niveau bac+4, pas un accès direct après le bac.$tip Les dates d’ouverture changent souvent — les concours ont par exemple été suspendus en 2025 pour être réorganisés — donc vérifiez toujours l’annonce officielle du ministère concerné avant de vous engager. Je peux vous expliquer les possibilités, mais le choix final vous appartient.',
      'Ny ankamaroan’ny fifaninanana ho amin’ny fanompoana miankina amin’ny fanjakana dia mangataka ny Bakalaorea ho mari-pahaizana farany ambany; ny Ministeran’ny Fanompoana Miankina amin’ny Fanjakana no mandrindra izany, miaraka amin’ny vaomiera isaky ny sehatra. Ohatra vitsivitsy azo idirana avy hatrany aorian’ny bakalaorea: sekoly miaramila na polisy, Sekoly Ambony Miompana amin’ny Ranomasina (ENEM), oniversite miankina amin’ny fanjakana mandray mpianatra amin’ny alalan’ny fifaninanana. Mila mitandrina: misy sekoly ambony toa ny ENAM mangataka fari-pahaizana bac+4, tsy azo idirana avy hatrany aorian’ny bakalaorea.$tip Miova matetika ny daty fanokafana — natsahatra vonjimaika mihitsy aza ny fifaninanana tamin’ny 2025 mba hohavaozina — koa jereo foana ny fanambarana ofisialin’ny ministera voakasika alohan’ny hisoratra anarana. Afaka manazava ny safidy misy aho, fa ianao ihany no manapa-kevitra farany.',
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureGreeting(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MianaraColors.greenSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: MianaraColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appText(context, 'Assistant', 'Mpanampy'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      appText(
                        context,
                        'Réponses locales, sans connexion',
                        'Valiny eto an-toerana, tsy misy Internet',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            itemCount: _messages.length + (_thinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return const _ThinkingBubble();
              }
              return _MessageBubble(message: _messages[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                label: appText(
                  context,
                  'Quelles pièces me manque-t-il ?',
                  'Inona no antontan-taratasy mbola ilaina?',
                ),
                onTap: () => _send(
                  appText(
                    context,
                    'Quelles pièces me manque-t-il ?',
                    'Inona no antontan-taratasy mbola ilaina?',
                  ),
                ),
              ),
              _SuggestionChip(
                label: appText(
                  context,
                  'Quel est mon centre d’examen ?',
                  'Aiza ny foibem-panadinako?',
                ),
                onTap: () => _send(
                  appText(
                    context,
                    'Quel est mon centre d’examen ?',
                    'Aiza ny foibem-panadinako?',
                  ),
                ),
              ),
              _SuggestionChip(
                label: appText(
                  context,
                  'Quels concours publics après le bac ?',
                  'Inona ny fifaninanana miankina amin’ny fanjakana aorian’ny bakalaorea?',
                ),
                onTap: () => _send(
                  appText(
                    context,
                    'Quels concours publics après le bac ?',
                    'Inona ny fifaninanana miankina amin’ny fanjakana aorian’ny bakalaorea?',
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: appText(
                      context,
                      'Posez votre question…',
                      'Apetraho ny fanontanianao…',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: MianaraColors.green,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _send(_controller.text),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    backgroundColor: MianaraColors.greenSoft,
    side: BorderSide.none,
    labelStyle: const TextStyle(
      color: MianaraColors.green,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = message.isUser
        ? MianaraColors.green
        : (isDark ? MianaraColors.surfaceRaisedDark : Colors.white);
    final textColor = message.isUser
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(MianaraRadii.lg),
            topRight: const Radius.circular(MianaraRadii.lg),
            bottomLeft: Radius.circular(message.isUser ? MianaraRadii.lg : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : MianaraRadii.lg),
          ),
          border: message.isUser
              ? null
              : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, height: 1.4),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(MianaraRadii.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const SizedBox(
        width: 20,
        height: 12,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    ),
  );
}
