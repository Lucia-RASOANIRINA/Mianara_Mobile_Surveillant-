import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/mobile_api.dart';
import '../../models/learning_content.dart';
import '../app_language.dart';
import '../theme.dart';

class LearningContentSection extends StatefulWidget {
  const LearningContentSection({super.key});

  @override
  State<LearningContentSection> createState() => _LearningContentSectionState();
}

class _LearningContentSectionState extends State<LearningContentSection> {
  late Future<_ItemsLoad> _items;
  late Future<List<CoachingSession>> _sessions;
  final Map<String, String> _paymentStatuses = {};
  bool _requiresLogin = true;

  @override
  void initState() {
    super.initState();
    _items = _loadItems();
    _sessions = _loadSessions();
  }

  Future<_ItemsLoad> _loadItems() async {
    final database = AppDatabase.instance;
    final candidateId = await database.loadMobileCandidateId();
    final token = await database.loadMobileToken();
    if (token != null && !await database.mobilePasswordChangeRequired()) {
      try {
        final catalog = await MobileApi.instance.learningItems(token: token);
        if (candidateId != null) {
          await database.cacheApprovedLearningItems(
            candidateId: candidateId,
            items: catalog.items.map((item) {
              final json = item.toJson();
              if (!item.purchased) json['content'] = '';
              return json;
            }).toList(),
          );
        }
        return _ItemsLoad(
          items: catalog.items,
          merchantNumber: catalog.merchantNumber,
        );
      } catch (error) {
        final cached = await _loadCached(database, candidateId);
        if (cached.isNotEmpty) {
          return _ItemsLoad(items: cached, error: error, offline: true);
        }
        rethrow;
      }
    }
    final cached = await _loadCached(database, candidateId);
    return _ItemsLoad(items: cached, offline: cached.isNotEmpty);
  }

  Future<List<LearningItem>> _loadCached(
    AppDatabase database,
    String? candidateId,
  ) async {
    if (candidateId == null) return const [];
    final cached = await database.loadApprovedLearningItems(
      candidateId: candidateId,
    );
    return cached.map(LearningItem.fromJson).toList();
  }

  Future<List<CoachingSession>> _loadSessions() async {
    final token = await AppDatabase.instance.loadMobileToken();
    final requiresLogin =
        token == null ||
        await AppDatabase.instance.mobilePasswordChangeRequired();
    if (mounted && _requiresLogin != requiresLogin) {
      setState(() => _requiresLogin = requiresLogin);
    }
    if (requiresLogin) {
      return const [];
    }
    return MobileApi.instance.coachingSessions(token: token);
  }

