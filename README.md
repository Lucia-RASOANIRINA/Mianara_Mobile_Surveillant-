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
disponible. Les sessions de révision sont conservées dans la file SQLite puis
envoyées à l’API mobile du dépôt web quand le candidat est connecté. Le jeton
est conservé dans le stockage sécurisé Android/iOS ; les opérations ne sont
retirées de la file qu’après confirmation du serveur. Chaque séance locale est
rattachée au compte candidat actif ; les éléments en attente d’un compte ne
sont jamais envoyés avec le compte d’un autre candidat. La mise à niveau locale
ajoute ce rattachement sans supprimer les séances existantes.

Configurez l’URL publique de l’API web à la compilation, sans intégrer de
secret serveur à l’application :

```sh
flutter run --dart-define=MIANARA_API_BASE_URL=https://votre-api.example
```

Le candidat se connecte depuis l’onglet Profil avec les identifiants de son
espace candidat web. L’application n’envoie pas les modifications du profil
local ni les pièces administratives : ces données ne sont pas modifiables par
le protocole de synchronisation mobile. La fréquence réelle d’exécution en
arrière-plan dépend des politiques du système Android/iOS.

## Apprentissage et tutorat

Après connexion, l’onglet Apprendre lit le catalogue approuvé via
`GET /api/mobile/learning`. Les contenus retournés sont mis en cache dans une
migration SQLite additive, par compte candidat ; le contenu complet est gardé
seulement pour les éléments que le serveur a marqués `purchased: true`. Un
cache permet la lecture hors ligne, mais ne confirme jamais un paiement et
n’autorise jamais le chat. Les demandes de paiement Orange Money et les
séances/messages de tutorat requièrent une connexion à l’API.

Les références de transaction sont envoyées par
`POST /api/mobile/coaching/payments`. Les séances et messages utilisent
`GET /api/mobile/coaching/sessions` et les routes `/messages` correspondantes.
Seules les séances actives fournies par le serveur ouvrent le chat. L’interface
du candidat n’affiche pas l’identité du tuteur ou du candidat ; le tutorat
indique uniquement la matière du tuteur. Le numéro marchand Orange Money est
géré par l’administration web et fourni avec le catalogue ; l’application
désactive l’envoi de référence tant que ce numéro n’est pas configuré.

## Portée actuelle

L’application est centrée sur les candidats au Baccalauréat : le profil ne
propose que le Bac, avec les séries générales L, S et OSE ainsi que les séries
techniques TI, TGC, TT et TA du référentiel web. Les anciens codes A/A1/A2
sont normalisés en L et C/D en S à la lecture des profils locaux. L’application
comprend aussi le suivi local du dossier, le tableau de bord et les séances de
révision avec objectif hebdomadaire. Le contenu des cours, exercices et annales
vient du catalogue approuvé par le serveur ; aucun contenu pédagogique fictif
n’est inclus. Les pièces proposées dans la checklist sont l’exemple du cahier
des charges et doivent être validées par les autorités compétentes.

## Vérification

```sh
flutter analyze
flutter test
```
