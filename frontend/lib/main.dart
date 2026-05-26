import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:fintech/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fintech/firebase_options.dart';
import 'package:fintech/services/topic_meta_service.dart';
import 'package:fintech/services/app_theme_controller.dart';
import 'package:fintech/services/app_notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _kGoogleSignInServerClientId =
    '819485859824-hvdisjpe9d3lco501fsfag59539h3sob.apps.googleusercontent.com';

Future<void> _initializeGoogleSignIn() async {
  await GoogleSignIn.instance.initialize(
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? DefaultFirebaseOptions.ios.iosClientId
        : null,
    serverClientId: _kGoogleSignInServerClientId,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _initializeGoogleSignIn();
  await TopicMetaService.instance.ensureLoaded();
  await AppNotificationService.instance.initialize();
  await AppThemeController.loadSaved();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.modeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<TextScaler>(
          valueListenable: AppThemeController.textScalerNotifier,
          builder: (context, textScaler, _) {
            return MaterialApp(
              title: 'Monéo',
              themeMode: themeMode,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                scaffoldBackgroundColor: const Color(0xFFF5F7FB),
                cardColor: Colors.white,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF0F172A),
                ),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF7C3AED),
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF0F1020),
                cardColor: const Color(0xFF1B1D33),
                canvasColor: const Color(0xFF17192B),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF17192B),
                  foregroundColor: Colors.white,
                ),
                dividerColor: const Color(0xFF2A2D4A),
                useMaterial3: true,
              ),
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), 
    );
  }
}
