import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../controllers/workout_controller.dart';

class RestTimerBanner extends StatelessWidget {
  final WorkoutController controller;

  const RestTimerBanner({super.key, required this.controller});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (controller.restRemainingSeconds <= 0 && !controller.isTimerRunning) {
      return const SizedBox.shrink();
    }

    final total = controller.restTotalSeconds > 0 ? controller.restTotalSeconds : 90;
    final progress = (controller.restRemainingSeconds / total).clamp(0.0, 1.0);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: controller.isTimerRunning
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.surfaceBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Warm Circular progress indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          controller.restRemainingSeconds <= 5
                              ? AppColors.accentRed
                              : AppColors.primary,
                        ),
                        strokeWidth: 3.5,
                      ),
                    ),
                    Icon(
                      controller.isTimerRunning ? Icons.hourglass_top_rounded : Icons.pause_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Label and Countdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'REST PERIOD',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (!controller.isTimerRunning)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PAUSED',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(controller.restRemainingSeconds),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tactile Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // +30s Pill Button
                    InkWell(
                      onTap: () => controller.addTimerSeconds(30),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '+30s',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: controller.isTimerRunning ? 'Pause' : 'Resume',
                      icon: Icon(
                        controller.isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      onPressed: controller.pauseResumeTimer,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Skip rest',
                      icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                      onPressed: controller.stopRestTimer,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
