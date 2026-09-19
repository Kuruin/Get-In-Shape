import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_1/data/bwf_routine_data.dart';
import 'package:workout_app_1/models/user_profile.dart';
import 'package:workout_app_1/models/workout_session.dart';
import 'package:workout_app_1/services/storage_service.dart';
import 'package:workout_app_1/controllers/workout_controller.dart';
import 'package:workout_app_1/screens/active_workout_screen.dart';
import 'package:workout_app_1/screens/progression_ladder_screen.dart';
import 'package:workout_app_1/screens/history_screen.dart';
import 'package:workout_app_1/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper to dismiss version changelog modal if it appears on first home mount
  Future<void> dismissChangelogIfNeeded(WidgetTester tester) async {
    if (find.text("Got it, Let's Train").evaluate().isNotEmpty) {
      await tester.tap(find.text("Got it, Let's Train"));
      await tester.pumpAndSettle();
    }
  }

  group('BWF Routine Database Tests', () {
    test('Verifies all 9 BWF RR ladders exist and have exercises', () {
      expect(BwfRoutineData.allLadders.length, 9);
      for (final ladder in BwfRoutineData.allLadders) {
        expect(ladder.exercises.isNotEmpty, isTrue);
        expect(ladder.defaultRestSeconds, greaterThanOrEqualTo(60));
      }
    });

    test('Verifies all warm-up exercises exist with instructions', () {
      expect(BwfRoutineData.warmups.length, 5);
      for (final warmup in BwfRoutineData.warmups) {
        expect(warmup.name.isNotEmpty, isTrue);
        expect(warmup.cues.isNotEmpty, isTrue);
      }
    });
  });

  group('Workout Controller & Local Persistence Tests', () {
    late StorageService storage;
    late WorkoutController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      controller = WorkoutController(storage);
    });

    test('Starts workout session with warmups and pairs initialized', () {
      expect(controller.activeSession, isNull);
      controller.startWorkout();
      expect(controller.activeSession, isNotNull);
      expect(controller.currentStage, WorkoutStage.warmup);

      // Verify sets initialized for all 9 ladders (3 sets each = 27 total sets) with default 0 reps
      expect(controller.activeSession!.sets.length, 27);
      expect(controller.activeSession!.sets.every((s) => s.reps == 0), isTrue);
    });

    test('Toggles warmups and completes sets with rest timer', () {
      controller.startWorkout();
      final warmupId = BwfRoutineData.warmups.first.id;
      controller.toggleWarmup(warmupId);
      expect(
        controller.activeSession!.completedWarmups.contains(warmupId),
        isTrue,
      );

      controller.advanceStage();
      expect(controller.currentStage, WorkoutStage.firstPair);

      // Log set for Pull-up
      final pullupLadder = BwfRoutineData.pullupLadder;
      controller.updateSetReps(pullupLadder.id, 0, 8);
      controller.completeSetAndTriggerRest(
        ladderId: pullupLadder.id,
        setIndex: 0,
        restSeconds: 90,
      );

      final set0 = controller.getSet(pullupLadder.id, 0);
      expect(set0!.isCompleted, isTrue);
      expect(set0.reps, 8);
      expect(controller.isTimerRunning, isTrue);
      expect(controller.restRemainingSeconds, 90);
    });

    test('Can switch progression levels', () async {
      final pullup = BwfRoutineData.pullupLadder;
      final current = controller.getSelectedExerciseForLadder(pullup.id);
      expect(current.level, 1);

      await controller.setProgression(pullup.id, 'pullup_4');
      final updated = controller.getSelectedExerciseForLadder(pullup.id);
      expect(updated.id, 'pullup_4');
      expect(updated.name, 'Full Pull-ups');
    });

    test('Saves custom user profile and marks onboarding completed', () async {
      expect(controller.isOnboardingCompleted(), isFalse);
      expect(controller.userProfile, isNull);

      final profile = UserProfile(
        name: 'Alex Calisthenics',
        isGuest: false,
        fitnessGoal: 'Master Pull-ups & Dips',
        createdAt: DateTime.now(),
      );

      await controller.saveProfile(profile);

      expect(controller.isOnboardingCompleted(), isTrue);
      expect(controller.userProfile?.name, 'Alex Calisthenics');
      expect(controller.userProfile?.isGuest, isFalse);
      expect(controller.userProfile?.fitnessGoal, 'Master Pull-ups & Dips');
    });

    test('Saves guest profile and marks onboarding completed', () async {
      expect(controller.isOnboardingCompleted(), isFalse);

      await controller.saveGuestProfile();

      expect(controller.isOnboardingCompleted(), isTrue);
      expect(controller.userProfile?.name, 'Guest Athlete');
      expect(controller.userProfile?.isGuest, isTrue);
    });

    test(
      'Reset all data wipes profile, sessions, and onboarding status',
      () async {
        await controller.saveGuestProfile();
        controller.startWorkout();
        expect(controller.isOnboardingCompleted(), isTrue);
        expect(controller.activeSession, isNotNull);

        await controller.resetAllData();

        expect(controller.isOnboardingCompleted(), isFalse);
        expect(controller.userProfile, isNull);
        expect(controller.activeSession, isNull);
        expect(controller.history, isEmpty);
      },
    );
  });

  group('Onboarding & App Entry Tests', () {
    testWidgets(
      'Fresh install displays ProfileSetupScreen with guest and custom options',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        final controller = WorkoutController(storage);

        await tester.pumpWidget(BwfWorkoutApp(controller: controller));
        await tester.pumpAndSettle();

        // Should render ProfileSetupScreen
        expect(find.text('Welcome to BWF Routine'), findsOneWidget);
        expect(find.text('Save Profile & Start Training'), findsOneWidget);
        expect(find.text('Continue as Guest'), findsOneWidget);
        expect(find.textContaining('100% Private'), findsOneWidget);
      },
    );

    testWidgets('Onboarding: continue as guest transitions to HomeScreen', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final controller = WorkoutController(storage);

      await tester.pumpWidget(BwfWorkoutApp(controller: controller));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue as Guest'));
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();
      await dismissChangelogIfNeeded(tester);

      // Now on HomeScreen
      expect(find.text('Recommended\nRoutine'), findsOneWidget);
      expect(find.text('Hello, Guest Athlete'), findsOneWidget);
      expect(find.text('Start Workout'), findsOneWidget);
    });

    testWidgets(
      'Onboarding: save custom profile transitions to HomeScreen with custom name',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final storage = await StorageService.init();
        final controller = WorkoutController(storage);

        await tester.pumpWidget(BwfWorkoutApp(controller: controller));
        await tester.pumpAndSettle();

        // Enter custom name
        await tester.enterText(find.byType(TextField), 'Marcus');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Save Profile & Start Training'));
        await tester.tap(find.text('Save Profile & Start Training'));
        await tester.pumpAndSettle();
        await dismissChangelogIfNeeded(tester);

        // Now on HomeScreen with Marcus
        expect(find.text('Recommended\nRoutine'), findsOneWidget);
        expect(find.text('Hello, Marcus'), findsOneWidget);
        expect(find.text('0 Days'), findsOneWidget);
        expect(find.text('STREAK'), findsOneWidget);
      },
    );
  });

  group('HomeScreen & Profile Sheet Tests', () {
    testWidgets(
      'HomeScreen profile sheet shows profile info and reset action',
      (WidgetTester tester) async {
        final testProfile = UserProfile(
          name: 'Manav',
          isGuest: false,
          fitnessGoal: 'Full Body Routine Progression',
          createdAt: DateTime.now(),
        );

        SharedPreferences.setMockInitialValues({
          'bwf_onboarding_completed': true,
          'bwf_last_seen_version': '1.0.0',
          'bwf_user_profile': jsonEncode(testProfile.toJson()),
        });
        final storage = await StorageService.init();
        final controller = WorkoutController(storage);

        await tester.pumpWidget(BwfWorkoutApp(controller: controller));
        await tester.pumpAndSettle();
        await dismissChangelogIfNeeded(tester);

        expect(find.text('Hello, Manav'), findsOneWidget);

        // Tap profile avatar container
        final avatarFinder = find.byIcon(Icons.person_rounded);
        expect(avatarFinder, findsOneWidget);
        await tester.tap(avatarFinder);
        await tester.pumpAndSettle();

        // Profile modal sheet should be open
        expect(find.text('Athlete Profile'), findsAtLeast(1));
        expect(find.text('Full Body Routine Progression'), findsOneWidget);
        expect(find.text('Manav'), findsOneWidget);
        expect(find.text('Reset All Stats & Data'), findsOneWidget);
        expect(find.textContaining('100% Private'), findsOneWidget);

        // Tap Reset All Stats & Data
        await tester.tap(find.text('Reset All Stats & Data'));
        await tester.pumpAndSettle();

        // Dialog confirmation
        expect(find.text('Reset All Data?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Reset Everything'), findsOneWidget);

        // Confirm reset
        await tester.tap(find.text('Reset Everything'));
        await tester.pumpAndSettle();

        // App should return to ProfileSetupScreen
        expect(find.text('Welcome to BWF Routine'), findsOneWidget);
        expect(find.text('Continue as Guest'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'ActiveWorkoutScreen renders workout components, default 0 reps, and pair switcher',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'bwf_onboarding_completed': true,
        'bwf_last_seen_version': '1.0.0',
      });
      final storage = await StorageService.init();
      final controller = WorkoutController(storage);

      controller.startWorkout();
      controller.advanceStage(); // Advance to first pair

      await tester.pumpWidget(
        MaterialApp(home: ActiveWorkoutScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Workout'), findsOneWidget);
      expect(find.text('FIRST PAIR • 1 OF 3'), findsOneWidget);
      expect(find.text('SET 1 OF 3'), findsOneWidget);
      expect(find.text('TARGET REST'), findsOneWidget);
      expect(find.text('COMPLETED WORK'), findsOneWidget);
      expect(find.text('TECHNIQUE FOCUS'), findsOneWidget);
      expect(find.text('ANTAGONIST SUPER-SET'), findsOneWidget);

      // Verify Stage/Pair Switcher pills exist
      expect(find.text('Warm-up'), findsOneWidget);
      expect(find.text('Pair 1'), findsOneWidget);
      expect(find.text('Pair 2'), findsOneWidget);
      expect(find.text('Pair 3'), findsOneWidget);
      expect(find.text('Core'), findsOneWidget);

      // Default reps is 0, button shows Log 0 Reps & Start Rest
      final logButton = find.text('Log 0 Reps & Start Rest');
      expect(logButton, findsOneWidget);

      // Scroll to button and tap to log the set and trigger rest
      await tester.ensureVisible(logButton);
      await tester.pumpAndSettle();
      await tester.tap(logButton);
      await tester.pump(const Duration(milliseconds: 100));

      // After logging, timer is running and button adjusts
      expect(controller.isTimerRunning, isTrue);
      expect(find.textContaining('Resting ('), findsOneWidget);
      expect(find.textContaining('Skip Rest & Begin Set'), findsOneWidget);

      // Stop timer before testing pair switcher to clean up pending timers
      controller.stopRestTimer();
      await tester.pump(const Duration(milliseconds: 50));

      // Switch between pairs: tap Pair 2 in the stage switcher
      await tester.tap(find.text('Pair 2'));
      await tester.pumpAndSettle();
      expect(controller.currentStage, WorkoutStage.secondPair);
      expect(find.text('SECOND PAIR • 2 OF 3'), findsOneWidget);

      await controller.discardWorkout();
    },
  );

  testWidgets(
    'ProgressionLadderScreen renders roadmap, bento cluster, chips, and milestone deck',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'bwf_onboarding_completed': true,
        'bwf_last_seen_version': '1.0.0',
      });
      final storage = await StorageService.init();
      final controller = WorkoutController(storage);

      await tester.pumpWidget(
        MaterialApp(home: ProgressionLadderScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Roadmap'), findsOneWidget);
      expect(find.text('RECOMMENDED ROUTINE'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('PRIMARY PAIRS'), findsOneWidget);
      expect(find.text('TARGET UNLOCK'), findsOneWidget);
      expect(find.textContaining('Pull-up'), findsAtLeast(1));
    },
  );

  group('HistoryScreen Tests', () {
    testWidgets(
      'HistoryScreen renders clean 0 baseline stats when no workouts logged',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'bwf_onboarding_completed': true,
          'bwf_last_seen_version': '1.0.0',
        });
        final storage = await StorageService.init();
        final controller = WorkoutController(storage);

        await tester.pumpWidget(
          MaterialApp(home: HistoryScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Verify Header
        expect(find.text('History'), findsOneWidget);

        // Verify Weekly Consistency Bar starts at 0
        expect(find.text('WEEKLY CONSISTENCY'), findsOneWidget);
        expect(find.text('0 Week Streak'), findsOneWidget);

        // Verify Monthly Heatmap Card starts at 0
        expect(find.text('MONTHLY HEATMAP'), findsOneWidget);
        expect(find.textContaining('0 / '), findsOneWidget);
        expect(
          find.textContaining('Month Load: 0 Strict Reps'),
          findsOneWidget,
        );

        // Verify Strict Reps Load Card starts at 0
        expect(find.text('STRICT REPS LOAD'), findsOneWidget);
        expect(find.text('0 reps'), findsOneWidget);
        expect(find.text('BASELINE'), findsOneWidget);

        // Verify Peak PR shows Baseline state
        expect(find.text('ESTABLISH YOUR BASELINE'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);

        // Verify Timeline empty state
        expect(find.text('Recent Logs'), findsOneWidget);
        expect(find.text('No Workouts Logged Yet'), findsOneWidget);

        // Verify Reddit Markdown Export Banner exists and tapping copy shows friendly snackbar
        expect(find.text('Reddit Markdown Export'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);

        await tester.ensureVisible(find.text('Copy'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'No workouts logged yet. Complete a workout first to export your log!',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'HistoryScreen renders populated session when workouts are logged',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final sampleSession = WorkoutSession(
          id: 'session_1',
          startTime: DateTime.now(),
          durationSeconds: 45 * 60,
          notes: 'Great calisthenics workout!',
          sets: [
            LoggedSet(
              exerciseId: 'pullup_1',
              exerciseName: 'Scapular Pulls',
              ladderId: 'pullup',
              setIndex: 0,
              reps: 8,
              isCompleted: true,
            ),
            LoggedSet(
              exerciseId: 'pullup_1',
              exerciseName: 'Scapular Pulls',
              ladderId: 'pullup',
              setIndex: 1,
              reps: 8,
              isCompleted: true,
            ),
            LoggedSet(
              exerciseId: 'pullup_1',
              exerciseName: 'Scapular Pulls',
              ladderId: 'pullup',
              setIndex: 2,
              reps: 8,
              isCompleted: true,
            ),
          ],
        );

        SharedPreferences.setMockInitialValues({
          'bwf_onboarding_completed': true,
          'bwf_last_seen_version': '1.0.0',
          'bwf_workout_history': jsonEncode([sampleSession.toJson()]),
        });
        final storage = await StorageService.init();
        final controller = WorkoutController(storage);

        await tester.pumpWidget(
          MaterialApp(home: HistoryScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Strict reps load should reflect 24 reps
        expect(find.text('24 reps'), findsOneWidget);

        // Verify Recent Logs header
        expect(find.text('Recent Logs'), findsOneWidget);

        // Tap timeline accordion to expand details
        final prDayFinder = find.text('PR Day').last;
        expect(prDayFinder, findsOneWidget);
        await tester.tap(prDayFinder);
        await tester.pumpAndSettle();

        // Timeline should display the expanded session details
        expect(find.text('BWF Recommended Routine'), findsOneWidget);
        expect(find.text('View Full Log'), findsOneWidget);

        // Reddit export should copy markdown
        await tester.ensureVisible(find.text('Copy'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Copy'));
        await tester.pump();
        expect(find.text('Copied!'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      },
    );
  });
}
