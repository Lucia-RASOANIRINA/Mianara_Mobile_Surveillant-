import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/candidate.dart';
import '../app_language.dart';
import '../theme.dart';
import '../widgets/candidate_form.dart';

class DossierScreen extends StatefulWidget {
  const DossierScreen({
    required this.candidate,
    required this.onRefresh,
    super.key,
  });

  final Candidate? candidate;
  final Future<void> Function() onRefresh;

  @override
  State<DossierScreen> createState() => _DossierScreenState();
}

class _DossierScreenState extends State<DossierScreen> {
  late Future<List<Map<String, Object?>>> _items;

  @override
  void initState() {
    super.initState();
    _items = AppDatabase.instance.loadDossierItems();
  }

  @override
  void didUpdateWidget(covariant DossierScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidate == null && widget.candidate != null) {
      setState(() => _items = AppDatabase.instance.loadDossierItems());
    }
  }

  Future<void> _toggle(String id, bool value) async {
    await AppDatabase.instance.setDossierItemComplete(id, value);
    await widget.onRefresh();
    if (mounted) {
      setState(() => _items = AppDatabase.instance.loadDossierItems());
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _items,
    builder: (context, snapshot) {
      final items = snapshot.data ?? [];
      final complete = items.where((item) => item['is_complete'] == 1).length;

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          Text(
            appText(context, 'Mon dossier', 'Ny antontan-taratasiko'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            widget.candidate == null
                ? appText(
                    context,
                    'Créez votre profil pour commencer à préparer vos démarches.',
                    'Mamoròna mombamomba anao hanombohana ny fikarakarana.',
                  )
                : '${widget.candidate!.examType == 'Baccalauréat' ? appText(context, 'Baccalauréat', 'Bakalaorea') : widget.candidate!.examType} · ${widget.candidate!.candidateStatus == 'Scolaire' ? appText(context, 'Scolaire', 'Mpianatra') : appText(context, 'Candidat libre', 'Mpiadina afaka')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (widget.candidate == null)
            CandidateForm(onSaved: widget.onRefresh)
          else if (items.isEmpty)
            _DossierNotice(
              icon: Icons.info_outline,
              message: appText(
                context,
                'Aucune pièce n’est encore définie pour ce profil.',
                'Mbola tsy voafaritra ny antontan-taratasy ilaina amin’ity mombamomba ity.',
              ),
            )
          else ...[
            _ProgressCard(complete: complete, total: items.length),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DocumentTile(
                  id: item['id']! as String,
                  label: localizedRequirementLabel(
                    context,
                    item['id']! as String,
                    item['label']! as String,
                  ),
                  complete: item['is_complete'] == 1,
                  onChanged: (value) =>
                      _toggle(item['id']! as String, value ?? false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _DossierNotice(
              icon: Icons.info_outline,
              message: appText(
                context,
                'Cette checklist correspond uniquement à l’exemple du cahier des charges (Baccalauréat, série C, Centre Fianarantsoa, scolaire, première participation). Les pièces officielles doivent être confirmées par le ministère.',
                'Ity lisitra ity dia mifanaraka amin’ny ohatra ao amin’ny fepetra ihany (Bakalaorea, sokajy C, foibem-panadinana Fianarantsoa, mpianatra, sambany miatrika). Tokony hohamafisin’ny ministera ny antontan-taratasy ofisialy.',
              ),
            ),
          ],
        ],
      );
    },
  );
}

IconData _iconFor(String id) => switch (id) {
  'birth_certificate' => Icons.badge_rounded,
  'school_certificate' => Icons.school_rounded,
  'identity_photos' => Icons.photo_camera_rounded,
  'registration_form' => Icons.description_rounded,
  'registration_fee' => Icons.payments_rounded,
  _ => Icons.insert_drive_file_rounded,
};

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.complete, required this.total});

  final int complete;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : complete / total;
    final done = ratio >= 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appText(
                      context,
                      'Checklist des pièces',
                      'Lisitry ny antontan-taratasy',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: done ? MianaraColors.greenSoft : MianaraColors.sunSoft,
                    borderRadius: BorderRadius.circular(MianaraRadii.pill),
                  ),
                  child: Text(
                    '$complete/$total',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: done ? MianaraColors.green : MianaraColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(MianaraRadii.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Stack(
                  children: [
                    Container(height: 12, color: MianaraColors.greenSoft),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 12,
                        decoration: const BoxDecoration(
                          gradient: MianaraGradients.progress,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              done
                  ? appText(
                      context,
                      'Toutes les pièces sont prêtes !',
                      'Vonona daholo ny antontan-taratasy!',
                    )
                  : appText(
                      context,
                      'Encore ${total - complete} pièce(s) à préparer.',
                      'Antontan-taratasy ${total - complete} sisa hoomanina.',
                    ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.id,
    required this.label,
    required this.complete,
    required this.onChanged,
  });

  final String id;
  final String label;
  final bool complete;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    color: complete
        ? MianaraColors.greenSoft.withValues(alpha: 0.5)
        : null,
    child: InkWell(
      onTap: () => onChanged(!complete),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: complete ? MianaraColors.green : MianaraColors.greenSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(id),
                size: 18,
                color: complete ? Colors.white : MianaraColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 15,
                  decoration: complete ? TextDecoration.lineThrough : null,
                  color: complete
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Checkbox(
              value: complete,
              onChanged: onChanged,
              activeColor: MianaraColors.green,
              shape: const CircleBorder(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DossierNotice extends StatelessWidget {
  const _DossierNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? MianaraColors.warningSoftDark : MianaraColors.warningSoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isDark ? MianaraColors.warningDark : MianaraColors.warning,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? MianaraColors.warningDark
                      : MianaraColors.warning,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
