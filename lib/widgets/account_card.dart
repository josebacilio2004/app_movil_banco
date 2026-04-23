import 'package:flutter/material.dart';
import '../models/cuenta.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class AccountCard extends StatelessWidget {
  final CuentaModel cuenta;

  const AccountCard({super.key, required this.cuenta});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final isAhorro = cuenta.tipo == 'ahorro';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isAhorro 
              ? [AppColors.secondaryBlue, AppColors.secondaryBlue.withValues(alpha: 0.8)]
              : [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAhorro ? "Cuenta de Ahorros" : "Cuenta Corriente",
                  style: TextStyle(
                    color: isAhorro ? Colors.white70 : AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isAhorro ? Icons.savings_outlined : Icons.account_balance_wallet_outlined,
                  color: isAhorro ? Colors.white70 : AppColors.primaryRed,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cuenta.numero,
              style: TextStyle(
                color: isAhorro ? Colors.white : AppColors.secondaryBlue,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fmt.format(cuenta.saldo),
              style: TextStyle(
                color: isAhorro ? Colors.white : AppColors.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isAhorro && cuenta.metaAhorro != null) ...[
              const SizedBox(height: 16),
              _buildProgress(cuenta),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(CuentaModel acc) {
    final progress = (acc.saldo / acc.metaAhorro!).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Meta: S/ ${acc.metaAhorro}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("$percent%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
