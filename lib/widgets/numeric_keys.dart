import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NumericKeys extends StatelessWidget {
  final Function(int) onNumberPressed;
  final VoidCallback onDeletePressed;

  const NumericKeys({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Standard banking keypad: 1-9, then empty, 0, delete
    final List<int?> items = [1, 2, 3, 4, 5, 6, 7, 8, 9, null, 0];

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 24,
            childAspectRatio: 1.1,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            if (index == 11) {
              return _KeyButton(onPressed: onDeletePressed, child: const Icon(Icons.backspace_outlined, color: AppColors.secondaryBlue, size: 28));
            }
            
            if (index >= items.length) return const SizedBox.shrink();

            final number = items[index];
            if (number == null) return const SizedBox.shrink();
            
            return _KeyButton(
              onPressed: () => onNumberPressed(number),
              child: Text("$number", style: AppStyles.headline(size: 24, weight: FontWeight.bold)),
            );
          },
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _KeyButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: AppColors.primaryRed.withOpacity(0.1),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.containerLow,
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
