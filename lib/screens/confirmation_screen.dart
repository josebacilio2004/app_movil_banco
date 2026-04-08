import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class ConfirmationScreen extends StatelessWidget {
  final String servicio;
  final double monto;
  final String contrato;

  const ConfirmationScreen({
    super.key,
    required this.servicio,
    required this.monto,
    required this.contrato,
  });

  void _compartir() {
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    Share.share("BCP MiPortal - Comprobante Digital:\nPago de S/ ${monto.toStringAsFixed(2)} a $servicio (Contrato: $contrato) realizado exitosamente el $now.\nOperación: ${DateTime.now().millisecondsSinceEpoch}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.check_circle, size: 100, color: AppColors.successGreen),
              const SizedBox(height: 24),
              const Text("¡OPERACIÓN EXITOSA!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue, letterSpacing: 1.1)),
              const SizedBox(height: 8),
              const Text("Tu pago ha sido procesado correctamente.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGray)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.containerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildDetail("Servicio:", servicio),
                    const Divider(height: 24),
                    _buildDetail("Nro Contrato:", contrato),
                    const Divider(height: 24),
                    _buildDetail("Importe:", "S/ ${monto.toStringAsFixed(2)}"),
                    const Divider(height: 24),
                    _buildDetail("Fecha:", DateFormat('dd/MM/yyyy').format(DateTime.now())),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _compartir,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text("COMPARTIR CONSTANCIA", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("IR AL INICIO", style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondaryBlue)),
      ],
    );
  }
}
