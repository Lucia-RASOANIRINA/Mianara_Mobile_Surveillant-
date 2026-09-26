import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/auth_service.dart';
import '../app_language.dart';
import '../theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onLoggedIn, super.key});

  final VoidCallback onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(
        username: _username.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      widget.onLoggedIn();
    } on ApiException catch (error) {
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFor(ApiException error) {
    if (error.statusCode == 423) {
      return appText(
        context,
        'Compte temporairement verrouillé après plusieurs échecs. Réessayez plus tard.',
        'Voahidy vonjimaika ny kaontinao noho ny fahatsapana matetika. Andramo indray any aoriana.',
      );
    }
    if (error.statusCode == 401) {
      return appText(
        context,
        'Identifiant ou mot de passe incorrect.',
        'Diso ny anarana mpampiasa na ny teny miafina.',
      );
    }
    return appText(
      context,
      'Connexion impossible pour le moment. Vérifiez votre connexion Internet.',
      'Tsy afaka niditra amin\'izao fotoana izao. Jereo ny fifandraisan\'ny Internet.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context, 'Connexion', 'Fidirana'))),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              appText(context, 'Ravi de vous revoir', 'Faly mahita anao indray'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              appText(
                context,
                'Connectez-vous pour retrouver votre dossier, vos révisions et votre assistant.',
                'Midira mba hahitana ny antontan-taratasinao, ny famerenana lesona ary ny mpanampy.',
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
              validator: (value) => value == null || value.isEmpty
                  ? appText(context, 'Champ obligatoire', 'Tsy maintsy fenoina')
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
                  : Text(appText(context, 'Se connecter', 'Hiditra')),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  final language = AppLanguageScope.of(context).language;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (routeContext) => AppLanguageScope(
                        language: language,
                        child: RegisterScreen(
                          onRegistered: () => Navigator.of(routeContext).pop(),
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  appText(
                    context,
                    'Pas encore de compte ? Créer un compte',
                    'Mbola tsy manana kaonty? Hamorona kaonty',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
