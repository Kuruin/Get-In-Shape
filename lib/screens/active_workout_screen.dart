import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../data/bwf_routine_data.dart';
import '../controllers/workout_controller.dart';
import '../widgets/rest_timer_banner.dart';
import '../widgets/exercise_card.dart';
import '../widgets/set_logging_card.dart';
import 'progression_ladder_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutController controller;

  const ActiveWorkoutScreen({super.key, required this.controller});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _selectedPairSubIndex = 0; // 0 for Exercise A, 1 for Exercise B (or 0, 1, 2 for Triplet)
  final TextEditingController _notesController = TextEditingController();

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Discard Workout?'),
        content: const Text('All progress for this session will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Going', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () {
              Navigator.pop(ctx);
              widget.controller.discardWorkout();
              Navigator.pop(context);
            },
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final session = widget.controller.activeSession;
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('No active workout')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Discard workout',
              onPressed: _confirmDiscard,
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(session.durationSeconds),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  widget.controller.advanceStage();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.controller.currentStage == WorkoutStage.coreTriplet
                          ? 'Finish'
                          : 'Next',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Stages Progress Tabs
              _buildStageSelector(),

              // Main Body depending on current Stage
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStageContent(),
                ),
              ),

              // Rest timer banner stays pinned at bottom when active
              RestTimerBanner(controller: widget.controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStageSelector() {
    final stages = [
      {'stage': WorkoutStage.warmup, 'name': 'Warm-up'},
      {'stage': WorkoutStage.firstPair, 'name': 'Pair 1'},
      {'stage': WorkoutStage.secondPair, 'name': 'Pair 2'},
      {'stage': WorkoutStage.thirdPair, 'name': 'Pair 3'},
      {'stage': WorkoutStage.coreTriplet, 'name': 'Core'},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = stages[index]['stage'] as WorkoutStage;
          final name = stages[index]['name'] as String;
          final isCurrent = widget.controller.currentStage == s;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPairSubIndex = 0;
              });
              widget.controller.setStage(s);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? AppColors.primary : AppColors.surfaceBorder,
                ),
              ),
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isCurrent ? Colors.black : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageContent() {
    switch (widget.controller.currentStage) {
      case WorkoutStage.warmup:
        return _buildWarmupStage();
      case WorkoutStage.firstPair:
        return _buildPairStage(
          ladderA: BwfRoutineData.pullupLadder,
          ladderB: BwfRoutineData.squatLadder,
          pairTitle: 'FIRST PAIR: PULL-UP & SQUAT',
        );
      case WorkoutStage.secondPair:
        return _buildPairStage(
          ladderA: BwfRoutineData.dipLadder,
          ladderB: BwfRoutineData.hingeLadder,
          pairTitle: 'SECOND PAIR: DIP & HINGE',
        );
      case WorkoutStage.thirdPair:
        return _buildPairStage(
          ladderA: BwfRoutineData.rowLadder,
          ladderB: BwfRoutineData.pushupLadder,
          pairTitle: 'THIRD PAIR: ROW & PUSH-UP',
        );
      case WorkoutStage.coreTriplet:
        return _buildTripletStage();
      case WorkoutStage.completed:
        return _buildCompletionStage();
    }
  }

  // --- 1. WARMUP STAGE ---
  Widget _buildWarmupStage() {
    final session = widget.controller.activeSession!;
    final total = BwfRoutineData.warmups.length;
    final completed = session.completedWarmups.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BWF MOBILITY & WARM-UP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '$completed / $total completed',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Prepare your joints, nervous system, and scapulae before loading.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: widget.controller.markAllWarmupsCompleted,
                      child: const Text('Mark All Done'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => widget.controller.advanceStage(),
                      child: const Text('Start Pair 1'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...BwfRoutineData.warmups.map((w) {
          final isDone = session.completedWarmups.contains(w.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDone ? AppColors.surfaceBorder.withValues(alpha: 0.3) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDone ? AppColors.primary.withValues(alpha: 0.6) : AppColors.surfaceBorder,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Checkbox(
                value: isDone,
                activeColor: AppColors.primary,
                checkColor: Colors.black,
                onChanged: (_) => widget.controller.toggleWarmup(w.id),
              ),
              title: Text(
                w.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${w.prescription} • ${w.target}',
                    style: const TextStyle(fontSize: 12, color: AppColors.accentCyan),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    w.instructions,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        }),
      ],
    );
  }

  // --- 2. PAIR STAGE RUNNER (PAIR 1, 2, 3) ---
  Widget _buildPairStage({
    required ProgressionLadder ladderA,
    required ProgressionLadder ladderB,
    required String pairTitle,
  }) {
    final exerciseA = widget.controller.getSelectedExerciseForLadder(ladderA.id);
    final exerciseB = widget.controller.getSelectedExerciseForLadder(ladderB.id);
    final currentLadder = _selectedPairSubIndex == 0 ? ladderA : ladderB;
    final currentExercise = _selectedPairSubIndex == 0 ? exerciseA : exerciseB;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Protocol explanation banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.sync_alt_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$pairTitle\nAlternate sets between A and B with 90s rest.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Alternating Exercise Switcher Tabs
        Row(
          children: [
            Expanded(
              child: _buildSubExerciseTab(
                title: 'A: ${ladderA.title.replaceAll(" Progression", "")}',
                exerciseName: exerciseA.name,
                ladderId: ladderA.id,
                isSelected: _selectedPairSubIndex == 0,
                onTap: () => setState(() => _selectedPairSubIndex = 0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSubExerciseTab(
                title: 'B: ${ladderB.title.replaceAll(" Progression", "")}',
                exerciseName: exerciseB.name,
                ladderId: ladderB.id,
                isSelected: _selectedPairSubIndex == 1,
                onTap: () => setState(() => _selectedPairSubIndex = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Active Exercise Card
        ExerciseCard(
          exercise: currentExercise,
          ladderTitle: currentLadder.title,
          totalLevels: currentLadder.exercises.length,
          onSwitchProgression: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProgressionLadderScreen(
                  controller: widget.controller,
                  initialLadderId: currentLadder.id,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Set Logging Card with rest timer triggers
        SetLoggingCard(
          controller: widget.controller,
          exercise: currentExercise,
          ladderId: currentLadder.id,
          defaultRestSeconds: currentLadder.defaultRestSeconds,
        ),
        const SizedBox(height: 20),

        // Advance to next pair button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.controller.advanceStage(),
            child: Text(
              widget.controller.currentStage == WorkoutStage.thirdPair
                  ? 'Proceed to Core Triplet'
                  : 'Proceed to Next Pair',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubExerciseTab({
    required String title,
    required String exerciseName,
    required String ladderId,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final sets = widget.controller.getSetsForLadder(ladderId);
    final completedCount = sets.where((s) => s.isCompleted).length;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
                Text(
                  '$completedCount/3',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: completedCount == 3 ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              exerciseName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. CORE TRIPLET STAGE ---
  Widget _buildTripletStage() {
    final ladders = [
      BwfRoutineData.antiExtensionLadder,
      BwfRoutineData.antiRotationLadder,
      BwfRoutineData.extensionLadder,
    ];
    final currentLadder = ladders[_selectedPairSubIndex.clamp(0, 2)];
    final currentExercise = widget.controller.getSelectedExerciseForLadder(currentLadder.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: const [
              Icon(Icons.loop_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CORE TRIPLET CIRCUIT\nPerform 1 set of each in order, with 60s rest after each set (3 rounds total).',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3-way tabs for Core Triplet
        Row(
          children: [
            for (int i = 0; i < ladders.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPairSubIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: _selectedPairSubIndex == i ? AppColors.surfaceElevated : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedPairSubIndex == i ? AppColors.primary : AppColors.surfaceBorder,
                        width: _selectedPairSubIndex == i ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          i == 0 ? 'Anti-Ext' : i == 1 ? 'Anti-Rot' : 'Extension',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _selectedPairSubIndex == i ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        ExerciseCard(
          exercise: currentExercise,
          ladderTitle: currentLadder.title,
          totalLevels: currentLadder.exercises.length,
          onSwitchProgression: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProgressionLadderScreen(
                  controller: widget.controller,
                  initialLadderId: currentLadder.id,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        SetLoggingCard(
          controller: widget.controller,
          exercise: currentExercise,
          ladderId: currentLadder.id,
          defaultRestSeconds: 60,
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.controller.advanceStage(),
            child: const Text('Complete BWF Workout'),
          ),
        ),
      ],
    );
  }

  // --- 4. COMPLETION STAGE ---
  Widget _buildCompletionStage() {
    final session = widget.controller.activeSession!;
    final totalReps = session.totalReps;
    final setsDone = session.completedSetCount;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 40, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'WORKOUT COMPLETE!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Authentic Reddit BWF Recommended Routine finished.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),

        // Metrics Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'DURATION',
                value: _formatDuration(session.durationSeconds),
                icon: Icons.timer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'SETS LOGGED',
                value: '$setsDone',
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'TOTAL REPS',
                value: '$totalReps',
                icon: Icons.repeat_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Progression Upgrades Check
        _buildLevelUpSection(),
        const SizedBox(height: 20),

        // Notes Input
        const Text(
          'WORKOUT NOTES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'How did the sets feel? Any tweaks or PRs?',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Finish Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              await widget.controller.finishWorkout(notes: _notesController.text);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save & Back to Home'),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelUpSection() {
    final readyLadders = <ProgressionLadder>[];
    for (final l in BwfRoutineData.allLadders) {
      if (widget.controller.checkProgressionReady(l.id)) {
        readyLadders.add(l);
      }
    }

    if (readyLadders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.upgrade_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'PROGRESSION MILESTONES ACHIEVED!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'You hit 3 sets of your target reps on these movements! In your next session, consider advancing to the next progression:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 10),
          for (final ladder in readyLadders) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right, color: AppColors.primary),
                  Text(
                    ladder.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
