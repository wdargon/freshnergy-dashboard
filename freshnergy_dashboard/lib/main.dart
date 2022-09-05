import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:freshnergy_dashboard/boot_screen.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'localize.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsFlutterBinding.ensureInitialized();
    return GlobalLoaderOverlay(
      child: MaterialApp(
          localizationsDelegates: const [
            // ... app-specific localization delegate[s] here
            LocDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('th'), // Thai
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const BootScreen(),
          }
      ),
    );
  }
}

