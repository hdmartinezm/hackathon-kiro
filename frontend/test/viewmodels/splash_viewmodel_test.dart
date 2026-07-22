import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/viewmodels/splash_viewmodel.dart';

void main() {
  group('SplashViewModel', () {
    late SplashViewModel viewModel;

    setUp(() {
      viewModel = SplashViewModel();
    });

    group('initial state', () {
      test('disclaimerAccepted is false by default', () {
        expect(viewModel.state.disclaimerAccepted, isFalse);
      });
    });

    group('acceptDisclaimer', () {
      test('sets disclaimerAccepted to true', () {
        viewModel.acceptDisclaimer();

        expect(viewModel.state.disclaimerAccepted, isTrue);
      });

      test('notifies listeners', () {
        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        viewModel.acceptDisclaimer();

        expect(listenerCallCount, equals(1));
      });

      test('is idempotent — calling twice keeps true', () {
        viewModel.acceptDisclaimer();
        viewModel.acceptDisclaimer();

        expect(viewModel.state.disclaimerAccepted, isTrue);
      });
    });
  });
}
