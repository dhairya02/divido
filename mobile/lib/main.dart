import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/local_db.dart';
import 'services/local_repository.dart';
import 'state/profile_state.dart';
import 'theme/brand.dart';
import 'widgets/brand_logo.dart';

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

    return MaterialApp(
      title: 'Divido',
      debugShowCheckedModeBanner: false,
      theme: buildBrandTheme(Brightness.light),
      darkTheme: buildBrandTheme(Brightness.dark),
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
    return Scaffold(
      backgroundColor: BrandColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            BrandMark(height: 56),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
