import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../data/bwf_routine_data.dart';
import '../controllers/workout_controller.dart';
import 'active_workout_screen.dart';
import 'progression_ladder_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final WorkoutController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentNavIndex,
            children: [
              _buildHomeTab(context),
              ProgressionLadderScreen(controller: widget.controller),
              HistoryScreen(controller: widget.controller),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary,
              selectedIndex: _currentNavIndex,
              onDestinationSelected: (index) {
                setState(() => _currentNavIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center, color: Colors.black),
                  label: 'Routine',
                ),
                NavigationDestination(
                  icon: Icon(Icons.stairs_outlined),
                  selectedIcon: Icon(Icons.stairs, color: Colors.black),
                  label: 'Progressions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history, color: Colors.black),
                  label: 'History',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final controller = widget.controller;
    final activeDraft = controller.activeSession;
    final history = controller.history;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'r/bodyweightfitness',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'RECOMMENDED\nROUTINE',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary Action Button: Start or Resume
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            activeDraft != null ? Icons.play_circle_fill : Icons.bolt_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            activeDraft != null ? 'WORKOUT IN PROGRESS' : 'READY TO TRAIN?',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeDraft != null
                            ? 'You have an active routine session in progress.'
                            : 'Full-body strength: 3 Pairs & Core Triplet with auto rest timers.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            activeDraft != null ? Icons.arrow_forward_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                          ),
                          label: Text(activeDraft != null ? 'Resume Workout' : 'Start BWF Routine'),
                          onPressed: () {
                            if (activeDraft == null) {
                              controller.startWorkout();
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActiveWorkoutScreen(controller: controller),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick stats banner
                if (history.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          icon: Icons.check_circle_outline,
                          label: 'WORKOUTS',
                          value: '${history.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'LAST SESSION',
                          value: DateFormat('MMM d').format(history.first.startTime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Progression Ladders Overview Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR CURRENT PROGRESSIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentNavIndex = 1),
                      child: const Text('View All Ladders', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Grouped Cards for the 3 Pairs + Triplet
                _buildLadderGroup(
                  title: 'PAIR 1: VERTICAL PULL & QUAD SQUAT',
                  ladders: [BwfRoutineData.pullupLadder, BwfRoutineData.squatLadder],
                ),
                const SizedBox(height: 12),
                _buildLadderGroup(
                  title: 'PAIR 2: VERTICAL PUSH & HINGE',
                  ladders: [BwfRoutineData.dipLadder, BwfRoutineData.hingeLadder],
                ),
                const SizedBox(height: 12),
                _buildLadderGroup(
                  title: 'PAIR 3: HORIZONTAL PULL & PUSH',
                  ladders: [BwfRoutineData.rowLadder, BwfRoutineData.pushupLadder],
                ),
                const SizedBox(height: 12),
                _buildLadderGroup(
                  title: 'CORE TRIPLET',
                  ladders: [
                    BwfRoutineData.antiExtensionLadder,
                    BwfRoutineData.antiRotationLadder,
                    BwfRoutineData.extensionLadder,
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLadderGroup({required String title, required List<ProgressionLadder> ladders}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          for (final ladder in ladders) ...[
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgressionLadderScreen(
                      controller: widget.controller,
                      initialLadderId: ladder.id,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Text(
                        'Lvl ${widget.controller.getSelectedExerciseForLadder(ladder.id).level}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.controller.getSelectedExerciseForLadder(ladder.id).name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
