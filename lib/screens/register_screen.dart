import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/stitch_widgets.dart';
import '../widgets/numeric_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form Data
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _cardController = TextEditingController();
  String _pin = "";
  String _confirmPin = "";
  
  bool _loading = false;
  int _cardTabIndex = 0; // 0: Tarjeta, 1: Cuenta

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      // Step validations
      if (_currentStep == 0 && _cardController.text.isEmpty) {
        _showError("Ingresa tu número de ${_cardTabIndex == 0 ? 'tarjeta' : 'cuenta'}");
        return;
      }
      if (_currentStep == 1) {
        if (_nombreController.text.isEmpty) {
          _showError("Ingresa tu nombre");
          return;
        }
        if (Validators.validateEmail(_emailController.text) != null) {
          _showError("Ingresa un correo válido");
          return;
        }
      }
      if (_currentStep == 2 && _pin.length != 6) {
        _showError("Define una clave de 6 dígitos");
        return;
      }

      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed));
  }

  void _finalizeRegister() async {
    if (_pin != _confirmPin) {
      _showError("Las claves no coinciden. Inténtalo de nuevo.");
      setState(() => _confirmPin = ""); // Reset confirm pin on error
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();

    final error = await auth.register(_emailController.text.trim(), _pin);
    
    if (error == null) {
      try {
        final user = UserModel(
          userId: auth.user!.uid,
          nombre: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          fechaRegistro: DateTime.now(),
        );
        final cardNum = _cardController.text.trim().replaceAll(RegExp(r'\D'), '');
        await firestore.createUserProfile(user, customNumber: cardNum);
        
        // Save enrollment locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('enrolled_card', cardNum);
        await prefs.setString('enrolled_email', _emailController.text.trim());
        await prefs.setString('enrolled_name', _nombreController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Registro Exitoso! Bienvenido")));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) _showError("Error al guardar perfil");
      }
    } else {
      if (mounted) _showError(error);
    }
    
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed, size: 28),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
              _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text("REGISTRO SEGURO", style: AppStyles.headline(size: 14, color: AppColors.primaryRed).copyWith(letterSpacing: 2)),
        centerTitle: true,
      ),
      body: RepaintBoundary(
        child: Column(
          children: [
            // Progress Dots (4 steps now)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => _buildProgressDot(index)),
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepIdentity(),
                  _buildStepPersonal(),
                  _buildStepPIN(),
                  _buildStepConfirmPIN(),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: StitchButton(
                text: _currentStep == 3 ? "FINALIZAR REGISTRO" : "CONTINUAR",
                onPressed: _currentStep == 3 ? (_loading ? null : _finalizeRegister) : _nextStep,
                isLoading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    bool active = _currentStep >= index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryRed : AppColors.outline.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Step 1: Card/Account
  Widget _buildStepIdentity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Empecemos", style: AppStyles.headline(size: 30)),
          const SizedBox(height: 8),
          Text("Víncula tu tarjeta de débito o cuenta de ahorro actual.", style: AppStyles.body(color: AppColors.textGray)),
          const SizedBox(height: 48),
          
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.containerLow, borderRadius: AppStyles.radiusXL),
            child: Row(
              children: [
                _buildCardTab("Tarjeta", 0),
                _buildCardTab("Cuenta", 1),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _cardController,
            keyboardType: TextInputType.number,
            style: AppStyles.headline(size: 22, weight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: "NÚMERO DE PRODUCTO",
              hintText: _cardTabIndex == 0 ? "4521 1234 **** ****" : "191-*********",
              filled: true,
              fillColor: AppColors.containerLow,
              border: OutlineInputBorder(borderRadius: AppStyles.radiusXL, borderSide: BorderSide.none),
              prefixIcon: Icon(_cardTabIndex == 0 ? Icons.credit_card : Icons.account_balance_wallet, color: AppColors.secondaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTab(String label, int index) {
    bool active = _cardTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cardTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: AppStyles.radiusXL,
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppStyles.body(size: 14, weight: FontWeight.bold, color: active ? AppColors.primaryRed : AppColors.secondaryBlue.withOpacity(0.4))),
        ),
      ),
    );
  }

  // Step 2: Identity
  Widget _buildStepPersonal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tus datos", style: AppStyles.headline(size: 30)),
          const SizedBox(height: 8),
          Text("Ingresa tu nombre y correo para activar tu perfil digital.", style: AppStyles.body(color: AppColors.textGray)),
          const SizedBox(height: 48),
          
          TextField(
            controller: _nombreController,
            style: AppStyles.headline(size: 18, weight: FontWeight.w600),
            decoration: _buildInputDecor(Icons.person_outline, "Nombre completo"),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppStyles.headline(size: 18, weight: FontWeight.w600),
            decoration: _buildInputDecor(Icons.email_outlined, "Correo electrónico"),
          ),
        ],
      ),
    );
  }

  // Step 3: Create PIN
  Widget _buildStepPIN() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Crea tu clave", style: AppStyles.headline(size: 30)),
                const SizedBox(height: 8),
                Text("Esta clave de 6 dígitos será tu llave de acceso.", style: AppStyles.body(color: AppColors.textGray)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPinDots(_pin),
          const SizedBox(height: 40),
          NumericKeys(
            onNumberPressed: (n) {
              if (_pin.length < 6) setState(() => _pin += n.toString());
            },
            onDeletePressed: () {
              if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Step 4: Confirm PIN
  Widget _buildStepConfirmPIN() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Confirma tu clave", style: AppStyles.headline(size: 30)),
                const SizedBox(height: 8),
                Text("Repite la clave que acabas de crear para evitar errores.", style: AppStyles.body(color: AppColors.textGray)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPinDots(_confirmPin),
          const SizedBox(height: 40),
          NumericKeys(
            onNumberPressed: (n) {
              if (_confirmPin.length < 6) setState(() => _confirmPin += n.toString());
            },
            onDeletePressed: () {
              if (_confirmPin.isNotEmpty) setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPinDots(String pin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primaryRed : Colors.transparent,
            border: Border.all(color: isFilled ? AppColors.primaryRed : AppColors.outline.withOpacity(0.3), width: 2),
          ),
        );
      }),
    );
  }

  InputDecoration _buildInputDecor(IconData icon, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.containerLow,
      border: OutlineInputBorder(borderRadius: AppStyles.radiusXL, borderSide: BorderSide.none),
      prefixIcon: Icon(icon, color: AppColors.secondaryBlue),
    );
  }
}
