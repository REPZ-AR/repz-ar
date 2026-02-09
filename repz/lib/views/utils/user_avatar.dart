import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Utilities for representing the signed-in Firebase user in the UI.
class UserAvatarUtils {
  static String initialsFor(User user) {
    final name = (user.displayName ?? '').trim();
    if (name.isEmpty) return 'U';

    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';

    final first = parts.first.characters.firstOrNull;
    final last = (parts.length > 1 ? parts.last : parts.first)
        .characters
        .firstOrNull;

    final a = first ?? 'U';
    final b = last ?? '';
    return (a + b).toUpperCase();
  }
}

