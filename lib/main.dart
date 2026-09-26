import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'data/app_database.dart';
import 'data/sync_service.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

const _syncTask = 'com.example.mianaraMobile.background.sync';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();

  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _syncTask,
      _syncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  runApp(const MianaraApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _syncTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    await AppDatabase.instance.initialize();
    await SyncService.instance.runPendingSync();
    return true;
  });
}

class MianaraApp extends StatelessWidget {
  const MianaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mianara',
      debugShowCheckedModeBanner: false,
      theme: MianaraTheme.light,
      darkTheme: MianaraTheme.dark,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
