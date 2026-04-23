import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaccion.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Movimientos Recientes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TransaccionModel>>(
        stream: firestore.getTransacciones(auth.user!.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final txs = snap.data ?? [];
          if (txs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Aún no tienes movimientos", style: TextStyle(color: AppColors.textGray, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: txs.length,
            itemBuilder: (context, index) {
              final tx = txs[index];
              final isDebito = tx.tipo == 'debito';
              final fmt = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
              final dateFmt = DateFormat('dd/MM/yyyy');

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDebito ? AppColors.errorRed.withValues(alpha: 0.05) : AppColors.successGreen.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDebito ? Icons.remove_circle_outline : Icons.add_circle_outline,
                        color: isDebito ? AppColors.errorRed : AppColors.successGreen,
                      ),
                    ),
                    title: Text(tx.descripcion, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.secondaryBlue)),
                    subtitle: Text(dateFmt.format(tx.fecha), style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
                    trailing: Text(
                      "${isDebito ? '-' : '+'} ${fmt.format(tx.monto)}",
                      style: TextStyle(
                        color: isDebito ? AppColors.errorRed : AppColors.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Divider(indent: 70, endIndent: 20, height: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
