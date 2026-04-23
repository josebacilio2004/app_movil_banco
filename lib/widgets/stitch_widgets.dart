import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StitchButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const StitchButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primaryRed : AppColors.surface,
          foregroundColor: isPrimary ? Colors.white : AppColors.secondaryBlue,
          disabledBackgroundColor: isPrimary ? AppColors.primaryRed.withValues(alpha: 0.4) : null,
          shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusFull),
          elevation: 0, // Flat design
          side: isPrimary ? null : BorderSide(color: Colors.grey[200]!, width: 1.5),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                text,
                style: AppStyles.headline(size: 16, color: isPrimary ? Colors.white : AppColors.secondaryBlue),
              ),
      ),
    );
  }
}

class StitchCard extends StatelessWidget {
  final String title;
  final String amount;
  final String number;
  final String holder;

  const StitchCard({
    super.key,
    required this.title,
    required this.amount,
    required this.number,
    required this.holder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryRed, // Flat color like NuBank instead of gradient
        borderRadius: AppStyles.radius3XL,
        boxShadow: AppStyles.cardShadow, // Softer shadow
      ),
      child: Stack(
        children: [
          // Glassmorphism circles
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toUpperCase(), style: AppStyles.body(size: 10, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.bold).copyWith(letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text(amount, style: AppStyles.headline(size: 32, color: Colors.white)),
                    ],
                  ),
                  const Text("BCP", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(number, style: AppStyles.headline(size: 18, color: Colors.white).copyWith(letterSpacing: 4)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("TITULAR", style: AppStyles.body(size: 9, color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.bold)),
                          Text(holder.toUpperCase(), style: AppStyles.body(size: 14, color: Colors.white, weight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(
                        width: 45,
                        height: 30,
                        child: Stack(
                          children: [
                            Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2))),
                            Positioned(
                              left: 15,
                              child: Container(width: 30, height: 30, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.4))),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class StitchBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StitchBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98), // Solid color for performance
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, "Home"),
          _buildNavItem(1, Icons.payments_rounded, "Pagos"),
          _buildNavItem(2, Icons.account_balance_wallet_rounded, "Banca"),
          _buildNavItem(3, Icons.settings_rounded, "Más"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool active = index == currentIndex;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? AppColors.primaryRed : AppColors.secondaryBlue, size: 28),
          const SizedBox(height: 4),
          Text(label, style: AppStyles.body(size: 11, weight: active ? FontWeight.bold : FontWeight.normal, color: active ? AppColors.primaryRed : AppColors.secondaryBlue)),
        ],
      ),
    );
  }
}
