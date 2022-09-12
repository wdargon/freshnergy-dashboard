import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:freshnergy_dashboard/boot_screen.dart';
import 'package:freshnergy_dashboard/data_screen.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'localize.dart';


// Change to false to use live database instance.
const USE_DATABASE_EMULATOR = false;
// The port we've set the Firebase Database emulator to run on via the
// `firebase.json` configuration file.
const emulatorPort = 9000;
final emulatorHost =
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? '10.0.2.2'
        : 'localhost';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (USE_DATABASE_EMULATOR) {
    FirebaseDatabase.instance.useDatabaseEmulator(emulatorHost, emulatorPort);
  }
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
          debugShowCheckedModeBanner: false,
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
            '/': (context) => const DataScreen(),
          }
      ),
    );
  }
}

