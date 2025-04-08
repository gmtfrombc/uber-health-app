import 'package:flutter/material.dart';
import '../theme.dart'; // Import theme to access backButtonIcon

/// A custom app bar that ensures consistent back button appearance
/// across all screens in the app
class ConsistentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const ConsistentAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Use the theme colors if not specified
    final theme = Theme.of(context);
    final effectiveBackground =
        backgroundColor ?? theme.appBarTheme.backgroundColor;
    final effectiveForeground =
        foregroundColor ?? theme.appBarTheme.foregroundColor;

    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: effectiveBackground,
      foregroundColor: effectiveForeground,
      elevation: elevation,
      bottom: bottom,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      // Use a custom back button with consistent appearance
      leading:
          leading ??
          (automaticallyImplyLeading && Navigator.of(context).canPop()
              ? IconButton(
                icon: Icon(
                  AppTheme
                      .backButtonIcon, // Use consistent back arrow icon from AppTheme
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
              : null),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
