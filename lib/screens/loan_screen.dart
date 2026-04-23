import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/prestamo.dart';
import '../utils/constants.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  double _monto = 5000;
  int _plazo = 12;
  bool _loading = false;

  double get _cuota {
    // Simulación de cuota con interés del 5% anual
    double interesAnual = 0.05;
    double totalAPagar = _monto * (1 + interesAnual);
    return totalAPagar / _plazo;
  }

  void _solicitar() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    if (auth.user == null) return;

    final prestamo = PrestamoModel(
      prestamoId: '',
      userId: auth.user!.uid,
      monto: _monto,
      plazo: _plazo,
      cuotaMensual: _cuota,
      estado: 'pendiente',
      fechaSolicitud: DateTime.now(),
    );

    try {
      await firestore.solicitarPrestamo(prestamo);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 60),
            content: const Text(
              "Tu solicitud de préstamo ha sido enviada y se encuentra en estado 'Pendiente' para evaluación.",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos watch para reaccionar al logout y redibujar si el usuario es null
    final auth = context.watch<AuthService>();
    final currentUser = auth.user;

    // Si no hay sesión, retornamos cargando mientras el Navigator actúa
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Préstamos Personales", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Cuánto dinero necesitas?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Text("MONTO A SOLICITAR", style: TextStyle(color: AppColors.textGray, fontSize: 12, letterSpacing: 1.2)),
                  Text("S/ ${_monto.toInt()}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _monto,
              min: 1000,
              max: 50000,
              divisions: 49,
              activeColor: AppColors.primaryRed,
              inactiveColor: AppColors.containerLow,
              onChanged: (val) => setState(() => _monto = (val / 1000).round() * 1000.0),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("S/ 1,000", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
                Text("S/ 50,000", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 40),
            const Text("¿En cuántos meses deseas pagar?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _plazo,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              items: [6, 12, 18, 24, 36].map((p) => DropdownMenuItem(value: p, child: Text("$p meses"))).toList(),
              onChanged: (val) => setState(() => _plazo = val!),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.secondaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondaryBlue.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Text("TU CUOTA MENSUAL SERÁ DE:", style: TextStyle(color: AppColors.textGray, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("S/ ${_cuota.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
                  const SizedBox(height: 4),
                  const Text("*TCEA referencial 5.0%", style: TextStyle(color: AppColors.textGray, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _solicitar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("SOLICITAR AHORA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
