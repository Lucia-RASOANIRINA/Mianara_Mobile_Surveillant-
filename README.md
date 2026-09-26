# Mianara Mobile

Application Flutter Android/iOS orientée candidat, avec stockage local SQLite
chiffré (SQLCipher) pour le profil, la checklist administrative et les sessions
de révision. La clé est générée par l’application et conservée dans le stockage
sécurisé du système (Android Keystore / iOS Keychain).

## Démarrer

```sh
flutter pub get
flutter run
```

L’application reprend les couleurs, la police et le symbole de la charte
Mianara. Les informations saisies et les modifications en attente sont stockées
localement afin de rester consultables hors connexion.
Le bouton `FR` / `MG` dans la barre supérieure permet de basculer l’interface
entre le français et le malagasy ; le choix est mémorisé localement.

## Synchronisation

WorkManager planifie une vérification périodique lorsque le réseau est
disponible. Les créations et modifications locales sont inscrites dans une
file d’attente SQLite. Le contrat de l’API web n’étant pas fourni, aucune
donnée n’est envoyée et les éléments en attente sont conservés ; l’application
indique que la connexion à l’API reste à configurer. La fréquence réelle
d’exécution en arrière-plan dépend des politiques du système Android/iOS.

## Portée actuelle

L’application comprend le profil candidat, le suivi local du dossier, le
tableau de bord et l’enregistrement de sessions de révision. Le contenu des
cours, exercices et annales doit être fourni par le catalogue pédagogique
officiel ; aucun contenu pédagogique fictif n’est inclus. Les pièces proposées
dans la checklist sont l’exemple du cahier des charges et doivent être validées
par les autorités compétentes.

## Vérification

```sh
flutter analyze
flutter test
```
