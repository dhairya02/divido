import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/device_contacts.dart';
import 'services/local_db.dart';
import 'services/local_repository.dart';
import 'state/profile_state.dart';
import 'theme/brand.dart';

/// Minimum time the branded splash stays on screen, so cold launches feel
/// intentional instead of a one-frame flicker on fast devices.
const _minSplashDuration = Duration(milliseconds: 1200);

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
        Provider<DeviceContactsService>(create: (_) => DeviceContactsService()),
        ChangeNotifierProvider<ProfileState>.value(value: profile),
      ],
      child: const DividoApp(),
    ),
  );
}

class DividoApp extends StatefulWidget {
  const DividoApp({super.key});

  @override
  State<DividoApp> createState() => _DividoAppState();
}

class _DividoAppState extends State<DividoApp> {
  late final Future<void> _splashHold;

  @override
  void initState() {
    super.initState();
    _splashHold = Future<void>.delayed(_minSplashDuration);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();

    return MaterialApp(
      title: 'Divido',
      debugShowCheckedModeBanner: false,
      theme: buildBrandTheme(Brightness.light),
      darkTheme: buildBrandTheme(Brightness.dark),
      home: FutureBuilder<void>(
        future: _splashHold,
        builder: (context, snap) {
          final bootstrapping = !profile.ready;
          final stillHoldingSplash =
              snap.connectionState != ConnectionState.done;
          if (bootstrapping || stillHoldingSplash) {
            return SplashScreen(showSpinner: bootstrapping);
          }
          return profile.displayName == null
              ? const WelcomeScreen()
              : const HomeScreen();
        },
      ),
    );
  }
}
