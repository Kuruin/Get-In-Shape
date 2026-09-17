import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_1/data/bwf_routine_data.dart';
import 'package:workout_app_1/services/storage_service.dart';
import 'package:workout_app_1/controllers/workout_controller.dart';
import 'package:workout_app_1/screens/active_workout_screen.dart';
import 'package:workout_app_1/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Workout Controller & Persistence Tests', () {
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
      expect(controller.activeSession!.completedWarmups.contains(warmupId), isTrue);

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
  });

  testWidgets('BwfWorkoutApp loads HomeScreen cleanly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = WorkoutController(storage);

    await tester.pumpWidget(BwfWorkoutApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Recommended\nRoutine'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('ActiveWorkoutScreen renders workout components, default 0 reps, and pair switcher',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = WorkoutController(storage);

    controller.startWorkout();
    controller.advanceStage(); // Advance to first pair

    await tester.pumpWidget(MaterialApp(
      home: ActiveWorkoutScreen(controller: controller),
    ));
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
  });
}
