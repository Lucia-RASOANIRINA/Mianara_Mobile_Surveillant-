import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../app_language.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.onRegistered, super.key});

  final VoidCallback onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(
        username: _username.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              context,
              'Compte créé. Vous pouvez maintenant vous connecter.',
              'Voaforona ny kaontinao. Afaka miditra ianao ankehitriny.',
            ),
          ),
        ),
      );
      widget.onRegistered();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(appText(context, 'Créer un compte', 'Hamorona kaonty')),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              appText(
                context,
                'Commencez votre parcours',
                'Atombohy ny dianao',
              ),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              appText(
                context,
                'Un compte candidat pour préparer votre dossier, réviser et suivre votre examen.',
                'Kaonty mpiadina hanomanana ny antontan-taratasinao, hamerina lesona ary hanaraka ny fanadinanao.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MianaraColors.dangerSoft,
                  borderRadius: BorderRadius.circular(MianaraRadii.md),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: MianaraColors.danger),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _fullName,
              decoration: InputDecoration(
                labelText: appText(context, 'Nom complet', 'Anarana feno'),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? appText(context, 'Champ obligatoire', 'Tsy maintsy fenoina')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              decoration: InputDecoration(
                labelText: appText(context, 'Identifiant', 'Anarana mpampiasa'),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? appText(context, 'Champ obligatoire', 'Tsy maintsy fenoina')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: appText(
                  context,
                  'Téléphone (optionnel)',
                  'Laharana finday (tsy tsy maintsy)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: appText(
                  context,
                  'E-mail (optionnel)',
                  'Mailaka (tsy tsy maintsy)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: appText(context, 'Mot de passe', 'Teny miafina'),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) => value == null || value.length < 8
                  ? appText(
                      context,
                      'Au moins 8 caractères',
                      'Farafahakeliny 8 tarehin-tsoratra',
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: appText(
                  context,
                  'Confirmer le mot de passe',
                  'Hamafiso ny teny miafina',
                ),
              ),
              validator: (value) => value != _password.text
                  ? appText(
                      context,
                      'Les mots de passe ne correspondent pas',
                      'Tsy mitovy ny teny miafina',
                    )
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      appText(context, 'Créer mon compte', 'Hamorona ny kaontiko'),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
