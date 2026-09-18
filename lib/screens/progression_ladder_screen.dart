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
  State<ProgressionLadderScreen> createState() => ProgressionLadderScreenState();
}

class ProgressionLadderScreenState extends State<ProgressionLadderScreen> {
  late String _selectedLadderId;
  final ScrollController _ladderScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedLadderId = widget.initialLadderId ?? BwfRoutineData.pullupLadder.id;
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${ladder.title} to Level ${exercise.level}: ${exercise.name}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        final activeExercise = widget.controller.getSelectedExerciseForLadder(_selectedLadderId);
        final bool canPop = Navigator.canPop(context);

        // Overall Mastery & Cleared stats across all ladders
        int totalLevels = 0;
        int clearedLevels = 0;
        int clearedPairs = 0;

        for (final ladder in BwfRoutineData.allLadders) {
          totalLevels += ladder.exercises.length;
          final selected = widget.controller.getSelectedExerciseForLadder(ladder.id);
          clearedLevels += (selected.level - 1);
          if (selected.level >= 2) {
            clearedPairs++;
          }
        }

        final double masteryRatio = totalLevels > 9 ? (clearedLevels / (totalLevels - 9)) : 0.0;
        final int masteryPercent = (68 + (masteryRatio * 28)).round().clamp(25, 100);
        final int clearedDisplayCount = (clearedPairs).clamp(0, 6);

        // Determine next target unlock for current ladder
        Exercise? nextUnlockExercise;
        final currentIndex = currentLadder.exercises.indexWhere((e) => e.id == activeExercise.id);
        if (currentIndex != -1 && currentIndex + 1 < currentLadder.exercises.length) {
          nextUnlockExercise = currentLadder.exercises[currentIndex + 1];
        }

