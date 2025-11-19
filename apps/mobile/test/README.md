# HistoriCam Mobile App Tests

This directory contains comprehensive tests for the HistoriCam mobile application.

## Quick Start

### Format Code Before Testing
```bash
# On macOS/Linux
cd apps/mobile
./format.sh

# On Windows
cd apps\mobile
format.bat

# Or directly with dart
dart format .
```

### Run Tests
```bash
flutter test
```

## Test Structure

```
test/
├── README.md                          # This file
├── widget_test.dart                   # Basic smoke tests
├── app_test.dart                      # Main app integration tests
├── config/
│   └── api_config_test.dart          # API configuration tests
├── services/
│   └── vision_api_service_test.dart  # Vision API service tests
├── screens/
│   ├── camera_screen_test.dart       # Camera screen widget tests
│   └── result_screen_test.dart       # Result screen widget tests
└── widgets/
    └── chatbot_widget_test.dart      # Chatbot widget tests
```

## Test Coverage

### Unit Tests

**ApiConfig Tests** (`config/api_config_test.dart`)
- URL configuration validation
- Endpoint generation
- URL format validation

**VisionApiService Tests** (`services/vision_api_service_test.dart`)
- API response parsing
- Building name formatting
- Building description retrieval
- Error handling

### Widget Tests

**ChatbotWidget Tests** (`widgets/chatbot_widget_test.dart`)
- UI element rendering
- Message sending functionality
- User/bot message differentiation
- Empty message handling
- Multiple message support
- Typing indicator animation

**CameraScreen Tests** (`screens/camera_screen_test.dart`)
- Header display
- Camera initialization states
- Capture button rendering
- Instruction overlay
- Proper styling and theming

**ResultScreen Tests** (`screens/result_screen_test.dart`)
- Header with back navigation
- Loading state display
- Error handling
- Tour suggestions button
- Chatbot integration
- Content scrolling

### Integration Tests

**App Tests** (`app_test.dart`)
- App launch and initialization
- Theme configuration
- Navigation flow
- State management
- Color scheme consistency

## Running Tests

### Run all tests
```bash
flutter test
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Run specific test file
```bash
flutter test test/app_test.dart
```

### Run tests in a specific directory
```bash
flutter test test/widgets/
```

### Run tests with verbose output
```bash
flutter test --verbose
```

## Test Dependencies

The following packages are used for testing:

- `flutter_test` - Flutter's testing framework (included with SDK)
- `mockito` - Mocking library for unit tests
- `build_runner` - Code generation for mockito

## Generating Mocks

If you add new services that need to be mocked:

```bash
flutter pub run build_runner build
```

This will generate `.mocks.dart` files based on the `@GenerateMocks` annotations in test files.

## Writing New Tests

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/my_service.dart';

void main() {
  group('MyService', () {
    late MyService service;

    setUp(() {
      service = MyService();
    });

    test('should do something', () {
      final result = service.doSomething();
      expect(result, expectedValue);
    });
  });
}
```

### Widget Test Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/widgets/my_widget.dart';

void main() {
  testWidgets('MyWidget should display text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MyWidget(),
        ),
      ),
    );

    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

## Test Best Practices

1. **Organize tests** - Mirror the lib/ directory structure in test/
2. **Use descriptive names** - Test names should clearly describe what they test
3. **Group related tests** - Use `group()` to organize related test cases
4. **Setup and teardown** - Use `setUp()` and `tearDown()` for common initialization
5. **Test one thing** - Each test should verify a single behavior
6. **Mock external dependencies** - Use mockito to isolate units under test
7. **Avoid flaky tests** - Use `pumpAndSettle()` for animations and async operations
8. **Test edge cases** - Include tests for error conditions and boundary values

## Known Limitations

1. **Camera Testing** - Full camera functionality requires device-specific features that are difficult to test in unit tests. Camera tests focus on UI and state management.

2. **API Testing** - Vision API tests use mocked responses. Integration with the actual API should be tested manually or in end-to-end tests.

3. **Permissions** - Permission handling is tested at the UI level. Actual permission dialogs require integration testing on physical devices or emulators.

4. **Image Processing** - Tests use dummy image paths. Actual image processing should be verified through manual testing.

## Continuous Integration

These tests are designed to run in CI/CD pipelines. Ensure your CI configuration includes:

```yaml
- flutter pub get
- flutter test --coverage
- flutter analyze
```

## Coverage Reports

After running tests with coverage:

1. Generate HTML report:
```bash
genhtml coverage/lcov.info -o coverage/html
```

2. View the report:
```bash
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
xdg-open coverage/html/index.html # Linux
```

## Contributing

When adding new features:

1. Write tests first (TDD approach recommended)
2. Ensure all tests pass before submitting PR
3. Maintain or improve code coverage
4. Update this README if adding new test categories

## Troubleshooting

### Tests fail with "Camera not initialized"
- Ensure you set `cameras = [];` in `setUp()` or at the start of the test

### Mock generation fails
- Run `flutter pub run build_runner clean`
- Then run `flutter pub run build_runner build --delete-conflicting-outputs`

### Tests timeout
- Increase timeout: `testWidgets('...', timeout: Timeout(Duration(seconds: 30)), ...)`
- Check for missing `await` on async operations
- Ensure you call `pumpAndSettle()` after navigation or animations

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)
