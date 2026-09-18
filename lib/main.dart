import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'controllers/workout_controller.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set friendly error widget for unhandled widget exceptions
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.accentRed),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode ? details.exceptionAsString() : 'Please restart the application.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  };

  final storageService = await StorageService.init();
  final workoutController = WorkoutController(storageService);

  runApp(BwfWorkoutApp(controller: workoutController));
}

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class BwfWorkoutApp extends StatelessWidget {
  final WorkoutController controller;

  const BwfWorkoutApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BWF Recommended Routine',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.theme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: mediaQueryData.textScaler.clamp(
              maxScaleFactor: 1.1,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return controller.storage.isOnboardingCompleted()
              ? HomeScreen(controller: controller)
              : ProfileSetupScreen(controller: controller);
        },
      ),
    );
  }
}
