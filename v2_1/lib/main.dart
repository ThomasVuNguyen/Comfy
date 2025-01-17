import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v2_1/themes/color_schemes.dart';
import 'package:v2_1/themes/typography.dart';

import 'comfyauth/authentication/auth.dart';
import 'firebase_options.dart';

Future<void> main() async {
  //initializing firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  //firebase initializing finished, run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          useMaterial3: true, colorScheme: lightColorScheme,
          textTheme: ComfyTextTheme,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          //darkColorScheme,
          textTheme: ComfyTextTheme,
        ),
        debugShowCheckedModeBanner: false,
        home: const auth_page(welcomePage: true,)
    );
  }
}


