import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../data/mobile_api.dart';
import '../../data/sync_service.dart';
import '../app_language.dart';
import '../theme.dart';
import '../widgets/candidate_form.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onSaved, super.key});

  final Future<void> Function() onSaved;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<String?> _username;
  late Future<String> _syncStatus;
  late Future<bool> _passwordChangeRequired;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _username = AppDatabase.instance.loadMobileUsername();
    _syncStatus = AppDatabase.instance.syncStatus();
    _passwordChangeRequired = AppDatabase.instance
        .mobilePasswordChangeRequired();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _username = AppDatabase.instance.loadMobileUsername();
    _syncStatus = AppDatabase.instance.syncStatus();
    _passwordChangeRequired = AppDatabase.instance
        .mobilePasswordChangeRequired();
  }

  Future<void> _signIn() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          appText(context, 'Connexion candidat', 'Fidirana mpiadina'),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: appText(
                    context,
                    'Matricule',
                    'Laharan’ny mpiadina',
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? appText(
                        context,
                        'Saisissez votre matricule.',
                        'Ampidiro ny laharanao.',
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appText(context, 'Mot de passe', 'Tenimiafina'),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? appText(
                        context,
                        'Saisissez votre mot de passe.',
                        'Ampidiro ny tenimiafinao.',
                      )
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appText(context, 'Annuler', 'Hanafoana')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, usernameController.text.trim());
              }
            },
            child: Text(appText(context, 'Se connecter', 'Hiditra')),
          ),
        ],
      ),
    );
    usernameController.dispose();
    if (username == null || !mounted) {
      passwordController.dispose();
      return;
    }

    setState(() => _working = true);
    try {
      final mustChangePassword = await SyncService.instance.login(
        username: username,
        password: passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _username = AppDatabase.instance.loadMobileUsername();
        _passwordChangeRequired = AppDatabase.instance
            .mobilePasswordChangeRequired();
      });
      _refreshSyncStatus();
      if (mustChangePassword) {
        final changed = await _promptPasswordChange(
          currentPassword: passwordController.text,
        );
        if (!changed) {
          await widget.onSaved();
          return;
        }
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              context,
              'Compte candidat connecté.',
              'Tafiditra ny kaontin’ny mpiadina.',
            ),
          ),
        ),
      );
      await _syncNow();
      await widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appText(context, 'Connexion impossible', 'Tsy afaka miditra')}: $error',
          ),
        ),
      );
    } finally {
      passwordController.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _working = true);
    try {
      await SyncService.instance.logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appText(context, 'Session supprimée de cet appareil ; révocation serveur impossible', 'Voafafa tamin’ity fitaovana ity ny session; tsy afaka nanafoana azy tao amin’ny mpizara')}: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _username = AppDatabase.instance.loadMobileUsername();
          _syncStatus = AppDatabase.instance.syncStatus();
          _working = false;
        });
      }
    }
  }

  Future<bool> _promptPasswordChange({required String currentPassword}) async {
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final newPassword = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          appText(context, 'Sécuriser votre compte', 'Arovy ny kaontinao'),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appText(
                  context,
                  'Votre mot de passe temporaire doit être remplacé avant la synchronisation.',
                  'Tsy maintsy soloina ny tenimiafina vonjimaika alohan’ny fampifandraisana.',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: newPasswordController,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appText(
                    context,
                    'Nouveau mot de passe',
                    'Tenimiafina vaovao',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return appText(
                      context,
                      '8 caractères minimum.',
                      'Tarehintsoratra 8 farafahakeliny.',
                    );
                  }
                  if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                      !RegExp(r'\d').hasMatch(value)) {
                    return appText(
                      context,
                      'Ajoutez au moins une lettre et un chiffre.',
                      'Asio litera iray sy isa iray farafahakeliny.',
                    );
                  }
                  if (value == currentPassword) {
                    return appText(
                      context,
                      'Choisissez un mot de passe différent.',
                      'Misafidiana tenimiafina hafa.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: appText(
                    context,
                    'Confirmer le mot de passe',
                    'Hamafiso ny tenimiafina',
                  ),
                ),
                validator: (value) => value != newPasswordController.text
                    ? appText(
                        context,
                        'Les mots de passe ne correspondent pas.',
                        'Tsy mitovy ny tenimiafina.',
                      )
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appText(context, 'Plus tard', 'Aoriana')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, newPasswordController.text);
              }
            },
            child: Text(appText(context, 'Enregistrer', 'Tehirizo')),
          ),
        ],
      ),
    );
    newPasswordController.dispose();
    confirmController.dispose();
    if (newPassword == null || !mounted) return false;

    try {
      await SyncService.instance.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return false;
      setState(() {
        _passwordChangeRequired = AppDatabase.instance
            .mobilePasswordChangeRequired();
      });
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appText(context, 'Modification du mot de passe impossible', 'Tsy afaka nanova tenimiafina')}: $error',
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<String?> _showCurrentPassword() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          appText(context, 'Mot de passe actuel', 'Tenimiafina ankehitriny'),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: InputDecoration(
            labelText: appText(context, 'Mot de passe', 'Tenimiafina'),
          ),
          onSubmitted: (_) => Navigator.pop(dialogContext, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appText(context, 'Annuler', 'Hanafoana')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(appText(context, 'Continuer', 'Tohizo')),
          ),
        ],
      ),
    );
    controller.dispose();
    return password;
  }

  void _refreshSyncStatus() {
    setState(() => _syncStatus = AppDatabase.instance.syncStatus());
  }

  Future<void> _syncNow() async {
    setState(() => _working = true);
    try {
      await SyncService.instance.runPendingSync();
      _refreshSyncStatus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appText(context, 'Synchronisation impossible', 'Tsy afaka mampifandray')}: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
    children: [
      Text(
        appText(context, 'Mon profil', 'Ny mombamomba ahy'),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 6),
      Text(
        appText(
          context,
          'Vos informations restent sur cet appareil et peuvent être modifiées.',
          'Voatahiry amin’ity fitaovana ity ny mombamomba anao ary azonao ovaina.',
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<String?>(
            future: _username,
            builder: (context, snapshot) {
              final username = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appText(
                      context,
                      'Compte Mianara Web',
                      'Kaonty Mianara Web',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !MobileApi.instance.isConfigured
                        ? appText(
                            context,
                            'L’adresse de l’API doit être configurée pour activer la synchronisation.',
                            'Tsy maintsy amboarina ny adiresin’ny API mba hampandeha ny fampifandraisana.',
                          )
                        : username == null
                        ? appText(
                            context,
                            'Connectez-vous avec le matricule et le mot de passe de votre espace candidat.',
                            'Midira amin’ny laharana sy tenimiafina ao amin’ny kaontinao mpiadina.',
                          )
                        : '${appText(context, 'Connecté', 'Tafiditra')} · $username',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (!MobileApi.instance.isConfigured)
                    Text(
                      'MIANARA_API_BASE_URL',
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  else if (username == null)
                    FilledButton.icon(
                      onPressed: _working ? null : _signIn,
                      icon: const Icon(Icons.login_rounded),
                      label: Text(appText(context, 'Se connecter', 'Hiditra')),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _syncStatus,
                          builder: (context, statusSnapshot) => Text(
                            _localizedSyncStatus(
                              context,
                              statusSnapshot.data ?? 'local_only',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FutureBuilder<bool>(
                          future: _passwordChangeRequired,
                          builder: (context, passwordSnapshot) {
                            final requiresChange =
                                passwordSnapshot.data ?? true;
                            return Wrap(
                              spacing: 8,
                              children: [
                                if (requiresChange)
                                  OutlinedButton.icon(
                                    onPressed: _working
                                        ? null
                                        : () async {
                                            final currentPassword =
                                                await _showCurrentPassword();
                                            if (currentPassword != null) {
                                              await _promptPasswordChange(
                                                currentPassword:
                                                    currentPassword,
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.password_rounded),
                                    label: Text(
                                      appText(
                                        context,
                                        'Changer le mot de passe',
                                        'Hanova tenimiafina',
                                      ),
                                    ),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: _working ? null : _syncNow,
                                    icon: const Icon(Icons.sync_rounded),
                                    label: Text(
                                      appText(
                                        context,
                                        'Synchroniser',
                                        'Hampifandray',
                                      ),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: _working ? null : _signOut,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: Text(
                                    appText(
                                      context,
                                      'Se déconnecter',
                                      'Hivoaka',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  if (_working)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(
                        color: MianaraColors.green,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 22),
      CandidateForm(onSaved: widget.onSaved),
    ],
  );

  String _localizedSyncStatus(BuildContext context, String status) {
    switch (status) {
      case 'up_to_date':
        return appText(context, 'Données à jour', 'Vaovao ny tahiry');
      case 'syncing':
        return appText(
          context,
          'Synchronisation en cours…',
          'Mbola mampifandray…',
        );
      case 'sync_failed':
        return appText(
          context,
          'Échec de synchronisation ; les séances restent en attente.',
          'Tsy nahomby ny fampifandraisana; mbola miandry ireo lesona.',
        );
      case 'pending_sync':
        return appText(
          context,
          'Des séances attendent la synchronisation.',
          'Misy lesona miandry hampifandraisina.',
        );
      case 'authentication_required':
        return appText(
          context,
          'Connectez-vous pour synchroniser.',
          'Midira mba hampifandray.',
        );
      case 'password_change_required':
        return appText(
          context,
          'Remplacez votre mot de passe temporaire pour synchroniser.',
          'Soloy ny tenimiafina vonjimaika mba hampifandray.',
        );
      case 'api_not_configured':
        return appText(context, 'API non configurée.', 'Tsy voaomana ny API.');
      default:
        return appText(
          context,
          'Synchronisation non effectuée.',
          'Tsy mbola nifandray.',
        );
    }
  }
}
