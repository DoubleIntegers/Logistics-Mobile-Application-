import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/auth_controller.dart';
import 'controllers/delivery_controller.dart';
import 'controllers/order_controller.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_screen.dart';

// ── Background FCM handler (top-level, wajib) ──────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
  await firebaseBackgroundMessageHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  // await Firebase.initializeApp();

  // 2. Supabase
  await Supabase.initialize(
    url: 'https://tctnruxotyxbvjldxbzw.supabase.co/rest/v1/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjdG5ydXhvdHl4YnZqbGR4Ynp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNTMzMjEsImV4cCI6MjA5MzYyOTMyMX0.RfhUWTspmJ2_FOP-eAsXTwYBrWRxtYDCgOTgiEj-czk',
  );

  // 3. FCM Background handler (daftarkan sebelum runApp)
  // FirebaseMessaging.onBackgroundMessage(
  //     _firebaseMessagingBackgroundHandler);

  // 4. Notification Service
  // await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => DeliveryController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeCtrl, _) {
        return MaterialApp(
          title: 'LogiTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeCtrl.themeMode,
          // ← Pasang scaffoldMessengerKey untuk Snackbar dari service
          scaffoldMessengerKey:
              NotificationService.scaffoldMessengerKey,
          home: const MainScreen(),
        );
      },
    );
  }
}