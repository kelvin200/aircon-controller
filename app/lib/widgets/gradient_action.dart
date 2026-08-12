import 'package:flutter/material.dart';
import '../theme.dart';

/// Pink-to-purple gradient used for primary actions.
const Gradient _gradient = LinearGradient(
  colors: [Color(0xFFF472B6), Color(0xFF8B5CF6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Primary floating action button with a pink-to-purple gradient and a white icon.
class GradientFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const GradientFab({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(panelRadius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(panelRadius),
            border: Border.all(color: AppColors.dark.hairline),
          ),
          child: InkWell(
            onTap: onPressed,
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width primary button with a pink-to-purple gradient and white content.
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const GradientButton({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radiusSm),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined destructive action: transparent coral fill with a coral border.
ButtonStyle dangerButtonStyle() => ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(AppColors.dark.coral),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => AppColors.dark.coral.withValues(
          alpha: states.contains(WidgetState.pressed) ? 0.12 : 0.06,
        ),
      ),
      side: WidgetStatePropertyAll(BorderSide(color: AppColors.dark.coral, width: 1)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
