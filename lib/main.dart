import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'admin/screens/admin_screen.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'user/screens/user_screen.dart';
import 'utils/app_theme.dart';

const apiKey = 'AIzaSyAwjcN3Aei78CJ6YP2Ok-W47i-Z_5k_5EE';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeManager = ThemeManager();
  await themeManager.loadTheme();


  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize('6ebc33e0-21f7-4380-867f-9a6c8c9220e9');
  OneSignal.Notifications.requestPermission(true);

  // Initialize Gemini
  Gemini.init(apiKey: apiKey);

  Widget home;
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final adminSnapshot = await FirebaseFirestore.instance
        .collection('admin')
        .where('email', isEqualTo: user.email)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      home = const AdminScreen();
    } else {
      home = UserScreen();
    }
  } else {
    home = const LoginScreen();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeManager,
      child: MyApp(home: home),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return MaterialApp(
      themeMode: themeManager.themeMode,
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}
