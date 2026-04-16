import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/identification_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/solicitud_credito_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'MiBCP Stitch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryRed,
            primary: AppColors.primaryRed,
            surface: AppColors.background,
          ),
          fontFamily: 'Manrope',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.primaryRed),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          "solicitud_credito": (context) => const SolicitudCreditoScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> _getEnrolledEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('enrolled_email');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    // 1. Si ya hay sesión activa en Firebase y NO es anónima -> Dashboard
    if (auth.user != null && !auth.user!.isAnonymous) {
      return const DashboardScreen();
    }
    
    // 2. Si no hay sesión, verificamos enrolamiento local dinámicamente
    return FutureBuilder<String?>(
      future: _getEnrolledEmail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final enrolledEmail = snapshot.data;
        if (enrolledEmail != null) {
          return LoginScreen(initialEmail: enrolledEmail);
        }
        
        // 3. Fallback: Primer ingreso -> Tarjeta (Identificación)
        return const IdentificationScreen();
      }
    );
  }
}
