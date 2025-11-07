import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class MoodHelpers {
  static String getMoodEmoji(int level) {
    switch (level) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  static String getMoodLabel(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case 1:
        return l10n.veryPoor;
      case 2:
        return l10n.poor;
      case 3:
        return l10n.okay;
      case 4:
        return l10n.good;
      case 5:
        return l10n.excellent;
      default:
        return l10n.okay;
    }
  }

  static Color getMoodColor(int level) {
    switch (level) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen.shade600;
      case 5:
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }
}
