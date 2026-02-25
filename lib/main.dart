import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/medication_controller.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- CORRECTION : INITIALISATION NON BLOQUANTE ---
  final notificationService = NotificationService();
  notificationService.init(); 

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => MedicationController()),
        // On utilise l'instance déjà initialisée
        ChangeNotifierProvider.value(value: notificationService), 
      ],
      child: const MedicationApp(),
    ),
  );
}

class MedicationApp extends StatelessWidget {
  const MedicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DAWA',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeView();
        }
        return LoginView();
      },
    );
  }
}