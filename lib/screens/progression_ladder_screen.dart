import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../data/bwf_routine_data.dart';
import '../controllers/workout_controller.dart';
import 'active_workout_screen.dart';

class ProgressionLadderScreen extends StatefulWidget {
  final WorkoutController controller;
  final String? initialLadderId;
  final String? title;

  const ProgressionLadderScreen({
    super.key,
    required this.controller,
    this.initialLadderId,
    this.title,
  });

  @override
  State<ProgressionLadderScreen> createState() =>
      ProgressionLadderScreenState();
}

class ProgressionLadderScreenState extends State<ProgressionLadderScreen> {
  late String _selectedLadderId;
  String? _selectedPathId;
  final ScrollController _ladderScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedLadderId =
        widget.initialLadderId ?? BwfRoutineData.pullupLadder.id;
    _syncPathForLadder(_selectedLadderId);
  }

  void _syncPathForLadder(String ladderId) {
    final ladder = BwfRoutineData.getLadder(ladderId);
    final active = widget.controller.getSelectedExerciseForLadder(ladderId);
    if (ladder.paths.isNotEmpty) {
      final matchingPath = ladder.paths.firstWhere(
        (p) => p.exerciseIds.contains(active.id),
        orElse: () {
          if (widget.controller.globalTrackMode == 'bodyweight' &&
              ladder.paths.length > 1) {
            return ladder.paths[1];
          }
          return ladder.paths.first;
        },
      );
      _selectedPathId = matchingPath.id;
    } else {
      _selectedPathId = null;
    }
  }

  @override
  void dispose() {
    _ladderScrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (_ladderScrollController.hasClients) {
      _ladderScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _switchProgression(ProgressionLadder ladder, Exercise exercise) async {
    HapticFeedback.selectionClick();
    await widget.controller.setProgression(ladder.id, exercise.id);
    if (mounted) {
      setState(() {
        _syncPathForLadder(ladder.id);
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated ${ladder.title} to Level ${exercise.level}: ${exercise.name}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.actionDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentLadder = BwfRoutineData.getLadder(_selectedLadderId);
        final activeExercise = widget.controller.getSelectedExerciseForLadder(
          _selectedLadderId,
        );
        final bool canPop = Navigator.canPop(context);

        // Overall Mastery & Cleared stats across all ladders
        int totalLevels = 0;
        int clearedLevels = 0;
        int clearedPairs = 0;

        for (final ladder in BwfRoutineData.allLadders) {
          totalLevels += ladder.exercises.length;
          final selected = widget.controller.getSelectedExerciseForLadder(
            ladder.id,
          );
          clearedLevels += (selected.level - 1);
          if (selected.level >= 2) {
            clearedPairs++;
          }
        }

        final double masteryRatio = totalLevels > 9
            ? (clearedLevels / (totalLevels - 9))
            : 0.0;
        final int masteryPercent = (68 + (masteryRatio * 28)).round().clamp(
          25,
          100,
        );
        final int clearedDisplayCount = (clearedPairs).clamp(0, 6);

        // Resolve current path and path exercises for this ladder
        ProgressionPath? currentPath;
        if (currentLadder.paths.isNotEmpty) {
          currentPath = currentLadder.paths.firstWhere(
            (p) => p.id == _selectedPathId,
            orElse: () => currentLadder.paths.first,
          );
        }
        final pathExercises = currentPath != null
            ? currentLadder.exercisesForPath(currentPath.id)
            : currentLadder.exercises;

        // Determine next target unlock for current ladder in this path
        Exercise? nextUnlockExercise;
        final currentIndex = pathExercises.indexWhere(
          (e) => e.id == activeExercise.id,
        );
        if (currentIndex != -1 && currentIndex + 1 < pathExercises.length) {
          nextUnlockExercise = pathExercises[currentIndex + 1];
        } else if (currentIndex == -1 && pathExercises.isNotEmpty) {
          final branchIndex = pathExercises.indexWhere((e) => e.isBranchPoint);
          if (branchIndex != -1 && branchIndex + 1 < pathExercises.length) {
            nextUnlockExercise = pathExercises[branchIndex + 1];
          } else {
            nextUnlockExercise = pathExercises.first;
          }
        }

        return PrimaryScrollController(
          controller: _ladderScrollController,
          child: Scaffold(
            backgroundColor: AppColors.canvas,
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Scrollbar(
                    controller: _ladderScrollController,
                    child: SingleChildScrollView(
                      controller: _ladderScrollController,
                      padding: EdgeInsets.fromLTRB(
                        0,
                        12,
                        0,
                        110 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header Section (Roadmap & Status)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildHeaderSection(
                              context,
                              canPop,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Asymmetric Bento Hero Cluster (Status Gauge + Target Unlock + Doctrine Met)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildBentoCluster(
                              masteryPercent: masteryPercent,
                              clearedPairsCount: clearedDisplayCount,
                              activeExercise: activeExercise,
                              nextUnlockExercise: nextUnlockExercise,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 3. Category Filter Chips (Horizontal Navigation - Edge to Edge)
                          _buildCategoryFilterChips(),
                          const SizedBox(height: 20),

                          // 4. Tactical Milestone Deck for Current Ladder
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildMilestoneDeck(
                              currentLadder,
                              activeExercise,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Progressive fade under status bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 16,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.canvas,
                              AppColors.canvas.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. HEADER SECTION
  // ===========================================================================
  Widget _buildHeaderSection(
    BuildContext context,
    bool canPop,
  ) {
    final bool isSessionActive = widget.controller.activeSession != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              if (canPop) ...[
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.carbon,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accentMint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'RECOMMENDED ROUTINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.stone,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.title ?? 'Roadmap',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: -0.6,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Action Icon (Start/Resume Workout)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            if (!isSessionActive) {
              widget.controller.startWorkout();
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ActiveWorkoutScreen(controller: widget.controller),
              ),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.actionDark,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. BENTO CLUSTER (HERO)
  // ===========================================================================
  Widget _buildBentoCluster({
    required int masteryPercent,
    required int clearedPairsCount,
    required Exercise activeExercise,
    required Exercise? nextUnlockExercise,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Horizontal Full-Width Status Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(22),
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
              // Radial Mastery Gauge
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(52, 52),
                      painter: _RoadmapRadialGaugePainter(
                        progress: masteryPercent / 100.0,
                        strokeWidth: 5.5,
                      ),
                    ),
                    Text(
                      '$masteryPercent%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: -0.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Status Label and Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accentMint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.stone.withValues(alpha: 0.8),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Progression Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Pairs Cleared Sub-card / Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.inset,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PAIRS',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.stone.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.carbon,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        children: [
                          TextSpan(text: '$clearedPairsCount '),
                          TextSpan(
                            text: '/ 6',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.stone.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Bottom Row: Remaining Two Bento Cards
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Focus Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.accentMint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'CURRENT FOCUS',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentMint,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeExercise.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.carbon,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lvl ${activeExercise.level} • ${activeExercise.repRange}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.stone,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Next Target Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.inset,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              size: 10,
                              color: AppColors.stone,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'NEXT TARGET',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.stone,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nextUnlockExercise != null
                            ? nextUnlockExercise.name
                            : 'Ladder Peak',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.carbon,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextUnlockExercise != null
                            ? 'Target 3 × ${activeExercise.maxTargetReps} reps'
                            : 'Top progression reached',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.stone,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. CATEGORY FILTER CHIPS
  // ===========================================================================
  Widget _buildCategoryFilterChips() {
    final ladders = BwfRoutineData.allLadders;

    return SizedBox(
      height: 38,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.04, 0.94, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: ladders.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final l = ladders[index];
            final bool isSelected = l.id == _selectedLadderId;

            final String chipLabel = l.title.replaceAll(' Progression', '');

            return Builder(
              builder: (chipContext) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Scrollable.ensureVisible(
                      chipContext,
                      alignment: 0.5,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                    setState(() {
                      _selectedLadderId = l.id;
                      _syncPathForLadder(l.id);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.actionDark
                          : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.actionDark
                            : AppColors.borderSubtle,
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
                    child: Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.stone,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. TACTICAL MILESTONE DECK
  // ===========================================================================
  Widget _buildMilestoneDeck(
    ProgressionLadder currentLadder,
    Exercise activeExercise,
  ) {
    ProgressionPath? currentPath;
    if (currentLadder.paths.isNotEmpty) {
      currentPath = currentLadder.paths.firstWhere(
        (p) => p.id == _selectedPathId,
        orElse: () => currentLadder.paths.first,
      );
    }

    final pathExercises = currentPath != null
        ? currentLadder.exercisesForPath(currentPath.id)
        : currentLadder.exercises;

    final int displayCurrentLevel = activeExercise.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. General form doctrine tile
        if (currentLadder.generalFormCues.isNotEmpty) ...[
          _buildGeneralFormCuesTile(currentLadder),
          const SizedBox(height: 14),
        ],

        // Section Header with Minimal Track Dropdown Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.actionDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      '${currentLadder.pairCategory.toUpperCase()} • ${currentLadder.movementType.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTrackDropdownButton(currentLadder, currentPath),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Level $displayCurrentLevel of ${pathExercises.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.stone,
              ),
            ),
            if (currentPath?.equipment != null)
              Flexible(
                child: Text(
                  currentPath!.equipment!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.stone,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Alternate Track Info Banner (if viewing an alternate track while active is on main track)
        if (!pathExercises.any((e) => e.id == activeExercise.id)) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.actionDark.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.actionDark.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.alt_route_rounded,
                  size: 20,
                  color: AppColors.actionDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Active workout is on "${activeExercise.pathName}". Tap any progression below to select it for your routine.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.carbon,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // All Progression Tiers (All unlocked, none labeled Mastered)
        for (final exercise in pathExercises) ...[
          if (exercise.id == activeExercise.id)
            _buildCurrentFocusHeroCard(exercise, currentLadder)
          else
            _buildSelectableTierCard(exercise, currentLadder),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // --- Minimal Per-Exercise Track Dropdown / Popup Button ---
  Widget _buildTrackDropdownButton(
    ProgressionLadder ladder,
    ProgressionPath? currentPath,
  ) {
    if (ladder.paths.length <= 1) {
      return const SizedBox.shrink();
    }

    final currentPathName = currentPath?.name ?? ladder.paths.first.name;

    // Short, clean display label
    String buttonLabel = currentPathName;
    if (buttonLabel.contains('Recommended')) {
      buttonLabel = 'Recommended';
    } else if (buttonLabel.contains('Bodyweight')) {
      buttonLabel = 'Bodyweight';
    } else if (buttonLabel.length > 14) {
      buttonLabel = '${buttonLabel.substring(0, 12)}…';
    }

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Select Track',
        offset: const Offset(0, 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        onSelected: (selectedPathId) async {
          HapticFeedback.selectionClick();
          final selectedPath = ladder.paths.firstWhere(
            (p) => p.id == selectedPathId,
            orElse: () => ladder.paths.first,
          );

          setState(() {
            _selectedPathId = selectedPath.id;
          });

          // Switch active progression for THIS exercise ladder only
          final activeExercise = widget.controller.getSelectedExerciseForLadder(
            ladder.id,
          );
          if (!selectedPath.exerciseIds.contains(activeExercise.id)) {
            final pathExercises = ladder.exercisesForPath(selectedPath.id);
            final branchIndex = pathExercises.indexWhere(
              (e) => e.isBranchPoint,
            );
            if (branchIndex != -1 &&
                activeExercise.level >= pathExercises[branchIndex].level) {
              final nextIndex = (branchIndex + 1 < pathExercises.length)
                  ? branchIndex + 1
                  : branchIndex;
              await widget.controller.setProgression(
                ladder.id,
                pathExercises[nextIndex].id,
              );
            } else {
              final matching = pathExercises.firstWhere(
                (e) => e.level == activeExercise.level,
                orElse: () => pathExercises.first,
              );
              await widget.controller.setProgression(ladder.id, matching.id);
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${selectedPath.name} selected',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                duration: const Duration(milliseconds: 1400),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: AppColors.actionDark,
              ),
            );
          }
        },
        itemBuilder: (context) {
          return ladder.paths.map((path) {
            final bool isSelected = path.id == currentPath?.id;

            return PopupMenuItem<String>(
              value: path.id,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      path.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? AppColors.carbon : AppColors.stone,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: AppColors.actionDark,
                    ),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: AppColors.inset,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.carbon,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 15,
                color: AppColors.stone,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- General Form Doctrine Tile ---
  Widget _buildGeneralFormCuesTile(ProgressionLadder ladder) {
    if (ladder.generalFormCues.isEmpty) return const SizedBox.shrink();

    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.actionDark.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_rounded,
              size: 15,
              color: AppColors.actionDark,
            ),
          ),
          title: const Text(
            'Form Doctrine & Wiki Standards',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.carbon,
            ),
          ),
          subtitle: Text(
            '${ladder.generalFormCues.length} cues straight from Reddit BWF Wiki',
            style: const TextStyle(fontSize: 10.5, color: AppColors.stone),
          ),
          children: [
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 10),
            ...ladder.generalFormCues.map(
              (cue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.actionDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cue,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.carbon,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ladder.equipmentNote != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inset,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center_rounded,
                      size: 14,
                      color: AppColors.stone,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ladder.equipmentNote!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.stone,
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
    );
  }

  // --- Selected Active Tier Hero Card ---
  Widget _buildCurrentFocusHeroCard(
    Exercise exercise,
    ProgressionLadder ladder,
  ) {
    final String cue = exercise.formCues.isNotEmpty
        ? exercise.formCues.first
        : exercise.description;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.actionDark, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level Badge (Active)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.actionDark,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${exercise.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (exercise.isBranchPoint) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.actionDark.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BRANCH',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.actionDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.repRange,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentMint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Clean "Selected" Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentMintTint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accentMintBorder),
                ),
                child: const Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentMint,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          if (cue.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                cue,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.stone,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Selectable Progression Tier Card ---
  Widget _buildSelectableTierCard(
    Exercise exercise,
    ProgressionLadder ladder,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _confirmSwitchDialog(ladder, exercise),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${exercise.level}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stone,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Level ${exercise.level} • ${exercise.name}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.carbon,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (exercise.isBranchPoint) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.actionDark.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BRANCH',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.actionDark,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.repRange} • Tap to select',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.stone,
                ),
              ],
            ),
            if (exercise.branchPoint != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.actionDark.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.actionDark.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.alt_route_rounded,
                      size: 15,
                      color: AppColors.actionDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.branchPoint!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.carbon,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
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
    );
  }

  // Switch level confirmation modal
  void _confirmSwitchDialog(ProgressionLadder ladder, Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Select Level ${exercise.level}?',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.carbon,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          'Set "${exercise.name}" (${exercise.pathName}) as your active exercise in routine for ${ladder.title}?',
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.stone,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.stone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _switchProgression(ladder, exercise);
            },
            child: const Text(
              'Set as Active',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: RADIAL GAUGE FOR ROADMAP BENTO
// =============================================================================
class _RoadmapRadialGaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _RoadmapRadialGaugePainter({
    required this.progress,
    this.strokeWidth = 7.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth - 1) / 2;

    // Background track ring
    final bgPaint = Paint()
      ..color = AppColors.trackRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    final fgPaint = Paint()
      ..color = AppColors.obsidian
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RoadmapRadialGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth;
}
