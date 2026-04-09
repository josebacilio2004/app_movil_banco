import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/stitch_widgets.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdentificationScreen extends StatefulWidget {
  const IdentificationScreen({super.key});

  @override
  State<IdentificationScreen> createState() => _IdentificationScreenState();
}

class _IdentificationScreenState extends State<IdentificationScreen> {
  int _tabIndex = 0; // 0: Tarjeta, 1: Cuenta
  final _idController = TextEditingController();
  String? _enrolledCard;
  String? _enrolledEmail;
  String? _enrolledName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enrolledCard = prefs.getString('enrolled_card');
        _enrolledEmail = prefs.getString('enrolled_email');
        _enrolledName = prefs.getString('enrolled_name');
        if (_enrolledCard != null) {
          _idController.text = _enrolledCard!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RepaintBoundary(
          child: Column(
            children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryRed),
                  ),
                  Text("MiBCP", style: AppStyles.headline(size: 24, color: AppColors.primaryRed).copyWith(letterSpacing: -1)),
                  const Icon(Icons.help_outline, color: AppColors.secondaryBlue),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      _enrolledName != null ? "Hola, $_enrolledName" : "Bienvenido a MiBCP", 
                      style: AppStyles.headline(size: 34)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _enrolledName != null ? "Confirma tu identidad para continuar" : "Ingresa tu número de tarjeta o cuenta", 
                      style: AppStyles.body(size: 16, color: AppColors.secondaryBlue.withOpacity(0.8))
                    ),
                    
                    const SizedBox(height: 40),
                    // Toggle Component from Stitch
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.containerLow, borderRadius: AppStyles.radiusXL),
                      child: Row(
                        children: [
                          _buildTab("Tarjeta", 0),
                          _buildTab("Cuenta", 1),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    // Input Component
                    Text("NÚMERO DE ${_tabIndex == 0 ? 'TARJETA' : 'CUENTA'}", 
                      style: AppStyles.body(size: 11, weight: FontWeight.bold).copyWith(letterSpacing: 2, color: AppColors.secondaryBlue.withOpacity(0.7))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _idController,
                      style: AppStyles.headline(size: 20, weight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _tabIndex == 0 ? "**** **** **** 1234" : "191-*********",
                        hintStyle: TextStyle(color: AppColors.onSurface.withOpacity(0.2)),
                        filled: true,
                        fillColor: AppColors.containerHighest,
                        border: OutlineInputBorder(borderRadius: AppStyles.radiusXL, borderSide: BorderSide.none),
                        suffixIcon: Icon(_tabIndex == 0 ? Icons.credit_card : Icons.account_balance_outlined, color: AppColors.secondaryBlue),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    StitchButton(
                      text: "Continuar", 
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : () async {
                         String query = _idController.text.trim();
                         if (query.isEmpty) return;

                         setState(() => _isLoading = true);
                         String? loginEmail;
                         
                         // 1. Verificar coincidencia local (acelerar si es el mismo dispositivo)
                         if (_enrolledCard != null && query == _enrolledCard && _enrolledEmail != null) {
                           loginEmail = _enrolledEmail!;
                         } 
                         
                         // 2. Si no coincide localmente, buscar en Firestore
                         if (loginEmail == null) {
                           // Si ya es un email, lo usamos directamente
                           if (query.contains('@')) {
                             loginEmail = query;
                           } else {
                             // Buscar email por tarjeta/cuenta
                             final firestore = context.read<FirestoreService>();
                             loginEmail = await firestore.getEmailByCardNumber(query);
                           }
                         }

                         if (mounted) setState(() => _isLoading = false);

                         if (loginEmail != null) {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(initialEmail: loginEmail)));
                         } else {
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                               content: Text("No se encontró una cuenta asociada a este número"),
                               backgroundColor: AppColors.errorRed,
                             ));
                           }
                         }
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppColors.secondaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.fingerprint, color: AppColors.secondaryBlue, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Text("Usar huella digital", style: AppStyles.body(size: 14, weight: FontWeight.w600, color: AppColors.secondaryBlue)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Divider(height: 1, color: Colors.black12),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                            child: Text("¿No tienes tarjeta? Regístrate aquí", style: AppStyles.body(size: 14, weight: FontWeight.w600, color: AppColors.tertiaryBlue)),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Security Badge
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, size: 18, color: AppColors.secondaryBlue),
                  const SizedBox(width: 8),
                  Text("CONEXIÓN 100% SEGURA", style: AppStyles.body(size: 10, weight: FontWeight.bold).copyWith(letterSpacing: 1.2, color: AppColors.secondaryBlue.withOpacity(0.4))),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    bool active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: AppStyles.radiusXL,
            boxShadow: active ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppStyles.body(size: 14, weight: FontWeight.bold, color: active ? AppColors.primaryRed : AppColors.secondaryBlue.withOpacity(0.4))),
        ),
      ),
    );
  }
}
