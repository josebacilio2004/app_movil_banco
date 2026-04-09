import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
import '../models/cuenta.dart';
import '../models/transaccion.dart';
import '../utils/constants.dart';
import '../widgets/stitch_widgets.dart';
import 'payment_screen.dart';
import 'loan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<UserModel?>(
          stream: firestore.getUser(auth.user!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!userSnap.hasData || userSnap.data == null) return _buildErrorState(auth, firestore);
            
            final user = userSnap.data!;

            return Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(user, auth),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => {},
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _buildMainAccount(firestore, user),
                              const SizedBox(height: 32),
                              _buildQuickOperations(),
                              const SizedBox(height: 32),
                              _buildRecentActivityHeader(),
                              const SizedBox(height: 16),
                              _buildRecentActivityList(firestore, user),
                              const SizedBox(height: 32),
                              _buildSavingsPromo(),
                              const SizedBox(height: 120), // Space for bottom nav
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: StitchBottomNav(
                    currentIndex: _navIndex,
                    onTap: (idx) => setState(() => _navIndex = idx),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildTopBar(UserModel user, AuthService auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("BIENVENIDO", style: AppStyles.body(size: 10, weight: FontWeight.bold, color: AppColors.secondaryBlue).copyWith(letterSpacing: 1.5)),
              Text("Hola, ${user.nombre.split(' ')[0]}", style: AppStyles.headline(size: 22)),
            ],
          ),
          Row(
            children: [
              _buildIconButton(Icons.notifications_none_rounded, AppColors.secondaryBlue, () {}),
              const SizedBox(width: 12),
              _buildIconButton(Icons.help_outline_rounded, AppColors.primaryRed, () {}),
              const SizedBox(width: 12),
              _buildIconButton(Icons.logout_rounded, AppColors.secondaryBlue, () => auth.logout()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: AppColors.containerLow, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildMainAccount(FirestoreService firestore, UserModel user) {
    return StreamBuilder<List<CuentaModel>>(
      stream: firestore.getCuentas(user.userId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox(height: 200);
        final mainAcc = snap.data!.firstWhere((a) => a.tipo == 'corriente', orElse: () => snap.data!.first);
        return StitchCard(
          title: "Saldo Disponible",
          amount: "S/ ${NumberFormat("#,##0.00").format(mainAcc.saldo)}",
          number: "**** **** **** ${mainAcc.numero.replaceAll(RegExp(r'[\*\s]'), '').padLeft(4, '0')}",
          holder: user.nombre,
        );
      }
    );
  }

  Widget _buildQuickOperations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("OPERACIONES RÁPIDAS", style: AppStyles.body(size: 12, weight: FontWeight.bold, color: AppColors.secondaryBlue).copyWith(letterSpacing: 1)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildOpItem("Transferir", Icons.sync_alt_rounded, () {}),
            _buildOpItem("Pagar", Icons.receipt_long_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()))),
            _buildOpItem("Recargar", Icons.phone_iphone_rounded, () {}),
            _buildOpItem("Préstamos", Icons.monetization_on_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanScreen()))),
          ],
        ),
      ],
    );
  }

  Widget _buildOpItem(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.containerLow, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: AppColors.primaryRed, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppStyles.body(size: 11, weight: FontWeight.w600, color: AppColors.secondaryBlue)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("ACTIVIDAD RECIENTE", style: AppStyles.headline(size: 18)),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.expand_more, size: 16),
          label: Text("Este mes", style: AppStyles.body(size: 12, weight: FontWeight.bold, color: AppColors.secondaryBlue)),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryBlue),
        )
      ],
    );
  }

  Widget _buildRecentActivityList(FirestoreService firestore, UserModel user) {
    return StreamBuilder<List<TransaccionModel>>(
      stream: firestore.getTransacciones(user.userId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final txs = snap.data!.take(3).toList();
        if (txs.isEmpty) return const Text("No hay movimientos recientes");
        
        return Column(
          children: txs.map((tx) => _buildTxItem(tx)).toList(),
        );
      }
    );
  }

  Widget _buildTxItem(TransaccionModel tx) {
    bool isCredit = tx.tipo == 'credito';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCredit ? AppColors.tertiaryBlue.withOpacity(0.1) : AppColors.secondaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle
                ),
                child: Icon(
                  isCredit ? Icons.trending_up_rounded : Icons.shopping_bag_outlined, 
                  color: isCredit ? AppColors.tertiaryBlue : AppColors.secondaryBlue, 
                  size: 24
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.descripcion, style: AppStyles.body(size: 14, weight: FontWeight.bold)),
                  Text(
                    "${DateFormat("d MMM").format(tx.fecha)} • ${_getCategory(tx.descripcion)}", 
                    style: AppStyles.body(size: 12, color: AppColors.textGray.withOpacity(0.6))
                  ),
                ],
              ),
            ],
          ),
          Text(
            "${isCredit ? '+' : '-'} S/ ${NumberFormat("#,##0.00").format(tx.monto)}",
            style: AppStyles.headline(size: 15, color: isCredit ? AppColors.tertiaryBlue : AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  String _getCategory(String desc) {
    if (desc.contains("Wong")) return "Compras";
    if (desc.contains("Abono")) return "Ingresos";
    if (desc.contains("Celular")) return "Servicios";
    return "Otros";
  }

  Widget _buildSavingsPromo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryBlue.withOpacity(0.05),
        borderRadius: AppStyles.radius3XL,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ahorra para tu meta", style: AppStyles.headline(size: 18, color: AppColors.secondaryBlue)),
              const SizedBox(height: 8),
              Text(
                "Tu Alcancía BCP tiene una nueva tasa de 4.5% TREA.", 
                style: AppStyles.body(size: 13, color: AppColors.secondaryBlue.withOpacity(0.8))
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusFull),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text("Empezar ahora", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          Positioned(
            right: -10,
            bottom: -20,
            child: Icon(Icons.savings_outlined, size: 100, color: AppColors.secondaryBlue.withOpacity(0.05)),
          )
        ],
      ),
    );
  }

  Widget _buildErrorState(AuthService auth, FirestoreService firestore) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle_outlined, size: 80, color: AppColors.primaryRed),
          const SizedBox(height: 24),
          Text("Perfil incompleto", style: AppStyles.headline(size: 20)),
          const SizedBox(height: 12),
          Text(
            "Tu usuario existe pero no encontramos tus datos financieros. Esto sucede si hubo un error de conexión durante el registro.",
            textAlign: TextAlign.center,
            style: AppStyles.body(color: AppColors.textGray),
          ),
          const SizedBox(height: 32),
          StitchButton(
            text: "REPARAR Y ACTIVAR CUENTA", 
            onPressed: () async {
               final user = UserModel(
                 userId: auth.user!.uid,
                 nombre: "Usuario MiBCP",
                 email: auth.user!.email ?? "demo@mibanco.com",
                 fechaRegistro: DateTime.now(),
               );
               await firestore.createUserProfile(user);
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => auth.logout(), 
            child: Text("Cerrar sesión", style: TextStyle(color: AppColors.textGray.withOpacity(0.5))),
          ),
        ],
        ),
      ),
    );
  }
}
