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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: controller.isTimerRunning ? AppColors.primary : AppColors.surfaceBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Circular progress indicator with remaining seconds inside
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surfaceBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        controller.restRemainingSeconds <= 5
                            ? AppColors.accentRed
                            : AppColors.primary,
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                  Icon(
                    controller.isTimerRunning ? Icons.timer_outlined : Icons.pause_circle_outline,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Time and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'REST INTERVAL',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (!controller.isTimerRunning)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PAUSED',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(controller.restRemainingSeconds),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // +30s Button
                  IconButton(
                    tooltip: 'Add 30 seconds',
                    icon: const Text(
                      '+30s',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () => controller.addTimerSeconds(30),
                  ),
                  // Play/Pause
                  IconButton(
                    tooltip: controller.isTimerRunning ? 'Pause timer' : 'Resume timer',
                    icon: Icon(
                      controller.isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: controller.pauseResumeTimer,
                  ),
                  // Skip
                  IconButton(
                    tooltip: 'Skip rest',
                    icon: const Icon(Icons.skip_next_rounded, color: AppColors.textMuted),
                    onPressed: controller.stopRestTimer,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                controller.restRemainingSeconds <= 5
                    ? AppColors.accentRed
                    : AppColors.primary,
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
