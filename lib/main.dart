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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    // 0. Si el sistema de sesión aún no ha cargado el enrolamiento (null inicial vs null real)
    // El AuthService carga el enrolamiento en el constructor, pero es asíncrono.
    // Aunque notifyListeners se llamará, si queremos ser deterministas:
    // Pero por simplicidad, confiamos en notifyListeners().

    // 1. Si hay sesión activa real (no anónima) -> Dashboard
    if (auth.user != null && !auth.user!.isAnonymous) {
      return const DashboardScreen();
    }
    
    // 2. Si no hay sesión, pero tenemos correo enrolado localmente -> Login (PIN)
    if (auth.enrolledEmail != null) {
      return LoginScreen(initialEmail: auth.enrolledEmail!);
    }
    
    // 3. Primer ingreso o sesión anónima en curso -> Identificación
    return const IdentificationScreen();
  }
}