        return Scaffold(
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
                      20,
                      12,
                      20,
                      110 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Section (Roadmap & Status)
                        _buildHeaderSection(context, canPop, activeExercise.level),
                        const SizedBox(height: 16),

                        // 2. Asymmetric Bento Hero Cluster (Status Gauge + Target Unlock + Doctrine Met)
                        _buildBentoCluster(
                          masteryPercent: masteryPercent,
                          clearedPairsCount: clearedDisplayCount,
                          activeExercise: activeExercise,
                          nextUnlockExercise: nextUnlockExercise,
                        ),
                        const SizedBox(height: 18),

                        // 3. Category Filter Chips (Horizontal Navigation)
                        _buildCategoryFilterChips(),
                        const SizedBox(height: 20),

                        // 4. Tactical Milestone Deck for Current Ladder
                        _buildMilestoneDeck(currentLadder, activeExercise),
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
        );
      },
    );
  }

  // ===========================================================================
  // 1. HEADER SECTION
  // ===========================================================================
  Widget _buildHeaderSection(BuildContext context, bool canPop, int activeLevel) {
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
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.carbon, size: 22),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title ?? 'Roadmap',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                              letterSpacing: -0.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            'Lvl $activeLevel • Intermediate',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.carbon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Action Icons (Bookmark + Start/Resume)
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progression saved to bookmarks'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.bookmark_outline_rounded,
                  size: 18,
                  color: AppColors.carbon,
                ),
              ),
            ),
            const SizedBox(width: 8),

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
                    builder: (_) => ActiveWorkoutScreen(controller: widget.controller),
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
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. ASYMMETRIC BENTO CLUSTER (HERO)
  // ===========================================================================
  Widget _buildBentoCluster({
    required int masteryPercent,
    required int clearedPairsCount,
    required Exercise activeExercise,
    required Exercise? nextUnlockExercise,
  }) {
    return SizedBox(
      height: 216,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: 5-Col Equivalent (Gauge & Status)
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(14),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.stone.withValues(alpha: 0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accentMint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                    const SizedBox(height: 8),

                    // Concentric Radial Mastery Gauge
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(78, 78),
                            painter: _RoadmapRadialGaugePainter(
                              progress: masteryPercent / 100.0,
                            ),
                          ),
                          Text(
                            '$masteryPercent%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                              letterSpacing: -0.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '$masteryPercent% MASTERY',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Primary Pairs Cleared Sub-card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.inset,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRIMARY PAIRS',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.stone.withValues(alpha: 0.8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.carbon,
                              ),
                              children: [
                                TextSpan(text: '$clearedPairsCount '),
                                TextSpan(
                                  text: '/ 6 Cleared',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
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
            ),
            const SizedBox(width: 10),

            // Right Column: 7-Col Equivalent (Target Unlock + Doctrine Met)
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  // Target Unlock Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              const SizedBox(width: 5),
                              const Text(
                                'TARGET UNLOCK',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentMint,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextUnlockExercise != null ? nextUnlockExercise.name : 'Mastery Peak',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            nextUnlockExercise != null
                                ? 'Need 3 × ${activeExercise.maxTargetReps} reps strict to advance progression line.'
                                : 'Maximum progression unlocked for this movement.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.stone,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Doctrine Met Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DOCTRINE MET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.stone.withValues(alpha: 0.8),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentMint,
                                ),
                                children: [
                                  TextSpan(text: '3 × 8 '),
                                  TextSpan(
                                    text: 'Strict Form',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.stone,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.accentMintTint,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppColors.accentMintBorder),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: AppColors.accentMint,
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
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, 0.90, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
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
                    setState(() => _selectedLadderId = l.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    alignment: Alignment.center,
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
                    child: Text(
                      chipLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
  Widget _buildMilestoneDeck(ProgressionLadder currentLadder, Exercise activeExercise) {
    final exercises = currentLadder.exercises;
    final int activeLevel = activeExercise.level;

    final passed = exercises.where((e) => e.level < activeLevel).toList();
    final current = exercises.firstWhere((e) => e.level == activeLevel, orElse: () => activeExercise);
    final upcoming = exercises.where((e) => e.level > activeLevel).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
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
            Text(
              'Progression $activeLevel of ${exercises.length}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.stone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Completed Tiers (Passed)
        if (passed.isNotEmpty) ...[
          if (passed.length >= 2) ...[
            // Render first 2 passed in compact 2-column grid
            Row(
              children: [
                Expanded(child: _buildPassedCard(passed[0], currentLadder)),
                const SizedBox(width: 8),
                Expanded(child: _buildPassedCard(passed[1], currentLadder)),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 2; i < passed.length; i++) ...[
              _buildPassedHorizontalCard(passed[i], currentLadder),
              const SizedBox(height: 8),
            ],
          ] else ...[
            for (final p in passed) ...[
              _buildPassedHorizontalCard(p, currentLadder),
              const SizedBox(height: 8),
            ],
          ],
        ],

        // CURRENT FOCUS Tier - Elevated High-Priority Hero Card
        _buildCurrentFocusHeroCard(current, currentLadder),
        const SizedBox(height: 10),

        // Upcoming / Locked Tiers
        for (final u in upcoming) ...[
          _buildUpcomingTierCard(u, currentLadder, activeExercise),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // --- Passed Card (2-Col Compact) ---
  Widget _buildPassedCard(Exercise exercise, ProgressionLadder ladder) {
    final String cue = exercise.formCues.isNotEmpty
        ? exercise.formCues.first
        : '3 × ${exercise.minTargetReps} reps clean execution';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _confirmSwitchDialog(ladder, exercise),
      child: Container(
        padding: const EdgeInsets.all(12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.accentMintTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.accentMint,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentMintTint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accentMintBorder),
                  ),
                  child: const Text(
                    'Passed',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentMint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.carbon,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              cue,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.stone,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Passed Card (Horizontal Bridge) ---
  Widget _buildPassedHorizontalCard(Exercise exercise, ProgressionLadder ladder) {
    final String cue = exercise.formCues.isNotEmpty
        ? exercise.formCues.first
        : 'Mastered 3 × ${exercise.maxTargetReps} reps';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _confirmSwitchDialog(ladder, exercise),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.accentMintTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 15,
                color: AppColors.accentMint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.carbon,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cue,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.stone,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Text(
                'Mastered',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.stone,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Current Focus Hero Card ---
  Widget _buildCurrentFocusHeroCard(Exercise exercise, ProgressionLadder ladder) {
    final String cue = exercise.formCues.isNotEmpty
        ? exercise.formCues.first
        : 'Controlled execution • Dead hang to full contraction';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.actionDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Level circle, Title, CURRENT pill, Tempo pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentMint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cue,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.stone,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inset,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  'Tempo 3-0-1-0',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stone,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rep Progress Stats & 3-Segment Progress Gauge
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.stoneBorder)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.stone,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'Current Peak: '),
                          TextSpan(
                            text: '${exercise.minTargetReps} / ${exercise.minTargetReps} / ${exercise.maxTargetReps} reps',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.carbon,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Goal: 3 × ${exercise.maxTargetReps} Strict',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.carbon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Segmented 3-Set Gauge Bars
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.actionDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.actionDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.trackRing,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.88,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.actionDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Upcoming / Locked Tier Card ---
  Widget _buildUpcomingTierCard(Exercise exercise, ProgressionLadder ladder, Exercise activeExercise) {
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
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.inset,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.stone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${exercise.level} • ${exercise.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.carbon,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Requires 3 × ${activeExercise.maxTargetReps} reps at Level ${exercise.level - 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.stone,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.stone),
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
          'Set "${exercise.name}" as your active exercise in routine for ${ladder.title}?',
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.stone,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.stone, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _switchProgression(ladder, exercise);
            },
            child: const Text('Set as Active', style: TextStyle(fontWeight: FontWeight.w700)),
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

  _RoadmapRadialGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Background track ring
    final bgPaint = Paint()
      ..color = AppColors.trackRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5;

    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    final fgPaint = Paint()
      ..color = AppColors.obsidian
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
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
      oldDelegate.progress != progress;
}
