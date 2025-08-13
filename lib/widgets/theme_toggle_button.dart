import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeToggleButton extends StatefulWidget {
  final Color? iconColor;

  const ThemeToggleButton({
    super.key,
    this.iconColor,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    _animationController.forward().then((_) {
      ThemeService.instance.toggleTheme();
      _animationController.reset();
    });
  }

  IconData _getIconForTheme() {
    final currentTheme = ThemeService.instance.themeMode;
    switch (currentTheme) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getTooltipForTheme() {
    final currentTheme = ThemeService.instance.themeMode;
    switch (currentTheme) {
      case ThemeMode.light:
        return 'Switch to dark theme';
      case ThemeMode.dark:
        return 'Switch to light theme';
      case ThemeMode.system:
        return 'Using system theme';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, child) {
        return Tooltip(
          message: _getTooltipForTheme(),
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: IconButton(
                  icon: Icon(
                    _getIconForTheme(),
                    color: widget.iconColor,
                  ),
                  onPressed: _toggleTheme,
                ),
              );
            },
          ),
        );
      },
    );
  }
}