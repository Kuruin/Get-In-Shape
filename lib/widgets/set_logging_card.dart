import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../theme/app_theme.dart';
import '../controllers/workout_controller.dart';

class SetLoggingCard extends StatelessWidget {
  final WorkoutController controller;
  final Exercise exercise;
  final String ladderId;
  final int defaultRestSeconds;

  const SetLoggingCard({
    super.key,
    required this.controller,
    required this.exercise,
    required this.ladderId,
    required this.defaultRestSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final sets = controller.getSetsForLadder(ladderId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOG SETS (3 SETS TARGET)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              if (controller.checkProgressionReady(ladderId))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_upward, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Ready to Level Up!',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < sets.length; i++)
            _buildSetRow(context, sets[i], i),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, LoggedSet set, int index) {
    final isDone = set.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDone ? AppColors.surfaceBorder.withValues(alpha: 0.4) : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? AppColors.primary.withValues(alpha: 0.5) : AppColors.surfaceBorder,
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Set number label
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : AppColors.surfaceBorder,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isDone ? Colors.black : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Target hint
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set ${index + 1}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                exercise.isTimed ? '${set.reps}s' : '${set.reps} reps',
                style: TextStyle(
                  color: isDone ? AppColors.primary : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Rep counter steppers
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, size: 22, color: AppColors.textSecondary),
                onPressed: () {
                  if (set.reps > 0) {
                    controller.updateSetReps(ladderId, index, set.reps - 1);
                  }
                },
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text(
                  '${set.reps}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, size: 22, color: AppColors.textSecondary),
                onPressed: () {
                  controller.updateSetReps(ladderId, index, set.reps + 1);
                },
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Complete Button / Rest Trigger
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? AppColors.primary : AppColors.surfaceBorder,
              foregroundColor: isDone ? Colors.black : AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              controller.completeSetAndTriggerRest(
                ladderId: ladderId,
                setIndex: index,
                restSeconds: defaultRestSeconds,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone ? Icons.check_circle : Icons.timer,
                  size: 16,
                  color: isDone ? Colors.black : AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  isDone ? 'Done' : '${defaultRestSeconds}s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDone ? Colors.black : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
