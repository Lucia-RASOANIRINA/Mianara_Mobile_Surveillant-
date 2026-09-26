import 'package:flutter/widgets.dart';

enum AppLanguage { french, malagasy }

class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    required this.language,
    required super.child,
    super.key,
  });

  final AppLanguage language;

  static AppLanguageScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    assert(scope != null, 'AppLanguageScope is missing from the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      language != oldWidget.language;
}

String appText(BuildContext context, String french, String malagasy) =>
    AppLanguageScope.of(context).language == AppLanguage.malagasy
    ? malagasy
    : french;

String localizedSubject(BuildContext context, String subject) {
  if (AppLanguageScope.of(context).language == AppLanguage.french) {
    return subject;
  }
  return switch (subject) {
    'Mathématiques' => 'Matematika',
    'Physique' => 'Fizika',
    'Français' => 'Frantsay',
    'Histoire' => 'Tantara',
    'Géographie' => 'Jeografia',
    _ => subject,
  };
}

/// Libellé localisé d'une pièce du dossier, à partir de son identifiant
/// technique. Partagé entre l'écran Dossier et l'assistant.
String localizedRequirementLabel(
  BuildContext context,
  String id,
  String fallback,
) {
  switch (id) {
    case 'birth_certificate':
      return appText(
        context,
        'Copie de l’acte de naissance',
        'Kopian’ny kopia nahaterahana',
      );
    case 'school_certificate':
      return appText(
        context,
        'Certificat de scolarité',
        'Taratasy manamarina ny maha-mpianatra',
      );
    case 'identity_photos':
      return appText(context, 'Photos d’identité', 'Sary famantarana');
    case 'registration_form':
      return appText(
        context,
        'Formulaire d’inscription',
        'Taratasy fisoratana anarana',
      );
    case 'registration_fee':
      return appText(
        context,
        'Frais d’inscription',
        'Saram-pisoratana anarana',
      );
    default:
      return fallback;
  }
}
