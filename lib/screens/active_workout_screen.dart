import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../theme/app_theme.dart';
import '../data/bwf_routine_data.dart';
import '../controllers/workout_controller.dart';
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
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Discard Workout?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.carbon,
            letterSpacing: -0.3,
          ),
        ),
        content: const Text(
          'Your active workout session and current logged sets will be cleared.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.stone,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep Training',
              style: TextStyle(color: AppColors.stone, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.controller.discardWorkout();
              Navigator.pop(context);
            },
            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w700)),
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
            backgroundColor: AppColors.canvas,
            body: Center(
              child: Text(
                'No active workout session',
                style: TextStyle(color: AppColors.carbon, fontWeight: FontWeight.w700),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.canvas,
          // Fixed Glassmorphic / Oatmeal Header
          appBar: AppBar(
            backgroundColor: AppColors.canvas.withValues(alpha: 0.92),
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.carbon, size: 22),
              tooltip: 'Minimize / Back',
              onPressed: () => Navigator.pop(context),
            ),
            title: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final session = widget.controller.activeSession;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Active Workout',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (session != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 11,
                            color: AppColors.actionDark,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDuration(session.durationSeconds),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.actionDark,
                              fontFeatures: [FontFeature.tabularFigures()],
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
            actions: [
              // Pause / Resume workout session
              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final isPaused = widget.controller.isSessionPaused;
                  return IconButton(
                    icon: Icon(
                      isPaused
                          ? Icons.play_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                      size: 22,
                      color: isPaused ? AppColors.accentMint : AppColors.stone,
                    ),
                    tooltip: isPaused ? 'Resume workout' : 'Pause workout',
                    onPressed: () => widget.controller.togglePauseWorkout(),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.stone, size: 22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppColors.surfaceWhite,
                onSelected: (value) {
                  if (value == 'discard') {
                    _confirmDiscard();
                  } else if (value == 'next') {
                    widget.controller.advanceStage();
                  } else if (value == 'ladder') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgressionLadderScreen(controller: widget.controller),
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'next',
                    child: Row(
                      children: [
                        Icon(Icons.skip_next_rounded, size: 18, color: AppColors.carbon),
                        SizedBox(width: 10),
                        Text('Skip to Next Stage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ladder',
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: AppColors.carbon),
                        SizedBox(width: 10),
                        Text('Progression Ladders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'discard',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRed),
                        SizedBox(width: 10),
                        Text(
                          'Discard Workout',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.actionDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                _buildStageSelector(session),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildStageContent(session),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageSelector(WorkoutSession session) {
    final currentStage = widget.controller.currentStage;
    if (currentStage == WorkoutStage.completed) return const SizedBox.shrink();

    final stages = [
      (WorkoutStage.warmup, 'Warm-up', session.completedWarmups.length >= BwfRoutineData.warmups.length),
      (WorkoutStage.firstPair, 'Pair 1', _isPairCompleted(BwfRoutineData.pullupLadder.id, BwfRoutineData.squatLadder.id)),
      (WorkoutStage.secondPair, 'Pair 2', _isPairCompleted(BwfRoutineData.dipLadder.id, BwfRoutineData.hingeLadder.id)),
      (WorkoutStage.thirdPair, 'Pair 3', _isPairCompleted(BwfRoutineData.rowLadder.id, BwfRoutineData.pushupLadder.id)),
      (WorkoutStage.coreTriplet, 'Core', _isCoreCompleted()),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.canvas,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        height: 42,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.90, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = stages[index];
              final isSelected = currentStage == item.$1;
              return Builder(
                builder: (itemContext) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.selectionClick();
                        Scrollable.ensureVisible(
                          itemContext,
                          alignment: 0.5,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _selectedPairSubIndex = 0);
                        widget.controller.setStage(item.$1);
                      }
                    },
                    child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.actionDark : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.actionDark : AppColors.borderSubtle,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.$3) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: isSelected ? Colors.white : AppColors.accentMint,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.stone,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  ),
),
);
  }

  bool _isPairCompleted(String ladderAId, String ladderBId) {
    final setsA = widget.controller.getSetsForLadder(ladderAId);
    final setsB = widget.controller.getSetsForLadder(ladderBId);
    return setsA.isNotEmpty &&
        setsA.every((s) => s.isCompleted) &&
        setsB.isNotEmpty &&
        setsB.every((s) => s.isCompleted);
  }

  bool _isCoreCompleted() {
    final l1 = widget.controller.getSetsForLadder(BwfRoutineData.antiExtensionLadder.id);
    final l2 = widget.controller.getSetsForLadder(BwfRoutineData.antiRotationLadder.id);
    final l3 = widget.controller.getSetsForLadder(BwfRoutineData.extensionLadder.id);
    return l1.isNotEmpty &&
        l1.every((s) => s.isCompleted) &&
        l2.isNotEmpty &&
        l2.every((s) => s.isCompleted) &&
        l3.isNotEmpty &&
        l3.every((s) => s.isCompleted);
  }

  Widget _buildStageContent(WorkoutSession session) {
    switch (widget.controller.currentStage) {
      case WorkoutStage.warmup:
        return _buildWarmupStage(session);
      case WorkoutStage.firstPair:
        return _buildPairStage(
          ladderA: BwfRoutineData.pullupLadder,
          ladderB: BwfRoutineData.squatLadder,
          stageName: 'First Pair • 1 of 3',
          pairTitle: 'Strict Pull-up & Squat',
          session: session,
        );
      case WorkoutStage.secondPair:
        return _buildPairStage(
          ladderA: BwfRoutineData.dipLadder,
          ladderB: BwfRoutineData.hingeLadder,
          stageName: 'Second Pair • 2 of 3',
          pairTitle: 'Parallel Dip & Hinge',
          session: session,
        );
      case WorkoutStage.thirdPair:
        return _buildPairStage(
          ladderA: BwfRoutineData.rowLadder,
          ladderB: BwfRoutineData.pushupLadder,
          stageName: 'Third Pair • 3 of 3',
          pairTitle: 'Inverted Row & Push-up',
          session: session,
        );
      case WorkoutStage.coreTriplet:
        return _buildTripletStage(session);
      case WorkoutStage.completed:
        return _buildCompletionStage(session);
    }
  }

  // ===========================================================================
  // 1. PAIR STAGE (WORKOUT.HTML DESIGN SYSTEM)
  // ===========================================================================
  Widget _buildPairStage({
    required ProgressionLadder ladderA,
    required ProgressionLadder ladderB,
    required String stageName,
    required String pairTitle,
    required WorkoutSession session,
  }) {
    final exerciseA = widget.controller.getSelectedExerciseForLadder(ladderA.id);
    final exerciseB = widget.controller.getSelectedExerciseForLadder(ladderB.id);

    final currentLadder = _selectedPairSubIndex == 0 ? ladderA : ladderB;
    final otherLadder = _selectedPairSubIndex == 0 ? ladderB : ladderA;

    final currentExercise = _selectedPairSubIndex == 0 ? exerciseA : exerciseB;
    final otherExercise = _selectedPairSubIndex == 0 ? exerciseB : exerciseA;

    final currentSets = widget.controller.getSetsForLadder(currentLadder.id);
    final otherSets = widget.controller.getSetsForLadder(otherLadder.id);

    // Find the current active set to log
    int activeSetIndex = currentSets.indexWhere((s) => !s.isCompleted);
    if (activeSetIndex == -1) {
      activeSetIndex = currentSets.length - 1; // All done for this exercise
    }
    final currentSet = currentSets[activeSetIndex];
    final bool isExerciseAllDone = currentSets.every((s) => s.isCompleted);
    final bool isPairAllDone = isExerciseAllDone && otherSets.every((s) => s.isCompleted);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Routine Hierarchy & Live Timer Header
          _buildSessionContextHeader(stageName: stageName, pairTitle: pairTitle, session: session),
          const SizedBox(height: 16),

          // Segmented Pair Toggle Pill Bar
          _buildSegmentedPairToggle(
            ladderA: ladderA,
            exerciseA: exerciseA,
            ladderB: ladderB,
            exerciseB: exerciseB,
            currentSubIndex: _selectedPairSubIndex,
          ),
          const SizedBox(height: 16),

          // Primary Active Workout Card (Ceramic White with concentric gauge)
          _buildPrimaryWorkoutCard(
            currentLadder: currentLadder,
            currentExercise: currentExercise,
            currentSet: currentSet,
            activeSetIndex: activeSetIndex,
            totalSets: currentSets.length,
          ),
          const SizedBox(height: 16),

          // Micro Coach Tip Neo-Banner
          _buildCoachTipBanner(currentExercise),
          const SizedBox(height: 16),

          // Up Next Paired Movement Preview Pill Card
          _buildUpNextPreviewCard(
            otherExercise: otherExercise,
            otherLadder: otherLadder,
            onSwitch: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPairSubIndex = _selectedPairSubIndex == 0 ? 1 : 0;
              });
            },
          ),
          const SizedBox(height: 20),

          // Main Primary Floating Execution Bar
          _buildExecutionButton(
            isPairAllDone: isPairAllDone,
            isExerciseAllDone: isExerciseAllDone,
            currentLadder: currentLadder,
            activeSetIndex: activeSetIndex,
            currentSet: currentSet,
          ),
        ],
      ),
    );
  }

  // --- Session Context & Live Elapsed Timer Header ---
  Widget _buildSessionContextHeader({
    required String stageName,
    required String pairTitle,
    required WorkoutSession session,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.actionDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stageName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stone,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pairTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.carbon,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Live Elapsed Time Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 15, color: AppColors.actionDark),
              const SizedBox(width: 5),
              Text(
                _formatDuration(session.durationSeconds),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.carbon,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Segmented Pair Toggle Pill Bar ---
  Widget _buildSegmentedPairToggle({
    required ProgressionLadder ladderA,
    required Exercise exerciseA,
    required ProgressionLadder ladderB,
    required Exercise exerciseB,
    required int currentSubIndex,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTogglePill(
              label: '1A. ${ladderA.title.replaceAll(' Progression', '')}',
              isSelected: currentSubIndex == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPairSubIndex = 0);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTogglePill(
              label: '1B. ${ladderB.title.replaceAll(' Progression', '')}',
              isSelected: currentSubIndex == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPairSubIndex = 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.actionDark : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.stone,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Primary Active Workout Card (Ceramic White) ---
  Widget _buildPrimaryWorkoutCard({
    required ProgressionLadder currentLadder,
    required Exercise currentExercise,
    required LoggedSet currentSet,
    required int activeSetIndex,
    required int totalSets,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Meta Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inset,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center_rounded, size: 13, color: AppColors.stone),
                    const SizedBox(width: 5),
                    Text(
                      'SET ${activeSetIndex + 1} OF $totalSets',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inset,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 14, color: AppColors.stone),
                    const SizedBox(width: 5),
                    Text(
                      '3-0-1-0 Tempo',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.carbon,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Movement Focus & Form Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLadder.movementType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stone,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            currentExercise.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (currentExercise.isBranchPoint) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.actionDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BRANCH POINT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currentExercise.formCues.isNotEmpty
                          ? currentExercise.formCues.first
                          : 'Controlled execution • Full range of motion',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.stone,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentExercise.branchPoint != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.actionDark.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.actionDark.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alt_route_rounded, size: 14, color: AppColors.actionDark),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                currentExercise.branchPoint!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.carbon,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Level indicator pill
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inset,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.tune_rounded, size: 16, color: AppColors.actionDark),
                      const SizedBox(height: 2),
                      Text(
                        'Lvl ${currentExercise.level}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.carbon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Concentric Rest & Interval Timer Gauge
          _buildRestTimerGauge(currentLadder.defaultRestSeconds),
          const SizedBox(height: 16),

          // Tactile Rep Counter Stepper Module
          _buildRepCounterModule(
            currentExercise: currentExercise,
            currentLadder: currentLadder,
            currentSet: currentSet,
            setIndex: activeSetIndex,
          ),
        ],
      ),
    );
  }

  // --- Concentric Circular Rest & Interval Timer Gauge ---
  Widget _buildRestTimerGauge(int defaultRestSeconds) {
    final bool isTimerRunning = widget.controller.isTimerRunning;
    final int remaining = widget.controller.restRemainingSeconds;
    final int total = widget.controller.restTotalSeconds > 0
        ? widget.controller.restTotalSeconds
        : defaultRestSeconds;

    final double progress = isTimerRunning && total > 0
        ? (remaining / total).clamp(0.0, 1.0)
        : 0.0;

    final String timerText = isTimerRunning
        ? _formatDuration(remaining)
        : _formatDuration(defaultRestSeconds);

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom concentric gauge canvas
                CustomPaint(
                  size: const Size(190, 190),
                  painter: _RestGaugePainter(progress: progress),
                ),

                // Center Counter Display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTimerRunning ? 'REST COUNTDOWN' : 'TARGET REST',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.stone,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timerText,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: -1.2,
                        fontFeatures: [FontFeature.tabularFigures()],
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Heart rate / Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.inset,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 13,
                            color: isTimerRunning ? AppColors.accentRed : AppColors.actionDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTimerRunning ? 'RESTING' : 'READY',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quick Adjust Rest Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSmallActionPill('+15s', () {
              HapticFeedback.lightImpact();
              widget.controller.addTimerSeconds(15);
            }),
            const SizedBox(width: 8),
            _buildSmallActionPill('+30s', () {
              HapticFeedback.lightImpact();
              widget.controller.addTimerSeconds(30);
            }),
            const SizedBox(width: 8),
            _buildSmallActionPill(
              isTimerRunning ? 'Skip Rest' : 'Start Timer',
              () {
                HapticFeedback.mediumImpact();
                if (isTimerRunning) {
                  widget.controller.stopRestTimer();
                } else {
                  widget.controller.startRestTimer(defaultRestSeconds);
                }
              },
              isMuted: !isTimerRunning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallActionPill(String label, VoidCallback onTap, {bool isMuted = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.inset,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isMuted ? AppColors.stone : AppColors.carbon,
          ),
        ),
      ),
    );
  }

  // --- Tactile Rep Counter Stepper Module ---
  Widget _buildRepCounterModule({
    required Exercise currentExercise,
    required ProgressionLadder currentLadder,
    required LoggedSet currentSet,
    required int setIndex,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inset,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMPLETED WORK',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.stone,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.controller.updateSetReps(
                    currentLadder.id,
                    setIndex,
                    currentExercise.minTargetReps,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: AppColors.stone),
                      const SizedBox(width: 3),
                      Text(
                        'Target: ${currentExercise.minTargetReps}–${currentExercise.maxTargetReps} Reps',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.carbon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stepper Pill Control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Decrement Button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (currentSet.reps > 0) {
                      HapticFeedback.lightImpact();
                      widget.controller.updateSetReps(
                        currentLadder.id,
                        setIndex,
                        currentSet.reps - 1,
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.inset,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove_rounded,
                      color: AppColors.carbon,
                      size: 22,
                    ),
                  ),
                ),

                // Reps Counter Text
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${currentSet.reps}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: -0.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Reps',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.stone,
                      ),
                    ),
                  ],
                ),

                // Increment Button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.controller.updateSetReps(
                      currentLadder.id,
                      setIndex,
                      currentSet.reps + 1,
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.actionDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Load Offset Chips (Bodyweight, +5 kg, +10 kg)
          Row(
            children: [
              Expanded(
                child: _buildLoadChip(
                  label: 'Bodyweight',
                  isSelected: currentSet.addedWeightKg == 0,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.controller.updateSetWeight(currentLadder.id, setIndex, 0);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildLoadChip(
                  label: '+5 kg',
                  isSelected: currentSet.addedWeightKg == 5,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.controller.updateSetWeight(currentLadder.id, setIndex, 5);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildLoadChip(
                  label: '+10 kg',
                  isSelected: currentSet.addedWeightKg == 10,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.controller.updateSetWeight(currentLadder.id, setIndex, 10);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.actionDark : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.actionDark : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.stone,
          ),
        ),
      ),
    );
  }

  // --- Micro Coach Tip Neo-Banner ---
  Widget _buildCoachTipBanner(Exercise exercise) {
    final String tip = exercise.formCues.isNotEmpty
        ? exercise.formCues.first
        : 'Keep core braced, maintain full lockout, and control the tempo.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.inset,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.actionDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TECHNIQUE FOCUS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.actionDark,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.stone,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Up Next Paired Movement Preview Pill Card ---
  Widget _buildUpNextPreviewCard({
    required Exercise otherExercise,
    required ProgressionLadder otherLadder,
    required VoidCallback onSwitch,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSwitch,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.actionDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ANTAGONIST SUPER-SET',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stone,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${otherExercise.name} (3 × 8)',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.carbon,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${otherLadder.defaultRestSeconds}s rest interval awaits',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.stone,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.carbon, size: 22),
          ],
        ),
      ),
    );
  }

  // --- Main Primary Floating Execution Bar ---
  Widget _buildExecutionButton({
    required bool isPairAllDone,
    required bool isExerciseAllDone,
    required ProgressionLadder currentLadder,
    required int activeSetIndex,
    required LoggedSet currentSet,
  }) {
    if (isPairAllDone) {
      final isLastPair = widget.controller.currentStage == WorkoutStage.thirdPair;
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.actionDark,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            setState(() => _selectedPairSubIndex = 0);
            widget.controller.advanceStage();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastPair ? 'Proceed to Core Triplet' : 'Proceed to Next Pair',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      );
    }

    final bool isTimerRunning = widget.controller.isTimerRunning;
    final int remaining = widget.controller.restRemainingSeconds;

    if (isTimerRunning) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.actionDark,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.controller.stopRestTimer();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Rest ${_formatDuration(remaining)} · Skip & Begin Set',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String repsLabel = currentSet.reps > 0 ? '${currentSet.reps} Reps' : '0 Reps';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionDark,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () {
          HapticFeedback.heavyImpact();
          widget.controller.completeSetAndTriggerRest(
            ladderId: currentLadder.id,
            setIndex: activeSetIndex,
            restSeconds: currentLadder.defaultRestSeconds,
          );

          // Alternating UX: Switch to the partner exercise automatically for the next set!
          setState(() {
            _selectedPairSubIndex = _selectedPairSubIndex == 0 ? 1 : 0;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Log $repsLabel & Start Rest',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. WARMUP STAGE
  // ===========================================================================
  Widget _buildWarmupStage(WorkoutSession session) {
    final warmups = BwfRoutineData.warmups;
    final int completedCount = session.completedWarmups.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'WARM-UP • PHASE 1 OF 5',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stone,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Joint Mobility & Prep',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: -0.6,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  '$completedCount / ${warmups.length} done',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.carbon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mobility instructions card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.inset,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.actionDark, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Prime scapulae, wrists, and core to prevent injury and maximize strength.',
                    style: TextStyle(fontSize: 13, color: AppColors.stone, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Warmup Items List
          for (final w in warmups) ...[
            _buildWarmupItem(w, session.completedWarmups.contains(w.id)),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: AppColors.surfaceWhite,
                  ),
                  onPressed: widget.controller.markAllWarmupsCompleted,
                  child: const Text(
                    'Mark All Done',
                    style: TextStyle(color: AppColors.carbon, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.actionDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _selectedPairSubIndex = 0);
                    widget.controller.advanceStage();
                  },
                  child: const Text(
                    'Start First Pair',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarmupItem(WarmupExercise w, bool isCompleted) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.controller.toggleWarmup(w.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.inset : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? AppColors.actionDark.withValues(alpha: 0.3) : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.actionDark : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.actionDark : AppColors.stone,
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? AppColors.stone : AppColors.carbon,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${w.prescription} • ${w.target}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.stone,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    w.instructions,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted ? AppColors.stone.withValues(alpha: 0.7) : AppColors.stone,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. CORE TRIPLET STAGE
  // ===========================================================================
  Widget _buildTripletStage(WorkoutSession session) {
    final ladders = [
      BwfRoutineData.antiExtensionLadder,
      BwfRoutineData.antiRotationLadder,
      BwfRoutineData.extensionLadder,
    ];
    final currentLadder = ladders[_selectedPairSubIndex.clamp(0, 2)];
    final currentExercise = widget.controller.getSelectedExerciseForLadder(currentLadder.id);
    final currentSets = widget.controller.getSetsForLadder(currentLadder.id);

    int activeSetIndex = currentSets.indexWhere((s) => !s.isCompleted);
    if (activeSetIndex == -1) {
      activeSetIndex = currentSets.length - 1;
    }
    final currentSet = currentSets[activeSetIndex];

    final bool isAllCoreDone = ladders.every((l) {
      final s = widget.controller.getSetsForLadder(l.id);
      return s.every((x) => x.isCompleted);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionContextHeader(
            stageName: 'Core Triplet • Circuit Round',
            pairTitle: 'Anti-Extension & Rotation',
            session: session,
          ),
          const SizedBox(height: 16),

          // 3-Way Triplet Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.inset,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                for (int i = 0; i < ladders.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _buildTogglePill(
                      label: '4${String.fromCharCode(65 + i)}. ${ladders[i].title.replaceAll(' Progression', '')}',
                      isSelected: _selectedPairSubIndex == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPairSubIndex = i);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildPrimaryWorkoutCard(
            currentLadder: currentLadder,
            currentExercise: currentExercise,
            currentSet: currentSet,
            activeSetIndex: activeSetIndex,
            totalSets: currentSets.length,
          ),
          const SizedBox(height: 16),

          _buildCoachTipBanner(currentExercise),
          const SizedBox(height: 20),

          // Execution Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                if (isAllCoreDone) {
                  HapticFeedback.mediumImpact();
                  widget.controller.advanceStage();
                } else if (widget.controller.isTimerRunning) {
                  HapticFeedback.mediumImpact();
                  widget.controller.stopRestTimer();
                } else {
                  HapticFeedback.heavyImpact();
                  widget.controller.completeSetAndTriggerRest(
                    ladderId: currentLadder.id,
                    setIndex: activeSetIndex,
                    restSeconds: 60,
                  );
                  // Advance triplet round
                  setState(() {
                    _selectedPairSubIndex = (_selectedPairSubIndex + 1) % 3;
                  });
                }
              },
              child: isAllCoreDone
                  ? const Text(
                      'Finish Workout & View Summary',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    )
                  : widget.controller.isTimerRunning
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined, size: 20, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'Resting (${_formatDuration(widget.controller.restRemainingSeconds)}) • Skip Rest',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Log ${currentSet.reps > 0 ? '${currentSet.reps} Reps' : '0 Reps'} & Rotate Movement',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. COMPLETION STAGE
  // ===========================================================================
  Widget _buildCompletionStage(WorkoutSession session) {
    final completedSets = session.sets.where((s) => s.isCompleted).length;
    final totalReps = session.totalReps;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 40, color: AppColors.actionDark),
          ),
          const SizedBox(height: 16),
          const Text(
            'Workout Complete!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.carbon,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Great discipline. Session logged to your history.',
            style: TextStyle(fontSize: 13, color: AppColors.stone),
          ),
          const SizedBox(height: 24),

          // Metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'DURATION',
                  value: _formatDuration(session.durationSeconds),
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'SETS LOGGED',
                  value: '$completedSets',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'TOTAL REPS',
                  value: '$totalReps',
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Notes input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOGBOOK NOTES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.stone,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.carbon, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Notes on form, fatigue, or progression levels...',
                    hintStyle: const TextStyle(color: AppColors.stone),
                    filled: true,
                    fillColor: AppColors.inset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.actionDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save & Finish Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await widget.controller.finishWorkout(notes: _notesController.text);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Save & Return to Home',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.actionDark),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.carbon,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.stone,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CONCENTRIC REST TIMER GAUGE PAINTER (MATCHING WORKOUT.HTML SVG)
// =============================================================================
class _RestGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _RestGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 12;
    final innerRadius = outerRadius - 16;

    // 1. Base Outer Track (#EDE8DE)
    final basePaint = Paint()
      ..color = AppColors.trackRing
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerRadius, basePaint);

    // 2. Inner Track (#F5F2EB)
    final innerPaint = Paint()
      ..color = AppColors.inset
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, innerRadius, innerPaint);

    // 3. Inner Decorative Arc (#E5E1D8)
    final decoPaint = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -pi / 2,
      pi * 1.2,
      false,
      decoPaint,
    );

    // 4. Active Progress Arc in Obsidian Slate (#1E232A)
    if (progress > 0) {
      final activePaint = Paint()
        ..color = AppColors.obsidian
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -pi / 2,
        2 * pi * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RestGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
