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
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;
  String? _enrolledEmail;

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enrolledEmail = prefs.getString('enrolled_email');
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final auth = Provider.of<AuthService>(context);
    
    // 1. Si ya hay sesión activa en Firebase -> Dashboard
    if (auth.user != null) {
      return const DashboardScreen();
    }
    
    // 2. Si hay un usuario registrado localmente -> Directo al PIN
    if (_enrolledEmail != null) {
      return LoginScreen(initialEmail: _enrolledEmail!);
    }
    
    // 3. Fallback: Primer ingreso -> Tarjeta (Identificación)
    return const IdentificationScreen();
  }
}
