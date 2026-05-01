import 'package:flutter/material.dart';

/// Reusable extension helpers used across the app.

extension ContextExtensions on BuildContext {
  /// Shorthand for `Theme.of(this)`.
  ThemeData get theme => Theme.of(this);

  /// Shorthand for `Theme.of(this).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shorthand for `Theme.of(this).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shorthand for `MediaQuery.sizeOf(this)`.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Show a snackbar with a message.
  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

extension StringExtensions on String {
  /// Returns the initials from a full name. e.g. "John Doe" → "JD".
  String get initials {
    final parts = trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
