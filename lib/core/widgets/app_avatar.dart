import 'dart:convert';
import 'package:flutter/material.dart';

/// A universal, crash-proof avatar widget that renders:
/// 1. Base64 data URLs (`data:image/...;base64,...`) via [Image.memory].
/// 2. Regular HTTP/HTTPS network URLs (Google, Firebase Storage, etc.) via [Image.network].
/// 3. Fallback initials inside a [CircleAvatar] on network/decoding errors.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 20,
    this.fontSize,
  });

  final String? photoUrl;
  final String name;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = name.trim();
    final initials = trimmedName.isNotEmpty
        ? trimmedName.substring(0, 1).toUpperCase()
        : '?';

    final effectiveFontSize = fontSize ?? (radius * 0.85);

    Widget buildInitials() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return buildInitials();
    }

    // 1. Base64 Data URL (data:image/jpeg;base64,...)
    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Data);
        return ClipOval(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => buildInitials(),
            ),
          ),
        );
      } catch (_) {
        return buildInitials();
      }
    }

    // 2. HTTP / HTTPS Network URL
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => buildInitials(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return buildInitials();
          },
        ),
      ),
    );
  }
}

