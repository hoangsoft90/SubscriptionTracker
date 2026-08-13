import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local onboarding step state (persistence lives in SettingsController).
class OnboardingState {
  const OnboardingState({required this.step});

  final int step;

  OnboardingState next() => OnboardingState(step: step + 1);
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState(step: 0);

  void next() => state = state.next();
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
