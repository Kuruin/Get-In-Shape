import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../controllers/workout_controller.dart';

class ProfileSetupScreen extends StatefulWidget {
  final WorkoutController controller;

  const ProfileSetupScreen({super.key, required this.controller});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final List<String> _goals = const [
    'Build Strength & Master Calisthenics',
    'Master Pull-ups & Dips',
    'Full Body Routine Progression',
    'Improve Core, Flexibility & Mobility',
  ];

  late String _selectedGoal;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedGoal = _goals.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final trimmedName = _nameController.text.trim();
    final name = trimmedName.isNotEmpty ? trimmedName : 'Athlete';

    final profile = UserProfile(
      name: name,
      isGuest: false,
      fitnessGoal: _selectedGoal,
      createdAt: DateTime.now(),
    );

    await widget.controller.saveProfile(profile);
  }

  Future<void> _handleContinueAsGuest() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    await widget.controller.saveGuestProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Hero Icon / Badge
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.obsidian,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.accentMint,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title & Subtitle
                  Text(
                    'Welcome to BWF Routine',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.obsidian,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bodyweight Fitness Recommended Routine.\nTrack authentic paired progressions offline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.stoneMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.stoneBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR NAME OR ATHLETE CALLSIGN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.stoneMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.obsidian,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Manav, Alex, or Titan',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.stoneMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.stoneMuted,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.stoneTint,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.accentMint,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Goal Selection
                        Text(
                          'PRIMARY TRAINING GOAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.stoneMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._goals.map((goal) {
                          final isSelected = _selectedGoal == goal;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedGoal = goal);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentMintTint
                                    : AppColors.stoneTint,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accentMint
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.accentMintDark
                                        : AppColors.stoneMuted,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      goal,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.obsidian
                                            : AppColors.softCharcoal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Profile Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSaveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.obsidian,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Save Profile & Start Training',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Continue as Guest Button
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _handleContinueAsGuest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.obsidian,
                      side: BorderSide(color: AppColors.stoneBorder, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softCharcoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Privacy & Local Storage Callout Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emerald200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: AppColors.emerald700,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '100% Private · All stats stored locally on this device',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
