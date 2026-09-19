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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SETS TO COMPLETE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              if (controller.checkProgressionReady(ladderId))
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Ready to Level Up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < sets.length; i++)
            _buildSetRow(context, sets[i], i),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, LoggedSet set, int index) {
    final isDone = set.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.surfaceBorder.withValues(alpha: 0.3)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.surfaceBorder,
          width: isDone ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Set number circle
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
                color: isDone ? AppColors.onPrimary : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Target label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set ${index + 1}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                exercise.isTimed ? '${set.reps}s' : '${set.reps} reps',
                style: TextStyle(
                  color: isDone ? AppColors.primary : AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Minimalist Rep Stepper
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    if (set.reps > 0) {
                      controller.updateSetReps(ladderId, index, set.reps - 1);
                    }
                  },
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Icon(Icons.remove, size: 16, color: AppColors.textSecondary),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  alignment: Alignment.center,
                  child: Text(
                    '${set.reps}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    controller.updateSetReps(ladderId, index, set.reps + 1);
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Icon(Icons.add, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Complete Button / Rest Trigger
          InkWell(
            onTap: () {
              controller.completeSetAndTriggerRest(
                ladderId: ladderId,
                setIndex: index,
                restSeconds: defaultRestSeconds,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDone ? AppColors.primary : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone ? Icons.check_rounded : Icons.timer_outlined,
                    size: 15,
                    color: isDone ? AppColors.onPrimary : AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isDone ? 'Done' : '${defaultRestSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDone ? AppColors.onPrimary : AppColors.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
