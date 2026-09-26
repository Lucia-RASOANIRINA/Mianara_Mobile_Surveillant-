import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../models/candidate.dart';
import '../app_language.dart';
import '../theme.dart';

/// Formulaire de profil candidat, réutilisé tel quel dans l'onglet Profil et
/// directement dans l'onglet Dossier tant qu'aucun profil n'existe.
class CandidateForm extends StatefulWidget {
  const CandidateForm({required this.onSaved, super.key});

  final Future<void> Function() onSaved;

  @override
  State<CandidateForm> createState() => _CandidateFormState();
}

class _CandidateFormState extends State<CandidateForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String _series = 'S';
  String _status = 'Scolaire';
  String _gender = '';
  String _language = 'Français';
  bool _firstParticipation = true;
  bool _loading = true;
  bool _saving = false;

  static const _fields = {
    'firstName': ('Prénom', 'Anarana', true),
    'lastName': ('Nom', 'Fanampin’anarana', true),
    'birthDate': (
      'Date de naissance (AAAA-MM-JJ)',
      'Daty nahaterahana (TAONA- volana-andro)',
      false,
    ),
    'birthplace': ('Lieu de naissance', 'Toerana nahaterahana', false),
    'address': ('Adresse', 'Adiresy', false),
    'phone': ('Téléphone', 'Laharana finday', false),
    'email': ('E-mail', 'Mailaka', false),
    'birthCertificateNumber': (
      'Numéro d’acte de naissance',
      'Laharan’ny kopia nahaterahana',
      false,
    ),
    'examCenter': ('Centre d’examen', 'Foibem-panadinana', false),
  };

  @override
  void initState() {
    super.initState();
    for (final key in _fields.keys) {
      _controllers[key] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    final candidate = await AppDatabase.instance.loadCandidate();
    if (candidate != null) {
      _controllers['firstName']!.text = candidate.firstName;
      _controllers['lastName']!.text = candidate.lastName;
      _controllers['birthDate']!.text = candidate.birthDate;
      _controllers['birthplace']!.text = candidate.birthplace;
      _controllers['address']!.text = candidate.address;
      _controllers['phone']!.text = candidate.phone;
      _controllers['email']!.text = candidate.email;
      _controllers['birthCertificateNumber']!.text =
          candidate.birthCertificateNumber;
      _controllers['examCenter']!.text = candidate.examCenter;
      _series = Candidate.canonicalSeries(candidate.examSeries);
      _status = candidate.candidateStatus;
      _gender = candidate.gender;
      _language = candidate.preferredLanguage;
      _firstParticipation = candidate.firstParticipation;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.saveCandidate(
        Candidate(
          firstName: _controllers['firstName']!.text.trim(),
          lastName: _controllers['lastName']!.text.trim(),
          birthDate: _controllers['birthDate']!.text.trim(),
          birthplace: _controllers['birthplace']!.text.trim(),
          gender: _gender,
          address: _controllers['address']!.text.trim(),
          phone: _controllers['phone']!.text.trim(),
          email: _controllers['email']!.text.trim(),
          birthCertificateNumber: _controllers['birthCertificateNumber']!.text
              .trim(),
          examType: 'Baccalauréat',
          examSeries: _series,
          examCenter: _controllers['examCenter']!.text.trim(),
          candidateStatus: _status,
          firstParticipation: _firstParticipation,
          preferredLanguage: _language,
        ),
      );
      await widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appText(
            context,
            'Profil enregistré sur cet appareil.',
            'Voatahiry amin’ity fitaovana ity ny mombamomba anao.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            icon: Icons.badge_rounded,
            tint: MianaraColors.green,
            tintSoft: MianaraColors.greenSoft,
            title: appText(context, 'État civil', 'Mombamomba manokana'),
            children: [
              ..._fields.entries
                  .take(4)
                  .map((entry) => _textField(entry.key, entry.value)),
              DropdownButtonFormField<String>(
                initialValue: _gender.isEmpty ? null : _gender,
                decoration: InputDecoration(
                  labelText: appText(context, 'Sexe', 'Lahy sa vavy'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Féminin',
                    child: Text(appText(context, 'Féminin', 'Vehivavy')),
                  ),
                  DropdownMenuItem(
                    value: 'Masculin',
                    child: Text(appText(context, 'Masculin', 'Lehilahy')),
                  ),
                ],
                onChanged: (value) => setState(() => _gender = value ?? ''),
              ),
              const SizedBox(height: 12),
              ..._fields.entries
                  .skip(4)
                  .take(5)
                  .map((entry) => _textField(entry.key, entry.value)),
            ],
          ),
          const SizedBox(height: 18),
          _SectionCard(
            icon: Icons.school_rounded,
            tint: MianaraColors.red,
            tintSoft: MianaraColors.redSoft,
            title: appText(context, 'Examen', 'Fanadinana'),
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: appText(
                    context,
                    'Examen national',
                    'Fanadinam-pirenena',
                  ),
                ),
                child: Text(
                  appText(context, 'Baccalauréat', 'Bakalaorea'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _series,
                decoration: InputDecoration(
                  labelText: appText(
                    context,
                    'Série du Baccalauréat',
                    'Sokajin’ny bakalorea',
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'L',
                    child: Text(
                      appText(context, 'Littéraire · L', 'Literatiora · L'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'S',
                    child: Text(
                      appText(context, 'Scientifique · S', 'Siantifika · S'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'OSE',
                    child: Text(
                      appText(
                        context,
                        'Économie et société · OSE',
                        'Toekarena sy fiarahamonina · OSE',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'TI',
                    child: Text(
                      appText(
                        context,
                        'Bac technique · Industriel (TI)',
                        'Bac teknika · Indostrialy (TI)',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'TGC',
                    child: Text(
                      appText(
                        context,
                        'Bac technique · Génie civil (TGC)',
                        'Bac teknika · Fanorenana (TGC)',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'TT',
                    child: Text(
                      appText(
                        context,
                        'Bac technique · Tertiaire (TT)',
                        'Bac teknika · Fitantanana (TT)',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'TA',
                    child: Text(
                      appText(
                        context,
                        'Bac technique · Agricole (TA)',
                        'Bac teknika · Fambolena (TA)',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _series = value ?? _series),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: appText(
                    context,
                    'Statut du candidat',
                    'Satan’ny mpiadina',
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Scolaire',
                    child: Text(appText(context, 'Scolaire', 'Mpianatra')),
                  ),
                  DropdownMenuItem(
                    value: 'Libre',
                    child: Text(
                      appText(context, 'Candidat libre', 'Mpiadina afaka'),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  appText(
                    context,
                    'Première participation',
                    'Sambany miatrika',
                  ),
                ),
                value: _firstParticipation,
                onChanged: (value) =>
                    setState(() => _firstParticipation = value),
              ),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: InputDecoration(
                  labelText: appText(
                    context,
                    'Langue préférée',
                    'Fiteny tiana',
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Français',
                    child: Text(appText(context, 'Français', 'Frantsay')),
                  ),
                  DropdownMenuItem(value: 'Malagasy', child: Text('Malagasy')),
                ],
                onChanged: (value) =>
                    setState(() => _language = value ?? _language),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              appText(
                context,
                'Enregistrer mon profil',
                'Hitahiry ny mombamomba ahy',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(String key, (String, String, bool) config) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controllers[key],
      keyboardType: key == 'email'
          ? TextInputType.emailAddress
          : key == 'phone'
          ? TextInputType.phone
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: appText(context, config.$1, config.$2),
      ),
      validator: config.$3
          ? (value) => value == null || value.trim().isEmpty
                ? appText(context, 'Champ obligatoire', 'Tsy maintsy fenoina')
                : null
          : null,
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.tint,
    required this.tintSoft,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color tint;
  final Color tintSoft;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: tintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}
