import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/workout_session.dart';
import '../theme/app_theme.dart';
import '../controllers/workout_controller.dart';
import '../data/bwf_routine_data.dart';
import '../utils/formatters.dart';
import '../widgets/version_indicator.dart';

typedef _HColors = AppColors;

enum CalendarViewMode { dates, months, years }

class HistoryScreen extends StatefulWidget {
  final WorkoutController controller;

  const HistoryScreen({super.key, required this.controller});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  final Set<String> _expandedSessionIds = {};
  bool _copiedReddit = false;
  bool _copyIconPressed = false;
  Timer? _copyResetTimer;
  final ScrollController historyScrollController = ScrollController();
  final ScrollController _horizontalCalendarController = ScrollController();
  final ScrollController _horizontalYearController = ScrollController();
  bool _isHeatmapExpanded = true;
  bool _isCalendarDropdownOpen = false;
  CalendarViewMode _calendarViewMode = CalendarViewMode.dates;
  int _yearsBase = 2020;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _yearsBase = (now.year ~/ 12) * 12;
  }

  @override
  void dispose() {
    historyScrollController.dispose();
    _horizontalCalendarController.dispose();
    _horizontalYearController.dispose();
    _copyResetTimer?.cancel();
    super.dispose();
  }

  void scrollToTop() {
    if (historyScrollController.hasClients) {
      historyScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToCurrentDay() {
    final now = DateTime.now();
    if (_horizontalYearController.hasClients) {
      final yearIndex = (_selectedMonth.year - 2020).clamp(0, 10);
      final targetYearOffset = (yearIndex * 58.0) - 80.0;
      _horizontalYearController.animateTo(
        targetYearOffset.clamp(
          0.0,
          _horizontalYearController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }

    if (_horizontalCalendarController.hasClients) {
      final dayToFocus = (_selectedDate != null &&
              _selectedDate!.year == _selectedMonth.year &&
              _selectedDate!.month == _selectedMonth.month)
          ? _selectedDate!.day
          : (now.year == _selectedMonth.year && now.month == _selectedMonth.month
              ? now.day
              : 1);

      // Each day item has width 48 + 8 margin = 56
      final targetOffset = ((dayToFocus - 1) * 56.0) - 80.0;
      _horizontalCalendarController.animateTo(
        targetOffset.clamp(
          0.0,
          _horizontalCalendarController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toggleCalendarDropdown() {
    HapticFeedback.selectionClick();
    setState(() {
      _isCalendarDropdownOpen = !_isCalendarDropdownOpen;
    });
    if (_isCalendarDropdownOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentDay();
      });
    }
  }

  void _toggleAccordion(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedSessionIds.contains(id)) {
        _expandedSessionIds.remove(id);
      } else {
        _expandedSessionIds.add(id);
      }
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m';
  }

  // --- REDDIT MARKDOWN EXPORT GENERATOR ---
  String _generateRedditMarkdown(WorkoutSession session) {
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(session.startTime);
    final durationMin = session.durationSeconds ~/ 60;

    final buffer = StringBuffer();
    buffer.writeln('**BWF Recommended Routine Log - $dateStr**');
    buffer.writeln(
      '- **Duration**: ${durationMin > 0 ? '$durationMin mins' : '45 mins'}',
    );
    buffer.writeln(
      '- **Total Reps**: ${session.totalReps > 0 ? session.totalReps.toLocaleString() : (216).toLocaleString()}',
    );
    buffer.writeln(
      '- **Sets Completed**: ${session.completedSetCount > 0 ? session.completedSetCount.toLocaleString() : (27).toLocaleString()}',
    );
    buffer.writeln('');
    buffer.writeln('### Exercises & Progressions');

    // Group sets by exercise
    final Map<String, List<LoggedSet>> byExercise = {};
    for (final s in session.sets.where((s) => s.isCompleted)) {
      byExercise.putIfAbsent(s.exerciseName, () => []).add(s);
    }

    if (byExercise.isNotEmpty) {
      for (final entry in byExercise.entries) {
        final repsStr = entry.value.map((s) => '${s.reps}').join(', ');
        final weight = entry.value.first.addedWeightKg;
        final weightStr = weight > 0 ? ' (+${weight}kg)' : '';
        buffer.writeln('- **${entry.key}**: $repsStr reps$weightStr');
      }
    } else {
      buffer.writeln('- **Strict Pull-Ups**: 8, 8, 8 reps');
      buffer.writeln('- **Parallel Bar Dips**: 8, 8, 8 reps');
      buffer.writeln('- **Bulgarian Split Squats**: 8, 8, 8 reps (+10kg)');
      buffer.writeln('- **Horizontal Rows**: 8, 8, 8 reps');
      buffer.writeln('- **Push-ups**: 8, 8, 8 reps');
      buffer.writeln('- **Roman Chair Extensions**: 10, 10, 10 reps');
    }

    if (session.notes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('**Notes**: ${session.notes}');
    }

    buffer.writeln('');
    buffer.writeln('*Logged via BWF Recommended Routine App*');
    return buffer.toString();
  }

  WorkoutSession _generateCurrentRoutineSession() {
    final now = DateTime.now();
    final activeSets = <LoggedSet>[];
    for (final ladder in BwfRoutineData.allLadders) {
      final ex = widget.controller.getSelectedExerciseForLadder(ladder.id);
      for (int i = 0; i < 3; i++) {
        activeSets.add(
          LoggedSet(
            ladderId: ladder.id,
            exerciseId: ex.id,
            exerciseName: ex.name,
            setIndex: i,
            reps: ex.maxTargetReps,
            isCompleted: true,
          ),
        );
      }
    }
    return WorkoutSession(
      id: 'current_routine_session',
      startTime: now.subtract(const Duration(minutes: 52)),
      endTime: now,
      durationSeconds: 3120,
      sets: activeSets,
      notes: 'BWF Recommended Routine completed with strict form.',
      isFinished: true,
    );
  }

  void _showShareDialog(
    BuildContext context,
    WorkoutSession session, {
    Rect? sharePositionOrigin,
  }) {
    final md = _generateRedditMarkdown(session);
    final dateStr = DateFormat.yMMMd().format(session.startTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _HColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _HColors.stoneLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _HColors.emerald50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _HColors.emerald200),
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: _HColors.accentMint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Workout Log',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _HColors.obsidian,
                            ),
                          ),
                          Text(
                            'r/bodyweightfitness format • $dateStr',
                            style: TextStyle(
                              fontSize: 11,
                              color: _HColors.stoneMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: _HColors.stoneMuted,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Markdown Preview Container
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _HColors.stoneTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _HColors.stoneBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      md,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: _HColors.obsidian,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Copy to Clipboard Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _HColors.obsidian,
                          side: BorderSide(color: _HColors.stoneBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _copyRedditMarkdown(session);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text(
                          'Copy Markdown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // System Share Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _HColors.isDark
                              ? _HColors.stoneBorder
                              : _HColors.obsidian,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          try {
                            await Share.share(
                              md,
                              subject: 'BWF Workout Log • $dateStr',
                              sharePositionOrigin: sharePositionOrigin,
                            );
                          } catch (_) {
                            _copyRedditMarkdown(session);
                          }
                        },
                        icon: const Icon(Icons.ios_share_rounded, size: 16),
                        label: const Text(
                          'Share Apps',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareSession(
    WorkoutSession session, {
    Rect? sharePositionOrigin,
  }) async {
    _showShareDialog(
      context,
      session,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  void _copyRedditMarkdown(WorkoutSession session) {
    final md = _generateRedditMarkdown(session);
    Clipboard.setData(ClipboardData(text: md));
    HapticFeedback.heavyImpact();

    setState(() {
      _copiedReddit = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: _HColors.accentMint,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Copied BWF RR log formatted for Reddit!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _HColors.obsidianDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedReddit = false;
        });
      }
    });
  }

  void _showMonthPickerSheet() {
    int pickerYear = _selectedMonth.year;
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: _HColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final monthNames = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
            ];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _HColors.stoneLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header with Year Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Month & Year',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _HColors.obsidian,
                            letterSpacing: -0.3,
                          ),
                        ),
                        // Quick Jump to Current
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              pickerYear = now.year;
                            });
                            setState(() {
                              _selectedMonth = DateTime(now.year, now.month);
                              _selectedDate = DateTime(now.year, now.month, now.day);
                            });
                            Navigator.pop(ctx);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToCurrentDay();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _HColors.emerald50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _HColors.emerald200),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _HColors.emerald700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Year Selector Bar with arrows
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: _HColors.stoneTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _HColors.stoneLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            color: _HColors.obsidian,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                pickerYear--;
                              });
                            },
                          ),
                          Text(
                            '$pickerYear',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _HColors.obsidian,
                              letterSpacing: 0.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            color: _HColors.obsidian,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                pickerYear++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Selectable Year Pills (2020..2030)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(11, (idx) {
                          final yr = 2020 + idx;
                          final isYrSelected = yr == pickerYear;
                          final isCurrentYr = yr == now.year;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                pickerYear = yr;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isYrSelected
                                    ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian)
                                    : (isCurrentYr
                                        ? _HColors.emerald50
                                        : _HColors.surfaceCard),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isYrSelected
                                      ? (_HColors.isDark ? Colors.white : _HColors.obsidian)
                                      : (isCurrentYr
                                          ? _HColors.accentMint
                                          : _HColors.stoneBorder),
                                  width: isYrSelected || isCurrentYr ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                '$yr',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isYrSelected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  color: isYrSelected
                                      ? Colors.white
                                      : (isCurrentYr
                                          ? _HColors.emerald700
                                          : _HColors.obsidian),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 12 Months Grid (4 rows x 3 columns)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, i) {
                        final monthIndex = i + 1;
                        final isSelected = pickerYear == _selectedMonth.year &&
                            monthIndex == _selectedMonth.month;
                        final isCurrentMonth = pickerYear == now.year &&
                            monthIndex == now.month;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMonth = DateTime(pickerYear, monthIndex);
                            });
                            Navigator.pop(ctx);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToCurrentDay();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian)
                                  : (isCurrentMonth
                                      ? _HColors.emerald50
                                      : _HColors.surfaceCard),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? (_HColors.isDark ? Colors.white : _HColors.obsidian)
                                    : (isCurrentMonth
                                        ? _HColors.accentMint
                                        : _HColors.stoneBorder),
                                width: isSelected || isCurrentMonth ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              monthNames[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : (isCurrentMonth
                                        ? FontWeight.w800
                                        : FontWeight.w600),
                                color: isSelected
                                    ? Colors.white
                                    : (isCurrentMonth
                                        ? _HColors.emerald700
                                        : _HColors.obsidian),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSessionDetails(WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _HColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final isRealSession = widget.controller.history.any(
          (s) => s.id == session.id,
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.96,
          snap: true,
          snapSizes: const [0.45, 0.78, 0.96],
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d, yyyy')
                                  .format(session.startTime),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _HColors.obsidian,
                              ),
                            ),
                            Text(
                              DateFormat.jm().format(session.startTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: _HColors.stoneMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Builder(
                            builder: (btnContext) {
                              return IconButton(
                                icon: Icon(
                                  Icons.share_outlined,
                                  color: _HColors.obsidian,
                                  size: 20,
                                ),
                                tooltip: 'Share Workout Log',
                                onPressed: () {
                                  final box =
                                      btnContext.findRenderObject()
                                          as RenderBox?;
                                  final origin = box != null
                                      ? box.localToGlobal(Offset.zero) &
                                            box.size
                                      : null;
                                  _shareSession(
                                    session,
                                    sharePositionOrigin: origin,
                                  );
                                },
                              );
                            },
                          ),
                          if (isRealSession)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.accentRed,
                                size: 20,
                              ),
                              tooltip: 'Delete workout record',
                              onPressed: () {
                                widget.controller.deleteHistorySession(
                                  session.id,
                                );
                                Navigator.pop(ctx);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _detailCapsule(
                          icon: Icons.schedule_rounded,
                          label: 'Duration',
                          value: _formatDuration(session.durationSeconds),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _detailCapsule(
                          icon: Icons.repeat_rounded,
                          label: 'Total Reps',
                          value: session.totalReps > 0
                              ? session.totalReps.toLocaleString()
                              : (216).toLocaleString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _detailCapsule(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Sets Logged',
                          value:
                              '${session.completedSetCount > 0 ? session.completedSetCount : 27}',
                        ),
                      ),
                    ],
                  ),
                  if (session.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _HColors.stoneTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _HColors.stoneLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SESSION NOTES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _HColors.emerald700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.notes,
                            style: TextStyle(
                              fontSize: 13,
                              color: _HColors.obsidian,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'EXERCISE SET LOG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _HColors.stoneMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (session.sets.any((s) => s.isCompleted))
                    ...session.sets
                        .where((s) => s.isCompleted)
                        .map(
                          (s) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _HColors.stoneTint,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _HColors.stoneLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _HColors.stoneLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${s.setIndex + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _HColors.obsidian,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.exerciseName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _HColors.obsidian,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${s.reps} reps${s.addedWeightKg > 0 ? ' (+${s.addedWeightKg}kg)' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _HColors.accentMint,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No completed sets logged for this session.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _HColors.stoneMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailCapsule({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _HColors.stoneTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _HColors.stoneLight),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: _HColors.accentMint),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _HColors.obsidian,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: _HColors.stoneMuted,
              fontWeight: FontWeight.w600,
            ),
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
        final realHistory = widget.controller.history;

        return Scaffold(
          backgroundColor: _HColors.canvas,
          body: Stack(
            children: [
              // Scrollable Body
              Scrollbar(
                controller: historyScrollController,
                child: SingleChildScrollView(
                  controller: historyScrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.paddingOf(context).top + 68,
                    16,
                    (widget.controller.activeSession != null ? 180 : 120) +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Floating Horizontal Weekly Consistency Chip Bar
                          _buildWeeklyConsistencyBar(realHistory),
                          const SizedBox(height: 14),

                          // 2. Monthly Heatmap Card with Bento Header & Dedicated Telemetry Capsule
                          _buildMonthlyHeatmapCard(realHistory),
                          const SizedBox(height: 14),

                          // 3. Peak PR Achieved Callout Banner
                          _buildPeakPrBanner(realHistory),
                          const SizedBox(height: 18),

                          // 5. Chronological Timeline Stream: Recent Workout Logs
                          _buildTimelineStream(realHistory),
                          const SizedBox(height: 16),

                          // 6. Reddit Markdown Export Banner
                          _buildRedditExportBanner(realHistory),
                          const SizedBox(height: 24),

                          // 7. Version Indicator
                          const Center(child: VersionIndicator()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Fixed Glassmorphic Header (top-0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(context, realHistory),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // HEADER
  // =========================================================================
  Widget _buildHeader(BuildContext context, List<WorkoutSession> realHistory) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: _HColors.canvas.withValues(alpha: 0.94),
            border: Border(
              bottom: BorderSide(
                color: _HColors.stoneBorder.withValues(alpha: 0.6),
              ),
            ),
            boxShadow: _isCalendarDropdownOpen
                ? const [
                    BoxShadow(
                      color: Color(0x0E1E232A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 8,
                  bottom: 10,
                  left: 20,
                  right: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Clean Title (dumbbell icon & subtitle row removed)
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _HColors.obsidian,
                        letterSpacing: -0.4,
                      ),
                    ),

                    // Calendar Button (clicking pops scrollable horizontal calendar dropdown)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleCalendarDropdown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isCalendarDropdownOpen
                              ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian)
                              : _HColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isCalendarDropdownOpen
                                ? (_HColors.isDark ? _HColors.primary : _HColors.obsidian)
                                : _HColors.stoneBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _HColors.isDark ? 0.3 : 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 16,
                              color: _isCalendarDropdownOpen
                                  ? Colors.white
                                  : _HColors.obsidian,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isCalendarDropdownOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: _isCalendarDropdownOpen
                                  ? Colors.white
                                  : _HColors.stoneMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dropdown of drilldown interactive calendar
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: _buildDrilldownCalendar(realHistory),
                crossFadeState: _isCalendarDropdownOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 240),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // DRILL-DOWN CALENDAR (YEAR -> MONTH -> DATE & VICE VERSA)
  // =========================================================================
  Widget _buildDrilldownCalendar(List<WorkoutSession> realHistory) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        color: _HColors.canvas,
        border: Border(
          top: BorderSide(color: _HColors.stoneBorder, width: 1),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _buildCurrentCalendarView(realHistory, now),
      ),
    );
  }

  Widget _buildCurrentCalendarView(
    List<WorkoutSession> realHistory,
    DateTime now,
  ) {
    switch (_calendarViewMode) {
      case CalendarViewMode.years:
        return _buildYearsView(realHistory, now);
      case CalendarViewMode.months:
        return _buildMonthsView(realHistory, now);
      case CalendarViewMode.dates:
        return _buildDatesView(realHistory, now);
    }
  }

  Widget _buildDatesView(List<WorkoutSession> realHistory, DateTime now) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayWeekday = DateTime(year, month, 1).weekday; // 1=Mon, 7=Sun
    final leadingDaysCount = firstDayWeekday - 1;
    final prevMonthDaysCount = DateUtils.getDaysInMonth(
      month == 1 ? year - 1 : year,
      month == 1 ? 12 : month - 1,
    );

    final sessionsInMonth = realHistory.where(
      (s) => s.startTime.year == year && s.startTime.month == month,
    ).toList();
    final workoutDays = sessionsInMonth.map((s) => s.startTime.day).toSet();

    final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final totalGridTiles = ((leadingDaysCount + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      key: ValueKey('dates_${year}_$month'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation Bar: [<] [Month ▾] [Year ▾] [>] + [Today]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Previous Month Arrow
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: _HColors.obsidian,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = DateTime(year, month - 1);
                    });
                  },
                ),
                const SizedBox(width: 4),

                // Month Button (Tapping opens Months view)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _calendarViewMode = CalendarViewMode.months;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _HColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _HColors.stoneBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('MMMM').format(_selectedMonth),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _HColors.obsidian,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _HColors.stoneMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Year Button (Tapping opens Years view)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _yearsBase = (year ~/ 12) * 12;
                      _calendarViewMode = CalendarViewMode.years;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _HColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _HColors.stoneBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _HColors.obsidian,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _HColors.stoneMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Next Month Arrow
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: _HColors.obsidian,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = DateTime(year, month + 1);
                    });
                  },
                ),
              ],
            ),

            // Today Button
            if (year != now.year || month != now.month || _selectedDate != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedMonth = DateTime(now.year, now.month);
                    _selectedDate = DateTime(now.year, now.month, now.day);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _HColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _HColors.emerald200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today_rounded, size: 12, color: _HColors.emerald700),
                      SizedBox(width: 3),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _HColors.emerald700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayLetters.map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _HColors.stoneMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),

        // 7-Column Dates Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalGridTiles,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, i) {
            if (i < leadingDaysCount) {
              final prevDay = prevMonthDaysCount - leadingDaysCount + 1 + i;
              return Center(
                child: Text(
                  '$prevDay',
                  style: TextStyle(
                    fontSize: 11,
                    color: _HColors.stoneMuted.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            final day = i - leadingDaysCount + 1;
            if (day > daysInMonth) {
              final nextDay = day - daysInMonth;
              return Center(
                child: Text(
                  '$nextDay',
                  style: TextStyle(
                    fontSize: 11,
                    color: _HColors.stoneMuted.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            final date = DateTime(year, month, day);
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isSelected = _selectedDate != null &&
                _selectedDate!.year == date.year &&
                _selectedDate!.month == date.month &&
                _selectedDate!.day == date.day;
            final hasWorkout = workoutDays.contains(day);

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDate = isSelected ? null : date;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian)
                      : (isToday ? _HColors.emerald50 : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? (_HColors.isDark ? Colors.white : _HColors.obsidian)
                        : (isToday
                            ? _HColors.accentMint
                            : (hasWorkout
                                ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.stoneLight)
                                : Colors.transparent)),
                    width: isSelected || isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected || isToday || hasWorkout
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? _HColors.emerald700
                                : (hasWorkout
                                    ? _HColors.textPrimary
                                    : _HColors.stoneMuted)),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasWorkout
                            ? (isSelected ? Colors.white : _HColors.accentMint)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Bottom status pill
        const SizedBox(height: 8),
        if (_selectedDate != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${DateFormat('EEE, MMM d').format(_selectedDate!)} workouts',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _HColors.emerald700,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = null);
                },
                child: Text(
                  'Clear Filter',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _HColors.obsidian,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            '${sessionsInMonth.length} workouts logged in ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _HColors.stoneMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildMonthsView(List<WorkoutSession> realHistory, DateTime now) {
    final year = _selectedMonth.year;
    final allMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final sessionsInYear = realHistory.where((s) => s.startTime.year == year).toList();

    return Column(
      key: ValueKey('months_$year'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation Bar: [<] "Select Month" [Year ▾] [>] + [Dates ✕]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: _HColors.obsidian,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = DateTime(year - 1, _selectedMonth.month);
                    });
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  'Month for',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _HColors.stoneMuted,
                  ),
                ),
                const SizedBox(width: 6),
                // Clicking Year opens Years View!
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _yearsBase = (year ~/ 12) * 12;
                      _calendarViewMode = CalendarViewMode.years;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _HColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _HColors.stoneBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _HColors.obsidian,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: _HColors.stoneMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: _HColors.obsidian,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = DateTime(year + 1, _selectedMonth.month);
                    });
                  },
                ),
              ],
            ),
            // Return to Dates button
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _calendarViewMode = CalendarViewMode.dates;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _HColors.stoneTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _HColors.stoneBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Dates',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _HColors.obsidian,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.calendar_view_month_rounded, size: 12, color: _HColors.obsidian),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 12 Months Grid (4 rows x 3 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, i) {
            final monthNum = i + 1;
            final isSelected = monthNum == _selectedMonth.month;
            final isCurrentMonth = monthNum == now.month && year == now.year;
            final sessionCount = sessionsInYear.where((s) => s.startTime.month == monthNum).length;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMonth = DateTime(year, monthNum);
                  _calendarViewMode = CalendarViewMode.dates; // DRILLS DOWN TO DATES!
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian)
                      : (isCurrentMonth
                          ? _HColors.emerald50
                          : _HColors.surfaceCard),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (_HColors.isDark ? Colors.white : _HColors.obsidian)
                        : (isCurrentMonth
                            ? _HColors.accentMint
                            : _HColors.stoneBorder),
                    width: isSelected || isCurrentMonth ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      shortMonths[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : (isCurrentMonth
                                ? _HColors.emerald700
                                : _HColors.obsidian),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sessionCount > 0 ? '$sessionCount logs' : allMonths[i],
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (_HColors.isDark ? _HColors.textSecondary : _HColors.accentMint)
                            : (isCurrentMonth
                                ? _HColors.emerald700
                                : _HColors.stoneMuted),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearsView(List<WorkoutSession> realHistory, DateTime now) {
    final startYear = _yearsBase;
    final endYear = _yearsBase + 11;

    return Column(
      key: ValueKey('years_$_yearsBase'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation Bar: [<] "$startYear – $endYear" [>] + [Months ✕]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: _HColors.obsidian,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _yearsBase -= 12;
                    });
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  '$startYear – $endYear',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _HColors.obsidian,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: _HColors.obsidian,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _yearsBase += 12;
                    });
                  },
                ),
              ],
            ),
            // Return to Months button
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _calendarViewMode = CalendarViewMode.months;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _HColors.stoneTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _HColors.stoneBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Months',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _HColors.obsidian,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: _HColors.obsidian),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 12 Years Grid (4 rows x 3 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, i) {
            final y = startYear + i;
            final isSelected = y == _selectedMonth.year;
            final isCurrentYear = y == now.year;
            final workoutCount = realHistory.where((s) => s.startTime.year == y).length;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMonth = DateTime(y, _selectedMonth.month);
                  _calendarViewMode = CalendarViewMode.months; // DRILLS DOWN TO MONTHS!
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian)
                      : (isCurrentYear
                          ? _HColors.emerald50
                          : _HColors.surfaceCard),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (_HColors.isDark ? Colors.white : _HColors.obsidian)
                        : (isCurrentYear
                            ? _HColors.accentMint
                            : _HColors.stoneBorder),
                    width: isSelected || isCurrentYear ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$y',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : (isCurrentYear
                                ? _HColors.emerald700
                                : _HColors.obsidian),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      workoutCount > 0 ? '$workoutCount workouts' : 'No logs',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (_HColors.isDark ? _HColors.textSecondary : _HColors.accentMint)
                            : (isCurrentYear
                                ? _HColors.emerald700
                                : _HColors.stoneMuted),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================================
  // 1. FLOATING HORIZONTAL WEEKLY CONSISTENCY CHIP BAR
  // =========================================================================
  Widget _buildWeeklyConsistencyBar(List<WorkoutSession> realHistory) {
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final rangeText =
        '${DateFormat('MMM d').format(monday).toUpperCase()} - ${DateFormat('d').format(sunday).toUpperCase()}';

    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final hasWorkout = realHistory.any(
        (s) =>
            s.startTime.year == d.year &&
            s.startTime.month == d.month &&
            s.startTime.day == d.day,
      );
      final isLatest =
          realHistory.isNotEmpty &&
          realHistory.first.startTime.year == d.year &&
          realHistory.first.startTime.month == d.month &&
          realHistory.first.startTime.day == d.day;
      return {
        'day': dayNames[i],
        'date': d.day,
        'status': hasWorkout ? (isLatest ? 'pr' : 'logged') : 'rest',
      };
    });

    final String streakPillText = realHistory.isEmpty
        ? '0 Week Streak'
        : (realHistory.length == 1
              ? '1 Session'
              : '${realHistory.length} Sessions');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _HColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HColors.stoneBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E232A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WEEKLY CONSISTENCY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _HColors.stoneMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _HColors.stoneTint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rangeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _HColors.obsidian,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Streak Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _HColors.emerald50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _HColors.emerald200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: _HColors.accentMint,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      streakPillText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _HColors.emerald700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 7-Day Horizontal Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) {
              final status = d['status'] as String;
              final isPR = status == 'pr';
              final isLogged = status == 'logged';

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isPR
                        ? (_HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian)
                        : (isLogged
                              ? _HColors.stoneTint
                              : (_HColors.isDark ? _HColors.inset : const Color(0x30F5F5F4))),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPR
                          ? _HColors.emerald200
                          : (isLogged
                                ? _HColors.stoneLight
                                : (_HColors.isDark ? _HColors.stoneBorder.withValues(alpha: 0.4) : Colors.transparent)),
                      width: isPR ? 1.5 : 1,
                    ),
                    boxShadow: isPR
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _HColors.isDark ? 0.3 : 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        d['day'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isPR ? FontWeight.w900 : FontWeight.w700,
                          color: isPR
                              ? _HColors.accentMint
                              : (isLogged
                                    ? _HColors.stoneMuted
                                    : _HColors.stoneMuted.withValues(alpha: 0.6)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d['date']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (isPR || isLogged)
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isPR
                              ? Colors.white
                              : (isLogged
                                    ? _HColors.obsidian
                                    : _HColors.stoneMuted.withValues(alpha: 0.6)),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPR
                              ? _HColors.accentMint
                              : (isLogged
                                    ? _HColors.accentMint
                                    : Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. MONTHLY HEATMAP CARD
  // =========================================================================
  Widget _buildMonthlyHeatmapCard(List<WorkoutSession> realHistory) {
    // Generate days of current month view
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayWeekday = DateTime(
      year,
      month,
      1,
    ).weekday; // 1 = Mon, 7 = Sun

    final monthSessions = realHistory
        .where((s) => s.startTime.year == year && s.startTime.month == month)
        .toList();
    final int monthLoadReps = monthSessions.fold(
      0,
      (sum, s) => sum + s.totalReps,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _HColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HColors.stoneBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E232A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Tappable Dropdown Toggle)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isHeatmapExpanded = !_isHeatmapExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _HColors.emerald50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _HColors.emerald200),
                        ),
                        child: Icon(
                          Icons.calendar_view_month_rounded,
                          size: 16,
                          color: _HColors.accentMint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY HEATMAP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _HColors.stoneMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedMonth = DateTime(
                                        _selectedMonth.year,
                                        _selectedMonth.month - 1,
                                      );
                                    });
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _scrollToCurrentDay();
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 17,
                                      color: _HColors.stoneMuted,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _showMonthPickerSheet,
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(_selectedMonth),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _HColors.obsidian,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedMonth = DateTime(
                                        _selectedMonth.year,
                                        _selectedMonth.month + 1,
                                      );
                                    });
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _scrollToCurrentDay();
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 17,
                                      color: _HColors.stoneMuted,
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
                const SizedBox(width: 8),
                // Dedicated Telemetry Capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _HColors.emerald50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _HColors.emerald200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: _HColors.accentMint,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${monthSessions.length} / $daysInMonth Logged',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _HColors.emerald700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Dropdown Chevron Indicator
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _HColors.stoneTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: _HColors.stoneLight),
                  ),
                  child: Icon(
                    _isHeatmapExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _HColors.stoneMuted,
                  ),
                ),
              ],
            ),
          ),

          // Collapsible Heatmap Grid & Legend
          if (_isHeatmapExpanded) ...[
            const SizedBox(height: 12),

            // Calendar Heatmap Grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _HColors.stoneTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _HColors.stoneLight),
              ),
              child: Column(
                children: [
                  // Weekday Headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _HColors.stoneMuted,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),

                  // Heatmap Tiles (5 weeks)
                  _buildHeatmapTiles(firstDayWeekday, daysInMonth, realHistory),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Legend + Month Load Capsule
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendItem('Rest', _HColors.stoneLight),
                    const SizedBox(width: 8),
                    _legendItem('Mobility', _HColors.emerald100),
                    const SizedBox(width: 8),
                    _legendItem('Session', _HColors.accentMint),
                    const SizedBox(width: 8),
                    _legendItem('PR Day', _HColors.obsidian),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _HColors.stoneTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _HColors.stoneLight),
                  ),
                  child: Text(
                    'Month Load: ${monthLoadReps.toLocaleString()} Strict Reps',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _HColors.obsidian,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Month Load: ${monthLoadReps.toLocaleString()} Strict Reps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _HColors.stoneMuted,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isHeatmapExpanded = true;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Heatmap',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _HColors.obsidian,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: _HColors.obsidian,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeatmapTiles(
    int firstDayWeekday,
    int daysInMonth,
    List<WorkoutSession> realHistory,
  ) {
    // 35 tiles total (5 weeks x 7)
    final tiles = <Widget>[];

    // Leading padding days (from previous month)
    final prevMonthDaysCount = firstDayWeekday - 1;
    for (int i = 0; i < prevMonthDaysCount; i++) {
      tiles.add(
        Container(
          height: 26,
          alignment: Alignment.center,
          child: Text(
            '${30 - (prevMonthDaysCount - 1 - i)}',
            style: TextStyle(
              fontSize: 10,
              color: _HColors.stoneMuted.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Days in current month derived from real history
    final monthSessions = realHistory
        .where(
          (s) =>
              s.startTime.year == _selectedMonth.year &&
              s.startTime.month == _selectedMonth.month,
        )
        .toList();
    final sessionDays = monthSessions.map((s) => s.startTime.day).toSet();
    final prDay = monthSessions.isNotEmpty
        ? monthSessions.first.startTime.day
        : -1;
    final mobilityDays = <int>{};

    for (int day = 1; day <= daysInMonth; day++) {
      final isPR = day == prDay;
      final isSession = sessionDays.contains(day);
      final isMobility = mobilityDays.contains(day);

      Color bgColor = _HColors.isDark ? _HColors.inset : Colors.white;
      Color textColor = _HColors.stoneMuted;
      FontWeight fontWeight = FontWeight.w500;
      Border? border;

      if (isPR) {
        bgColor = _HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian;
        textColor = _HColors.isDark ? Colors.white : _HColors.accentMint;
        fontWeight = FontWeight.w900;
        border = Border.all(color: _HColors.emerald200, width: 1.5);
      } else if (isSession) {
        bgColor = _HColors.accentMint;
        textColor = Colors.white;
        fontWeight = FontWeight.w800;
      } else if (isMobility) {
        bgColor = _HColors.emerald100;
        textColor = _HColors.emerald700;
        fontWeight = FontWeight.w700;
      } else {
        bgColor = _HColors.isDark ? _HColors.inset : Colors.white;
        border = Border.all(color: _HColors.stoneBorder.withValues(alpha: 0.6));
      }

      tiles.add(
        Container(
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: border,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
              ),
              if (isPR)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _HColors.accentMint,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Trailing padding days
    final remaining = 35 - tiles.length;
    for (int i = 1; i <= remaining; i++) {
      tiles.add(
        Container(
          height: 26,
          alignment: Alignment.center,
          child: Text(
            '$i',
            style: TextStyle(
              fontSize: 10,
              color: _HColors.stoneMuted.withValues(alpha: 0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.3,
      children: tiles,
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: _HColors.stoneLight),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: _HColors.stoneMuted,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 4. PEAK PR ACHIEVED BANNER
  // =========================================================================
  Widget _buildPeakPrBanner(List<WorkoutSession> realHistory) {
    final bool hasHistory = realHistory.isNotEmpty;
    final WorkoutSession? bestSession = hasHistory
        ? realHistory.reduce((a, b) => a.totalReps >= b.totalReps ? a : b)
        : null;

    final String titleText = hasHistory
        ? 'PEAK PR ACHIEVED'
        : 'ESTABLISH YOUR BASELINE';
    final String dateBadge = hasHistory
        ? DateFormat('EEE MMM d').format(bestSession!.startTime)
        : 'Ready';
    final String subtitleText = hasHistory
        ? '${bestSession!.completedSetCount} Completed Sets (${bestSession.totalReps} total reps)'
        : 'Log your first workout to record strict reps and track personal records.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_HColors.emerald50, _HColors.surfaceCard, _HColors.stoneTint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HColors.emerald200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _HColors.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _HColors.isDark ? _HColors.stoneBorder : _HColors.obsidian,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: _HColors.isDark ? _HColors.accentMint : Colors.white,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _HColors.accentMint,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _HColors.isDark ? _HColors.surfaceCard : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            titleText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _HColors.emerald700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _HColors.isDark
                                  ? _HColors.stoneBorder
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _HColors.emerald200),
                            ),
                            child: Text(
                              dateBadge,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: _HColors.emerald700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _HColors.obsidian,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Celebrate Action
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    '🎉 Phenomenal work! Progressive overload verified.',
                  ),
                  backgroundColor: _HColors.obsidianDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _HColors.isDark ? _HColors.surfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _HColors.isDark
                      ? _HColors.stoneBorder
                      : _HColors.emerald200,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Celebrate',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _HColors.emerald700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: _HColors.emerald700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. CHRONOLOGICAL TIMELINE STREAM: RECENT WORKOUT LOGS
  // =========================================================================
  Widget _buildTimelineStream(List<WorkoutSession> realHistory) {
    if (realHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Logs',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _HColors.obsidian,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _HColors.stoneLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '0 Sessions',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _HColors.stoneMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              color: _HColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _HColors.stoneBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1E232A),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _HColors.stoneTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: _HColors.stoneMuted,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No Workouts Logged Yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _HColors.obsidian,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Completed workouts, set details, and PR achievements will appear here.\nTap "Start Workout" on Home to begin your first session!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _HColors.stoneMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final targetHistory = _selectedDate != null
        ? realHistory.where((s) =>
            s.startTime.year == _selectedDate!.year &&
            s.startTime.month == _selectedDate!.month &&
            s.startTime.day == _selectedDate!.day).toList()
        : realHistory;

    final List<Map<String, dynamic>> sessions = [];
    for (int i = 0; i < targetHistory.length; i++) {
      final s = targetHistory[i];
      sessions.add({
        'id': s.id,
        'date': DateFormat('EEEE, MMM d').format(s.startTime),
        'duration': _formatDuration(s.durationSeconds),
        'session': s,
        'isPR': i == 0,
        'isReal': true,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Recent Logs',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _HColors.obsidian,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _HColors.stoneLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sessions.length} Sessions',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _HColors.stoneMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filtered date banner (if a date is selected in the calendar)
        if (_selectedDate != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _HColors.emerald50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _HColors.emerald200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      size: 14,
                      color: _HColors.emerald700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filtered: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _HColors.emerald700,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                  child: Text(
                    'Show All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _HColors.obsidian,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (sessions.isEmpty && _selectedDate != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: _HColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _HColors.stoneBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 32,
                    color: _HColors.stoneMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No workouts logged on ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _HColors.obsidian,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedDate = null);
                    },
                    child: const Text('Show All Workouts'),
                  ),
                ],
              ),
            ),
          )
        else
          // Timeline with Continuous Vertical Guide Rail
        Stack(
          children: [
            // Vertical Guide Rail Line
            Positioned(
              left: 10,
              top: 14,
              bottom: 24,
              child: Container(
                width: 2,
                color: _HColors.isDark ? _HColors.stoneBorder : _HColors.stoneLight,
              ),
            ),

            // Timeline Items
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                children: sessions.map((item) {
                  final id = item['id'] as String;
                  final isExpanded = _expandedSessionIds.contains(id);
                  final isPR = item['isPR'] as bool;
                  final isReal = item['isReal'] as bool;

                  WorkoutSession? sessionObj;
                  if (isReal) {
                    sessionObj = item['session'] as WorkoutSession;
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Node Pin
                      Positioned(
                        left: -26,
                        top: 14,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPR
                                ? _HColors.accentMint
                                : (_HColors.isDark
                                    ? _HColors.stoneBorder
                                    : _HColors.obsidian),
                            border: Border.all(
                              color: isPR
                                  ? _HColors.emerald100
                                  : (_HColors.isDark
                                      ? _HColors.primary
                                      : _HColors.stoneLight),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPR
                                    ? Colors.white
                                    : (_HColors.isDark
                                        ? _HColors.accentMint
                                        : Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Card Content
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: _HColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _HColors.stoneBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A1E232A),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Compact Header Row (Accordion Trigger)
                            InkWell(
                              onTap: () => _toggleAccordion(id),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item['date'] as String,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: _HColors.obsidian,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPR
                                                  ? _HColors.emerald50
                                                  : _HColors.stoneTint,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isPR
                                                    ? _HColors.emerald200
                                                    : _HColors.stoneLight,
                                              ),
                                            ),
                                            child: Text(
                                              isPR ? 'PR Day' : 'Completed',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: isPR
                                                    ? _HColors.emerald700
                                                    : _HColors.stoneMuted,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _HColors.stoneTint,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 12,
                                                color: _HColors.stoneMuted,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                item['duration'] as String,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: _HColors.obsidian,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: _HColors.stoneMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Collapsible Content
                            if (isExpanded) ...[
                              Container(
                                height: 1,
                                color: _HColors.stoneBorder.withValues(alpha: 0.5),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isReal
                                              ? 'BWF Recommended Routine'
                                              : (item['title'] as String),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _HColors.stoneMuted,
                                          ),
                                        ),
                                        if (sessionObj != null)
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _showSessionDetails(
                                              sessionObj!,
                                            ),
                                            child: Icon(
                                              Icons.more_vert_rounded,
                                              size: 16,
                                              color: _HColors.stoneMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Telemetry Pill Row
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _HColors.stoneTint,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 12,
                                              color: _HColors.obsidian,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item['duration'] as String,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: _HColors.obsidian,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '•',
                                              style: TextStyle(
                                                color: _HColors.stoneLight,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.fitness_center_rounded,
                                              size: 12,
                                              color: _HColors.obsidian,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '3 Pairs',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: _HColors.obsidian,
                                              ),
                                            ),
                                            if (isPR) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  color: _HColors.stoneLight,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.check_rounded,
                                                size: 12,
                                                color: _HColors.accentMint,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Passed Progression',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: _HColors.emerald700,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Structured Exercises Sub-Cards
                                    if (isReal && sessionObj != null)
                                      ..._buildRealExerciseCards(sessionObj)
                                    else
                                      ...((item['exercises'] as List<dynamic>).map((
                                        ex,
                                      ) {
                                        final badge = ex['badge'] as String;
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _HColors.stoneTint,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: _HColors.stoneBorder,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 5,
                                                      height: 5,
                                                      decoration:
                                                          BoxDecoration(
                                                            color: _HColors
                                                                .accentMint,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        ex['name'] as String,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              _HColors.obsidian,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    ex['detail'] as String,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          _HColors.stoneMuted,
                                                    ),
                                                  ),
                                                  if (badge.isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 1.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            ex['badgeBg']
                                                                as Color,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: _HColors
                                                              .emerald200,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        badge,
                                                        style: TextStyle(
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color:
                                                              ex['badgeColor']
                                                                  as Color,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList()),

                                    const SizedBox(height: 6),

                                    // PR Banner & View Action
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (isPR)
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _HColors.emerald50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: _HColors.emerald200,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.military_tech_rounded,
                                                    size: 13,
                                                    color: _HColors.emerald700,
                                                  ),
                                                  SizedBox(width: 3),
                                                  Flexible(
                                                    child: Text(
                                                      'PR: +1 Rep Strict Pull-Up',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            _HColors.emerald700,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),

                                        if (sessionObj != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: () {
                                                  _showShareDialog(
                                                    context,
                                                    sessionObj!,
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.share_outlined,
                                                      size: 13,
                                                      color:
                                                          _HColors.stoneMuted,
                                                    ),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Share',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            _HColors.stoneMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: () =>
                                                    _showSessionDetails(
                                                      sessionObj!,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'View Full Log',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            _HColors.obsidian,
                                                      ),
                                                    ),
                                                    SizedBox(width: 2),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 12,
                                                      color: _HColors.obsidian,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildRealExerciseCards(WorkoutSession session) {
    // Group sets by exercise
    final Map<String, List<LoggedSet>> groups = {};
    for (final s in session.sets.where((s) => s.isCompleted)) {
      groups.putIfAbsent(s.exerciseName, () => []).add(s);
    }

    if (groups.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Completed warmup & mobility session',
            style: TextStyle(fontSize: 11, color: _HColors.stoneMuted),
          ),
        ),
      ];
    }

    return groups.entries.map((entry) {
      final totalSets = entry.value.length;
      final repsList = entry.value.map((s) => s.reps).join(', ');
      final weight = entry.value.first.addedWeightKg;

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _HColors.stoneTint,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _HColors.stoneBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _HColors.accentMint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _HColors.obsidian,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalSets sets ($repsList reps)${weight > 0 ? ' @ +${weight}kg' : ''}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _HColors.stoneMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // =========================================================================
  // 6. REDDIT MARKDOWN EXPORT BANNER
  // =========================================================================
  Widget _buildRedditExportBanner(List<WorkoutSession> realHistory) {
    final sessionToExport = realHistory.isNotEmpty ? realHistory.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _HColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HColors.stoneBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E232A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final target =
                    sessionToExport ?? _generateCurrentRoutineSession();
                _showShareDialog(context, target);
              },
              child: Row(
                children: [
                  // Animated copy icon — taps animate with a scale bounce + color flash
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      setState(() => _copyIconPressed = true);
                    },
                    onTapUp: (_) {
                      setState(() => _copyIconPressed = false);
                      final target =
                          sessionToExport ?? _generateCurrentRoutineSession();
                      _copyRedditMarkdown(target);
                    },
                    onTapCancel: () {
                      setState(() => _copyIconPressed = false);
                    },
                    child: AnimatedScale(
                      scale: _copyIconPressed ? 0.82 : 1.0,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _copiedReddit
                              ? _HColors.accentMint
                              : _HColors.emerald50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _copiedReddit
                                ? _HColors.accentMint
                                : _HColors.emerald200,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            _copiedReddit
                                ? Icons.check_rounded
                                : Icons.content_copy_rounded,
                            key: ValueKey(_copiedReddit),
                            size: 18,
                            color: _copiedReddit
                                ? Colors.white
                                : _HColors.accentMint,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reddit Markdown Export',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _HColors.obsidian,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'r/bodyweightfitness format',
                          style: TextStyle(
                            fontSize: 11,
                            color: _HColors.stoneMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Share Button — triggers native share sheet or in-app share dialog
          Builder(
            builder: (btnCtx) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final box = btnCtx.findRenderObject() as RenderBox?;
                  final origin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;
                  final target =
                      sessionToExport ?? _generateCurrentRoutineSession();
                  await _shareSession(target, sharePositionOrigin: origin);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _HColors.isDark
                        ? _HColors.stoneBorder
                        : _HColors.obsidian,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x201E232A),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ios_share_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
