import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';
import '../data/bwf_routine_data.dart';
import '../controllers/workout_controller.dart';
import '../utils/formatters.dart';
import '../widgets/version_indicator.dart';
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
  int _selectedPairIndex = 0; // 0: Pair 1, 1: Pair 2, 2: Pair 3, 3: Core Triplet
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey<ProgressionLadderScreenState> _progressionLadderKey = GlobalKey();
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkChangelog());
  }

  void _checkChangelog() {
    final storage = widget.controller.storage;
    final lastSeen = storage.getLastSeenVersion();
    const currentVersion = VersionIndicator.version;
    if (lastSeen != currentVersion) {
      storage.setLastSeenVersion(currentVersion);
      _showChangelogModal();
    }
  }

  void _showChangelogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stoneBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentMintTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.obsidian, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "What's New in BWF Tracker",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.obsidian,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildChangelogItem('Warm Tactical Aesthetic', 'Crafted high-contrast, distraction-free surfaces inspired by athletic discipline.'),
                _buildChangelogItem('Alternating Routine Pairs', 'Authentic BWF paired sets with automatic 90s rest and progression switching.'),
                _buildChangelogItem('Offline Persistence & Reddit Export', 'Zero data loss with local drafts and one-tap formatted Reddit markdown logs.'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Got it, Let's Train"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangelogItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 10),
            child: Icon(Icons.check_circle_rounded, color: AppColors.accentMint, size: 16),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5, color: AppColors.stone, height: 1.4, fontFamily: 'Manrope'),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.obsidian)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final controller = widget.controller;
    final profile = controller.userProfile;
    final history = controller.history;
    final totalReps = history.fold(0, (sum, s) => sum + s.totalReps);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stoneBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppColors.obsidian,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: AppColors.accentMint, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile?.name ?? 'Athlete',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.obsidian,
                                    letterSpacing: -0.4,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(sheetCtx);
                                  _showEditNameDialog(context);
                                },
                                child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.stoneMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?.isGuest == true ? 'Guest Athlete (Local Account)' : 'Athlete Profile',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.stoneMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Goal info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.stoneTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.stoneBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE TRAINING GOAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.stoneMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.fitnessGoal ?? 'Full Body Routine Progression',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.obsidian,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Local device storage badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.emerald200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.emerald700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '100% Private · All stats and workouts are stored locally on your device.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quick stats summary
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.stoneBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOGGED SESSIONS',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.stoneMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${history.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.obsidian,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.stoneBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL REPS',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.stoneMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalReps.toLocaleString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.obsidian,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Reset All Stats & Data button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      side: const BorderSide(color: AppColors.accentRed, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      _confirmResetAllData(context, sheetCtx);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.accentRed),
                        SizedBox(width: 8),
                        Text(
                          'Reset All Stats & Data',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentRed,
                          ),
                        ),
                      ],
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

  void _confirmResetAllData(BuildContext parentContext, BuildContext sheetCtx) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: parentContext,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accentRed, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reset All Data?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'This will permanently delete all workout history, reset progression levels to Level 1, clear active drafts, and reset your profile. You will be returned to the profile setup screen.',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.stone,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.stoneMuted, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                Navigator.pop(sheetCtx);
                await widget.controller.resetAllData();
              },
              child: const Text('Reset Everything', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final textController = TextEditingController(text: widget.controller.userProfile?.name ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Edit Athlete Name',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.obsidian),
          ),
          content: TextField(
            controller: textController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter name',
              filled: true,
              fillColor: AppColors.stoneTint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.stoneMuted, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.obsidian,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final trimmed = textController.text.trim();
                if (trimmed.isNotEmpty) {
                  final current = widget.controller.userProfile;
                  if (current != null) {
                    await widget.controller.saveProfile(current.copyWith(name: trimmed));
                  }
                }
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Home · BWF Routine';
      case 1:
        return 'Roadmap · BWF Routine';
      case 2:
        return 'History · BWF Routine';
      default:
        return 'BWF Recommended Routine';
    }
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_homeScrollController.hasClients) {
      _homeScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: _getTabTitle(_currentNavIndex),
      color: AppColors.obsidian,
      child: PrimaryScrollController(
        controller: _homeScrollController,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: AppColors.canvas,
              body: Stack(
                children: [
                  // Main Tab Content
                  IndexedStack(
                    index: _currentNavIndex,
                    children: [
                      _buildHomeTab(context),
                      ProgressionLadderScreen(
                        key: _progressionLadderKey,
                        controller: widget.controller,
                        title: 'Roadmap',
                      ),
                      HistoryScreen(
                        key: _historyKey,
                        controller: widget.controller,
                      ),
                    ],
                  ),

                  // Progressive dissolve gradient overlay below status bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.paddingOf(context).top + 16,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.canvas,
                              AppColors.canvas.withValues(alpha: 0.8),
                              AppColors.canvas.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Docked Full-Width Solid Bottom Navigation Bar (Edge-to-Edge, No Blur)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildDockedBottomNav(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 1. HOME TAB (RESPONSIVE & TYPOGRAPHICALLY REFINED) ---
  Widget _buildHomeTab(BuildContext context) {
    final controller = widget.controller;
    final activeDraft = controller.activeSession;
    final history = controller.history;

    // Calculate routine progress
    int totalSets = 0;
    int completedSets = 0;
    if (activeDraft != null) {
      totalSets = activeDraft.sets.length;
      completedSets = activeDraft.sets.where((s) => s.isCompleted).length;
    }
    final int progressPercent = totalSets > 0
        ? ((completedSets / totalSets) * 100).round()
        : (history.isNotEmpty ? 100 : 0);

    final int streakDays = history.isNotEmpty ? history.length : 0;
    final int totalReps = history.fold(0, (sum, s) => sum + s.totalReps);

    final String todayDateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isCompact = maxWidth < 380;
        final bool isWide = maxWidth >= 580;
        final double horizontalPadding = isCompact ? 16.0 : 20.0;
        final double verticalSpacing = isCompact ? 14.0 : 18.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Scrollbar(
              controller: _homeScrollController,
              child: SingleChildScrollView(
                controller: _homeScrollController,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  MediaQuery.paddingOf(context).top + (isCompact ? 10 : 14),
                  horizontalPadding,
                  116 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Header
                    _buildUserHeader(context, isCompact),
                    SizedBox(height: verticalSpacing),

                    // Date & Routine Subheader
                    _buildDateSubheader(todayDateStr, isCompact),
                    SizedBox(height: verticalSpacing),

                    // Hero Challenge Banner
                    _buildHeroCard(context, activeDraft, progressPercent, isCompact),
                    SizedBox(height: isCompact ? 18 : 24),

                    // Readiness & Metrics Grid
                    _buildReadinessMetrics(streakDays, totalReps, isCompact, isWide),
                    SizedBox(height: isCompact ? 18 : 24),

                    // Current Routine Pairs
                    _buildRoutinePairsSection(context, isCompact),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Header: Avatar, Name, Notification Bell ---
  Widget _buildUserHeader(BuildContext context, bool isCompact) {
    final double avatarSize = isCompact ? 40 : 44;
    final double iconBtnSize = isCompact ? 40 : 44;
    final profile = widget.controller.userProfile;
    final userName = profile?.name ?? 'Athlete';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showProfileSheet(context),
          child: Row(
            children: [
              // Avatar Container with Status Dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.stoneTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.obsidian,
                        size: isCompact ? 22 : 24,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: isCompact ? 11 : 12,
                      height: isCompact ? 11 : 12,
                      decoration: BoxDecoration(
                        color: AppColors.accentMint,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: isCompact ? 10 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hello, $userName',
                        style: TextStyle(
                          fontSize: isCompact ? 19 : 21,
                          fontWeight: FontWeight.w900,
                          color: AppColors.obsidian,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.stoneMuted,
                      ),
                    ],
                  ),
                  if (profile?.isGuest == true)
                    const Text(
                      'Guest Account · Tap to view profile',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stoneMuted,
                      ),
                    )
                  else
                    const Text(
                      'Tap to view profile & stats',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.stoneMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Notification Bell Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('BWF Recommended Routine is fully synced and ready!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            width: iconBtnSize,
            height: iconBtnSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.obsidian,
              size: isCompact ? 20 : 22,
            ),
          ),
        ),
      ],
    );
  }

  // --- Subheader: Routine Week & Dynamic Calendar Date ---
  Widget _buildDateSubheader(String dateStr, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S ROUTINE • WEEK ${widget.controller.currentWeekNumber}, DAY ${widget.controller.currentRoutineDay}",
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            fontWeight: FontWeight.w800,
            color: AppColors.stoneMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: isCompact ? 18 : 20,
              color: AppColors.obsidian,
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: isCompact ? 19 : 22,
                fontWeight: FontWeight.w900,
                color: AppColors.obsidian,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Hero Challenge Banner Card ---
  Widget _buildHeroCard(
    BuildContext context,
    dynamic activeDraft,
    int progressPercent,
    bool isCompact,
  ) {
    final double cardPadding = isCompact ? 16 : 20;
    final double progressContainerSize = isCompact ? 80 : 90;
    final double ringSize = isCompact ? 50 : 58;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.sandCard,
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedGray,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.stoneTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  size: 16,
                  color: AppColors.obsidian,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 12),

          // Middle Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentMintTint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentMintBorder),
                      ),
                      child: const Text(
                        'Full Body RR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentMintDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recommended\nRoutine',
                        style: TextStyle(
                          fontSize: isCompact ? 22 : 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.obsidian,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 13,
                              color: AppColors.stoneMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activeDraft != null ? 'Active' : '3 hours',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.stoneMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const Row(
                          children: [
                            Icon(
                              Icons.military_tech_rounded,
                              size: 14,
                              color: AppColors.stoneMuted,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Beginner',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.stoneMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right side circular progress container
              Container(
                width: progressContainerSize,
                height: progressContainerSize,
                decoration: BoxDecoration(
                  color: AppColors.accentMintTint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentMintBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: CircularProgressIndicator(
                        value: progressPercent / 100,
                        backgroundColor: AppColors.trackRing,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.obsidian,
                        ),
                        strokeWidth: isCompact ? 4.0 : 4.5,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: isCompact ? 11.5 : 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.obsidian,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 14 : 16),

          // Bottom Continue Action Button (with arrow circle)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              if (activeDraft == null) {
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
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(isCompact ? 16 : 20, 9, 8, 9),
              decoration: BoxDecoration(
                color: AppColors.obsidian,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    activeDraft != null ? 'Continue the workout' : 'Start Workout',
                    style: TextStyle(
                      fontSize: isCompact ? 12.5 : 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.obsidian,
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

  // --- 2. READINESS & METRICS SECTION (Adaptive 2x2 or 4-col Grid) ---
  Widget _buildReadinessMetrics(
    int streakDays,
    int totalReps,
    bool isCompact,
    bool isWide,
  ) {
    final double tileGap = isCompact ? 8 : 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Readiness & Metrics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.softCharcoal,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'LIVE DATA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedGray,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 8 : 10),

        // 2x2 Responsive Grid
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'STREAK',
                    value: '$streakDays Days',
                    subtitle: 'Consistent Habit',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.obsidian,
                    iconBg: AppColors.stoneTint,
                    isCompact: isCompact,
                  ),
                ),
                SizedBox(width: tileGap),
                Expanded(
                  child: _buildMetricTile(
                    title: 'RECOVERY',
                    value: widget.controller.history.isNotEmpty ? '92%' : '100%',
                    subtitle: widget.controller.history.isNotEmpty ? 'Ready for Load' : 'Fresh & Primed',
                    icon: Icons.favorite_rounded,
                    iconColor: AppColors.accentMintDark,
                    iconBg: AppColors.accentMintTint,
                    isCompact: isCompact,
                  ),
                ),
              ],
            ),
            SizedBox(height: tileGap),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'TEMPO',
                    value: '3-0-1-0',
                    subtitle: 'Eccentric Focus',
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.stoneMuted,
                    iconBg: AppColors.stoneTint,
                    isCompact: isCompact,
                  ),
                ),
                SizedBox(width: tileGap),
                Expanded(
                  child: _buildVolumeTile(totalReps, isCompact),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.stoneBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 9.5 : 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stoneMuted,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: isCompact ? 22 : 24,
                height: isCompact ? 22 : 24,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: isCompact ? 13 : 14, color: iconColor),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.obsidian,
              letterSpacing: -0.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: AppColors.stoneMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeTile(int totalReps, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.stoneBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'VOLUME',
                  style: TextStyle(
                    fontSize: isCompact ? 9.5 : 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stoneMuted,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: isCompact ? 22 : 24,
                height: isCompact ? 22 : 24,
                decoration: const BoxDecoration(
                  color: AppColors.accentMintTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 13,
                  color: AppColors.accentMintDark,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            totalReps > 0 ? '${totalReps.toLocaleString()} Reps' : '0 Reps',
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.obsidian,
              letterSpacing: -0.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalReps > 0 ? (totalReps / 500).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: AppColors.trackRing,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentMint),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                totalReps > 0 ? '${((totalReps / 500).clamp(0.0, 1.0) * 100).round()}%' : '0%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.stoneMuted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. CURRENT ROUTINE PAIRS SECTION ---
  Widget _buildRoutinePairsSection(BuildContext context, bool isCompact) {
    // Current ladders for selected pair
    late List<ProgressionLadder> pairLadders;
    late String pairBadgeLabel;

    switch (_selectedPairIndex) {
      case 0:
        pairLadders = [BwfRoutineData.pullupLadder, BwfRoutineData.squatLadder];
        pairBadgeLabel = "Today's First Pair (90s Rest)";
        break;
      case 1:
        pairLadders = [BwfRoutineData.dipLadder, BwfRoutineData.hingeLadder];
        pairBadgeLabel = "Today's Second Pair (90s Rest)";
        break;
      case 2:
        pairLadders = [BwfRoutineData.rowLadder, BwfRoutineData.pushupLadder];
        pairBadgeLabel = "Today's Third Pair (90s Rest)";
        break;
      case 4:
        pairLadders = [BwfRoutineData.handstandLadder, BwfRoutineData.lsitLadder];
        pairBadgeLabel = "Skill Day Routine (Handstand & L-sit)";
        break;
      default:
        pairLadders = [
          BwfRoutineData.antiExtensionLadder,
          BwfRoutineData.antiRotationLadder,
          BwfRoutineData.extensionLadder,
        ];
        pairBadgeLabel = "Core Triplet Circuit (60s Rest)";
    }

    final exercises = pairLadders
        .map((ladder) => widget.controller.getSelectedExerciseForLadder(ladder.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pairBadgeLabel,
              style: TextStyle(
                fontSize: isCompact ? 13 : 14,
                fontWeight: FontWeight.w800,
                color: AppColors.obsidian,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                if (widget.controller.activeSession == null) {
                  widget.controller.startWorkout();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutScreen(controller: widget.controller),
                  ),
                );
              },
              child: const Text(
                'Log Reps',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentMintDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 8 : 10),

        // Pairs Carousel / Selector Tabs
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.90, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPairTab('Pair 1', 0),
                const SizedBox(width: 8),
                _buildPairTab('Pair 2', 1),
                const SizedBox(width: 8),
                _buildPairTab('Pair 3', 2),
                const SizedBox(width: 8),
                _buildPairTab('Core Triplet', 3),
                const SizedBox(width: 8),
                _buildPairTab('Skill Work', 4),
              ],
            ),
          ),
        ),
        SizedBox(height: isCompact ? 10 : 12),

        // Clean White Card with Exercise Rows & Alternating Divider
        Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: AppColors.stoneBorder.withValues(alpha: 0.8)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < pairLadders.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Divider(height: 1, color: AppColors.stoneBorder),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.inset,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swap_vert_rounded,
                                size: 14,
                                color: AppColors.stoneMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                i == 1
                                    ? (pairLadders.length == 3 ? 'Rest 60s & Alternate' : pairBadgeLabel)
                                    : 'Rest 60s & Complete Triplet',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.obsidian,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildExerciseRow(
                  context: context,
                  ladder: pairLadders[i],
                  exercise: exercises[i],
                  repsText: '3×8',
                  boxBg: i == 0
                      ? AppColors.inset
                      : (i == 1 ? AppColors.stoneTint : AppColors.accentMintTint),
                  boxText: i == 0
                      ? AppColors.obsidian
                      : (i == 1 ? AppColors.stoneMuted : AppColors.accentMintDark),
                  isCompact: isCompact,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPairTab(String label, int index) {
    final bool isSelected = _selectedPairIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPairIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.obsidian : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.obsidian : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.obsidian,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRow({
    required BuildContext context,
    required ProgressionLadder ladder,
    required Exercise exercise,
    required String repsText,
    required Color boxBg,
    required Color boxText,
    required bool isCompact,
  }) {
    final double badgeSize = isCompact ? 40 : 44;
    final double chevronSize = isCompact ? 28 : 32;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Reps Badge Box
              Container(
                width: badgeSize,
                height: badgeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: boxBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  repsText,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w900,
                    color: boxText,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ladder.title,
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.obsidian,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Level ${exercise.level} · ${exercise.name}',
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.stoneMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (exercise.pathName != 'Recommended Path' && exercise.pathName != 'Recommended Progression') ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.stoneTint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.pathName,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.obsidian,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Arrow Action Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
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
          child: Container(
            width: chevronSize,
            height: chevronSize,
            decoration: const BoxDecoration(
              color: AppColors.stoneTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: isCompact ? 16 : 18,
              color: AppColors.obsidian,
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. DOCKED FULL-WIDTH SOLID BOTTOM NAVIGATION BAR (NO BLUR) ---
  Widget _buildDockedBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(
            color: AppColors.stoneBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tab 0: Home
                  _buildNavButton(
                    index: 0,
                    label: 'Home',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                  ),

                  // Tab 1: Progressions
                  _buildNavButton(
                    index: 1,
                    label: 'Progressions',
                    icon: Icons.alt_route_rounded,
                    activeIcon: Icons.alt_route_rounded,
                  ),

                  // Tab 2: History
                  _buildNavButton(
                    index: 2,
                    label: 'History',
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = _currentNavIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        if (_currentNavIndex == index) {
          if (index == 0) {
            _scrollToTop();
          } else if (index == 1) {
            _progressionLadderKey.currentState?.scrollToTop();
          } else if (index == 2) {
            _historyKey.currentState?.scrollToTop();
          }
        } else {
          setState(() => _currentNavIndex = index);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.obsidian : AppColors.mutedGray,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.obsidian : AppColors.mutedGray,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
