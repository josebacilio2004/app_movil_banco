import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/numeric_keys.dart';
import 'identification_screen.dart';
import 'dashboard_screen.dart'; // Importamos el Dashboard

class LoginScreen extends StatefulWidget {
  final String? initialEmail;
  const LoginScreen({super.key, this.initialEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _email;
  String _pin = "";
  bool _loading = false;
  bool _showPin = false;
  String? _enrolledName;
  String? _enrolledCard;

  @override
  void initState() {
    super.initState();
    _email = widget.initialEmail ?? "demo@mibanco.com";
    if (_email.isEmpty) _email = "demo@mibanco.com";
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enrolledName = prefs.getString('enrolled_name');
      _enrolledCard = prefs.getString('enrolled_card');
    });
  }

  void _onNumberPressed(int number) {
    if (_pin.length < 6) {
      print("UI: Número presionado: $number");
      setState(() => _pin += number.toString());
      if (_pin.length == 6) {
        _attemptLogin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _attemptLogin() async {
    print("UI: Intentando login en pantalla para $_email con PIN");
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final error = await auth.login(_email, _pin);
    
    if (error != null && mounted) {
      print("UI ERROR: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $error"),
        backgroundColor: AppColors.errorRed,
      ));
      setState(() {
        _pin = ""; // Reset PIN on error
        _loading = false;
      });
    } else if (mounted) {
      print("UI: Login exitoso. Guardando enrolamiento y navegando...");
      
      try {
        // Guardar enrolamiento para futuras sesiones
        final firestore = context.read<FirestoreService>();
        final prefs = await SharedPreferences.getInstance();
        
        // Obtener datos del perfil para guardar localmente
        if (auth.user != null) {
          final userProfile = await firestore.getUser(auth.user!.uid).first;
          if (userProfile != null) {
            await prefs.setString('enrolled_name', userProfile.nombre);
            await prefs.setString('enrolled_email', userProfile.email);
            
            // Intentar obtener el número de tarjeta/cuenta
            final cuentas = await firestore.getCuentas(auth.user!.uid).first;
            if (cuentas.isNotEmpty) {
              await prefs.setString('enrolled_card', cuentas.first.numero);
            }
          }
        }
      } catch (e) {
        print("Error al guardar enrolamiento: $e");
      }

      if (mounted) {
        // La navegación ocurrirá automáticamente vía AuthWrapper al detectar auth.user != null
        print("UI: Esperando redirección automática a Dashboard...");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String cardSuffix = (_enrolledCard != null && _enrolledCard!.length >= 4) 
        ? "**** ${_enrolledCard!.substring(_enrolledCard!.length - 4)}"
        : "";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Navigator.canPop(context) 
                    ? IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed))
                    : const SizedBox(width: 48),
                  
                  Text("MiBCP", style: AppStyles.headline(size: 24, color: AppColors.primaryRed).copyWith(letterSpacing: -1)),
                  const IconButton(
                    onPressed: null, 
                    icon: Icon(Icons.help_outline, color: AppColors.primaryRed)
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          _enrolledName != null ? "Hola, $_enrolledName" : "Ingresa tu clave de internet", 
                          textAlign: TextAlign.center,
                          style: AppStyles.headline(size: 28)
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _enrolledCard != null ? "Tarjeta $cardSuffix" : "Clave de 6 dígitos", 
                          style: AppStyles.body(size: 16, weight: FontWeight.w500, color: AppColors.secondaryBlue)
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // Lock Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.containerLow, 
                      shape: BoxShape.circle
                    ),
                    child: const Icon(Icons.lock_open_rounded, color: AppColors.primaryRed, size: 36),
                  ),
                  
                  const SizedBox(height: 32),
                  // PIN Indicators
                  RepaintBoundary(child: _buildStitchPinDots()),
                  
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => setState(() => _showPin = !_showPin),
                    icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.secondaryBlue),
                    label: Text(
                      _showPin ? "Ocultar" : "Mostrar", 
                      style: AppStyles.body(size: 14, weight: FontWeight.w600, color: AppColors.secondaryBlue)
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  if (_loading) 
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    ),
                  
                  RepaintBoundary(
                    child: NumericKeys(
                      onNumberPressed: _onNumberPressed,
                      onDeletePressed: _onDeletePressed,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      final auth = context.read<AuthService>();
                      await auth.setEnrolledEmail(null);
                    },
                    child: Text(
                      "¿No eres tú? Cambiar de usuario", 
                      style: AppStyles.body(size: 14, weight: FontWeight.w600, color: AppColors.tertiaryBlue)
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStitchPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primaryRed : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.primaryRed : AppColors.outline.withValues(alpha: 0.3), 
              width: 2
            ),
            boxShadow: isFilled ? [
              BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.2), blurRadius: 4, spreadRadius: 1)
            ] : null,
          ),
          child: (_showPin && isFilled) 
            ? Center(child: Text(_pin[index], style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))
            : null,
        );
      }),
    );
  }
}
