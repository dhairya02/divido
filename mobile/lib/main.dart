import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/local_db.dart';
import 'services/local_repository.dart';
import 'state/profile_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final local = await LocalDatabase.open();
  final repo = LocalRepository(local);
  final profile = ProfileState(repo);
  await profile.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalDatabase>.value(value: local),
        Provider<LocalRepository>.value(value: repo),
        ChangeNotifierProvider<ProfileState>.value(value: profile),
      ],
      child: const DividoApp(),
    ),
  );
}

class DividoApp extends StatelessWidget {
  const DividoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();

    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.dark,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );

    return MaterialApp(
      title: 'Divido',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      home: !profile.ready
          ? const _Splash()
          : profile.displayName == null
              ? const WelcomeScreen()
              : const HomeScreen(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
