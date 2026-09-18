import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows the app version and build number with tabular figures and a subtle muted tone.
class VersionIndicator extends StatelessWidget {
  static const String appName = 'BWF Routine';
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  final bool showAppName;

  const VersionIndicator({
    super.key,
    this.showAppName = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = showAppName
        ? '$appName v$version ($buildNumber)'
        : 'v$version ($buildNumber)';

    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFeatures: [FontFeature.tabularFigures()],
        color: AppColors.stoneMuted,
        letterSpacing: 0.2,
      ),
    );
  }
}