  void _retryItems() => setState(() => _items = _loadItems());
  void _retrySessions() => setState(() => _sessions = _loadSessions());

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        appText(context, 'Cours et entraînements', 'Lesona sy fanazarana'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        appText(
          context,
          'Les contenus validés restent consultables hors connexion. Seul le serveur confirme un achat.',
          'Azo vakina tsy misy Internet ny lesona nekena. Ny mpizara ihany no manamarina ny fividianana.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      FutureBuilder<_ItemsLoad>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: appText(
                context,
                'Impossible de charger les contenus. Vérifiez la connexion puis réessayez.',
                'Tsy afaka nampiditra lesona. Hamarino ny Internet dia andramo indray.',
              ),
              onRetry: _retryItems,
            );
          }
          final result = snapshot.data!;
          return Column(
            children: [
              if (result.offline)
                _Notice(
                  text: appText(
                    context,
                    result.error == null
                        ? 'Affichage du dernier catalogue synchronisé. Les achats et le tutorat nécessitent une connexion.'
                        : 'Connexion impossible. Dernier catalogue synchronisé affiché ; les achats restent indisponibles.',
                    result.error == null
                        ? 'Ity ny lesona nampifandraisina farany. Mila Internet ny fividianana sy ny fampianarana.'
                        : 'Tsy tafiditra ny Internet. Aseho ny lesona farany; tsy azo atao ny fividianana.',
                  ),
                  retry: _retryItems,
                ),
              if (result.items.isEmpty)
                _Notice(
                  text: appText(
                    context,
                    'Aucun cours ni entraînement n’est publié pour le moment.',
                    'Mbola tsy misy lesona na fanazarana navoaka.',
                  ),
                  retry: result.offline ? _retryItems : null,
                )
              else
                ...result.items.map(
                  (item) => _LearningItemCard(
                    item: item,
                    merchantNumber: result.merchantNumber,
                    paymentStatus:
                        _paymentStatuses[item.id] ?? item.paymentStatus,
                    allowPayment: !result.offline,
                    onPaymentSubmitted: (status) {
                      setState(() {
                        _paymentStatuses[item.id] = status;
                        _items = _loadItems();
                        _sessions = _loadSessions();
                      });
                    },
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 28),
      Text(
        appText(context, 'Tutorat', 'Fampianarana manokana'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        appText(
          context,
          'Échangez uniquement dans une séance attribuée par le serveur. Le tutorat affiche la matière du tuteur, jamais son identité.',
          'Miresaha ao amin’ny fotoana nomen’ny mpizara ihany. Ny taranja ampianarin’ny mpampianatra ihany no aseho fa tsy ny mombamomba azy.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<CoachingSession>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: appText(
                context,
                'Impossible de charger les séances de tutorat.',
                'Tsy afaka nampiditra ny fotoana fampianarana.',
              ),
              onRetry: _retrySessions,
            );
          }
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty) {
            return _Notice(
              text: appText(
                context,
                _requiresLogin
                    ? 'Connectez-vous depuis Profil pour consulter vos séances.'
                    : 'Aucune séance ne vous a encore été attribuée.',
                _requiresLogin
                    ? 'Midira ao amin’ny Profil hijerena ny fotoana fampianarana.'
                    : 'Mbola tsy nomena fotoana fampianarana ianao.',
              ),
              retry: _retrySessions,
            );
          }
          return Column(
            children: sessions.map((session) {
              final active = session.canChat;
              return Card(
                child: ListTile(
                  leading: Icon(
                    active ? Icons.forum_outlined : Icons.hourglass_top,
                    color: active ? MianaraColors.green : MianaraColors.warning,
                  ),
                  title: Text(
                    appText(
                      context,
                      'Tuteur·rice en ${session.teacherSubject}',
                      'Mpampianatra ${session.teacherSubject}',
                    ),
                  ),
                  subtitle: Text(
                    active
                        ? appText(context, 'Séance active', 'Fotoana mandeha')
                        : appText(
                            context,
                            'Paiement en attente',
                            'Miandry fanamarinana ny vola',
                          ),
                  ),
                  trailing: active ? const Icon(Icons.chevron_right) : null,
                  onTap: active
                      ? () async {
                          final token = await AppDatabase.instance
                              .loadMobileToken();
                          if (!context.mounted || token == null) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _CoachingChatPage(
                                token: token,
                                session: session,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

class _ItemsLoad {
  const _ItemsLoad({
    required this.items,
    this.merchantNumber,
    this.error,
    this.offline = false,
  });

  final List<LearningItem> items;
  final String? merchantNumber;
  final Object? error;
  final bool offline;
}

class _LearningItemCard extends StatelessWidget {
  const _LearningItemCard({
    required this.item,
    required this.merchantNumber,
    required this.paymentStatus,
    required this.allowPayment,
    required this.onPaymentSubmitted,
  });

  final LearningItem item;
  final String? merchantNumber;
  final String? paymentStatus;
  final bool allowPayment;
  final ValueChanged<String> onPaymentSubmitted;

  @override
  Widget build(BuildContext context) {
    final isCoaching = item.kind == 'coaching';
    return Card(
      child: ListTile(
        leading: Icon(
          isCoaching ? Icons.support_agent : Icons.menu_book_outlined,
          color: MianaraColors.green,
        ),
        title: Text(
          isCoaching
              ? appText(
                  context,
                  'Tutorat en ${item.subjectCode}',
                  'Fampianarana ${item.subjectCode}',
                )
              : item.title,
        ),
        subtitle: Text(
          [
            if (!isCoaching && item.description.isNotEmpty) item.description,
            if (item.durationMinutes != null)
              appText(
                context,
                '${item.durationMinutes} min',
                '${item.durationMinutes} min',
              ),
            if (paymentStatus != null) _paymentLabel(context, paymentStatus!),
            if (item.purchased)
              appText(context, 'Acheté', 'Voavidy')
            else if (item.priceAmount != null)
              '${_formatPrice(item.priceAmount!)} ${item.currency}',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _LearningDetailSheet(
            item: item,
            merchantNumber: merchantNumber,
            paymentStatus: paymentStatus,
            allowPayment: allowPayment,
            onPaymentSubmitted: onPaymentSubmitted,
          ),
        ),
      ),
    );
  }

  String _paymentLabel(BuildContext context, String status) => switch (status) {
    'pending' => appText(
      context,
      'Paiement en attente',
      'Miandry fanamarinana ny vola',
    ),
    'approved' => appText(context, 'Paiement approuvé', 'Nekena ny vola'),
    'rejected' => appText(context, 'Paiement refusé', 'Tsy nekena ny vola'),
    _ => '',
  };
}

class _LearningDetailSheet extends StatelessWidget {
  const _LearningDetailSheet({
    required this.item,
    required this.merchantNumber,
    required this.paymentStatus,
    required this.allowPayment,
    required this.onPaymentSubmitted,
  });

  final LearningItem item;
  final String? merchantNumber;
  final String? paymentStatus;
  final bool allowPayment;
  final ValueChanged<String> onPaymentSubmitted;

  @override
  Widget build(BuildContext context) {
    final content = item.accessibleContent;
    final isCoaching = item.kind == 'coaching';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          22 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCoaching
                    ? appText(
                        context,
                        'Tutorat en ${item.subjectCode}',
                        'Fampianarana ${item.subjectCode}',
                      )
                    : item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              if (!isCoaching && item.description.isNotEmpty)
                Text(item.description),
              if (!isCoaching && content != null && content.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(height: 1.6),
                ),
              ] else if (!item.purchased) ...[
                const SizedBox(height: 12),
                _Notice(
                  text: appText(
                    context,
                    'Le contenu complet s’affiche après confirmation de l’achat par le serveur.',
                    'Hiseho ny lesona feno rehefa voamarin’ny mpizara ny fividianana.',
                  ),
                ),
              ],
              if (item.canSubmitCoachingPayment) ...[
                const SizedBox(height: 16),
                if (paymentStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_statusLabel(context, paymentStatus!)),
                  ),
                if (merchantNumber == null || merchantNumber!.isEmpty)
                  _Notice(
                    text: appText(
                      context,
                      'Le numéro marchand Orange Money n’est pas encore configuré.',
                      'Mbola tsy voafaritra ny laharan’ny Orange Money handoavana.',
                    ),
                  )
                else
                  Text(
                    appText(
                      context,
                      'Envoie ${_formatPrice(item.priceAmount!)} MGA au $merchantNumber, puis saisis la référence de transaction.',
                      'Alefaso amin’ny laharana $merchantNumber ny ${_formatPrice(item.priceAmount!)} MGA, dia ampidiro ny laharan’ny fifanakalozana.',
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      allowPayment &&
                          merchantNumber != null &&
                          merchantNumber!.isNotEmpty
                      ? () => _submitPayment(context)
                      : null,
                  icon: const Icon(Icons.phone_android),
                  label: Text(
                    appText(
                      context,
                      'Envoyer la référence Orange Money',
                      'Alefaso ny laharan’ny Orange Money',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPayment(BuildContext context) async {
    final authenticationRequired = appText(
      context,
      'Connectez-vous pour envoyer un paiement.',
      'Midira kaonty handefasana ny vola.',
    );
    final reference = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          appText(
            context,
            'Paiement Orange Money',
            'Fandoavana amin’ny Orange Money',
          ),
        ),
        content: TextField(
          controller: reference,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: appText(
              context,
              'Référence de transaction',
              'Laharan’ny fifanakalozana',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appText(context, 'Annuler', 'Hiverina')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, reference.text.trim()),
            child: Text(appText(context, 'Envoyer', 'Alefa')),
          ),
        ],
      ),
    );
    reference.dispose();
    if (value == null || value.isEmpty || !context.mounted) return;
    try {
      final token = await AppDatabase.instance.loadMobileToken();
      if (token == null ||
          await AppDatabase.instance.mobilePasswordChangeRequired()) {
        throw StateError(authenticationRequired);
      }
      final response = await MobileApi.instance.submitCoachingPayment(
        token: token,
        listingId: item.id,
        transactionReference: value,
      );
      final responsePayment = response['payment'];
      final rawStatus =
          response['status'] ??
          (responsePayment is Map ? responsePayment['status'] : null);
      final status =
          rawStatus is String &&
              const {'pending', 'approved', 'rejected'}.contains(rawStatus)
          ? rawStatus
          : 'pending';
      onPaymentSubmitted(status);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              context,
              'Envoi impossible. Vérifiez la connexion et réessayez.',
              'Tsy afaka nandefa. Hamarino ny Internet dia andramo indray.',
            ),
          ),
          action: SnackBarAction(
            label: appText(context, 'Réessayer', 'Andramo indray'),
            onPressed: () => _submitPayment(context),
          ),
        ),
      );
    }
  }

  String _statusLabel(BuildContext context, String status) => switch (status) {
    'pending' => appText(
      context,
      'Paiement en attente de confirmation.',
      'Miandry fanamarinana ny vola.',
    ),
    'approved' => appText(
      context,
      'Paiement approuvé par le serveur.',
      'Neken’ny mpizara ny vola.',
    ),
    'rejected' => appText(
      context,
      'Paiement refusé par le serveur.',
      'Nolavin’ny mpizara ny vola.',
    ),
    _ => '',
  };
}

class _CoachingChatPage extends StatefulWidget {
  const _CoachingChatPage({required this.token, required this.session});

  final String token;
  final CoachingSession session;

  @override
  State<_CoachingChatPage> createState() => _CoachingChatPageState();
}

class _CoachingChatPageState extends State<_CoachingChatPage> {
  late Future<List<CoachingMessage>> _messages;
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = _loadMessages();
  }

  Future<List<CoachingMessage>> _loadMessages() => MobileApi.instance
      .coachingMessages(token: widget.token, sessionId: widget.session.id);

  void _retry() => setState(() => _messages = _loadMessages());

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await MobileApi.instance.sendCoachingMessage(
        token: widget.token,
        sessionId: widget.session.id,
        text: text,
      );
      _controller.clear();
      setState(() => _messages = _loadMessages());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appText(context, 'Message envoyé.', 'Nalefa ny hafatra.'),
            ),
          ),
        );
      }
      // Retain the server response if an immediate read is temporarily delayed.
      if (message.id.isEmpty) return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appText(
                context,
                'Message non envoyé. Vérifiez la connexion et réessayez.',
                'Tsy nalefa ny hafatra. Hamarino ny Internet dia andramo indray.',
              ),
            ),
            action: SnackBarAction(
              label: appText(context, 'Réessayer', 'Andramo indray'),
              onPressed: _send,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        appText(
          context,
          'Tuteur·rice en ${widget.session.teacherSubject}',
          'Mpampianatra ${widget.session.teacherSubject}',
        ),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: FutureBuilder<List<CoachingMessage>>(
            future: _messages,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorCard(
                  message: appText(
                    context,
                    'Impossible de charger les messages.',
                    'Tsy afaka nampiditra ny hafatra.',
                  ),
                  onRetry: _retry,
                );
              }
              final messages = snapshot.data ?? const [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCandidate = message.sender == 'candidate';
                  return Align(
                    alignment: isCandidate
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .78,
                      ),
                      child: Card(
                        color: isCandidate
                            ? MianaraColors.greenSoft
                            : Theme.of(context).cardTheme.color,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appText(
                                  context,
                                  isCandidate ? 'Vous' : 'Tuteur·rice',
                                  isCandidate ? 'Ianao' : 'Mpampianatra',
                                ),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(message.text),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: appText(context, 'Votre message', 'Hafatrao'),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(appText(context, 'Réessayer', 'Andramo indray')),
          ),
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.retry});

  final String text;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) => Card(
    color: MianaraColors.infoSoft,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: MianaraColors.info),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          if (retry != null)
            IconButton(
              onPressed: retry,
              tooltip: appText(context, 'Actualiser', 'Havaozy'),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    ),
  );
}

String _formatPrice(num amount) =>
    amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
