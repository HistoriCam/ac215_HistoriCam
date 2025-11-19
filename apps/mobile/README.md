# HistoriCam Mobile App

Your Personal Tour Guide - A Flutter mobile application that uses camera and AI to identify historic buildings and provide detailed information about them.

###
```
flutter create . --platforms web
```
## Features

- **Camera Integration**: Access phone camera to capture photos of historic buildings
- **Image Recognition**: Ready for Vision API integration to identify landmarks
- **Building Information**: Display detailed descriptions and historical context
- **Interactive Chatbot**: Ask questions about the buildings (API integration ready)
- **Tour Suggestions**: Get recommendations for nearby historic sites

## Project Structure

```
apps/mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/
│   │   ├── camera_screen.dart    # Camera capture screen
│   │   └── result_screen.dart    # Building info display screen
│   ├── widgets/
│   │   └── chatbot_widget.dart   # Chatbot interface widget
│   └── services/                 # Future API services
├── android/                       # Android-specific configuration
├── ios/                          # iOS-specific configuration
└── pubspec.yaml                  # Dependencies
```

## Setup Instructions

### Prerequisites

1. Install Flutter SDK (3.0.0 or higher)
   - Follow instructions at: https://flutter.dev/docs/get-started/install

2. Install an IDE:
   - VS Code with Flutter extension, or
   - Android Studio with Flutter plugin

3. Set up mobile device or emulator:
   - **Android**: Android Studio emulator or physical device with USB debugging
   - **iOS**: Xcode simulator or physical device (macOS only)

### Installation

1. Navigate to the mobile app directory:
   ```bash
   cd apps/mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Check Flutter setup:
   ```bash
   flutter doctor
   ```
   Resolve any issues shown by the doctor command.

### Running the App

#### On Android

1. Start an Android emulator or connect a physical device

2. Run the app:
   ```bash
   flutter run
   ```

#### On iOS (macOS only)

1. Open iOS simulator or connect a physical device

2. Install CocoaPods dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

#### Android APK
```bash
flutter build apk --release
```

#### iOS (requires Apple Developer account)
```bash
flutter build ios --release
```

## Permissions

The app requires the following permissions:

- **Camera**: To capture photos of historic buildings
- **Storage**: To temporarily store captured images
- **Internet**: For future API calls to Vision AI and database services

Permissions are configured in:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

## Dependencies

Key packages used:
- `camera`: Camera functionality
- `image_picker`: Image selection
- `permission_handler`: Runtime permissions
- `http`: HTTP requests for API calls
- `provider`: State management

See [pubspec.yaml](pubspec.yaml) for complete list.

## Future Integrations

The app is structured to easily integrate the following APIs:

### 1. Vision API Integration
Location: Create `lib/services/vision_service.dart`

```dart
Future<String> identifyBuilding(String imagePath) async {
  // Send image to Vision API
  // Return building label/name
}
```

### 2. Database API Integration
Location: Create `lib/services/database_service.dart`

```dart
Future<BuildingInfo> getBuildingInfo(String buildingLabel) async {
  // Query database API with building label
  // Return building information
}
```

### 3. Chatbot API Integration
Location: Update `lib/widgets/chatbot_widget.dart`

```dart
Future<String> sendMessage(String message, String buildingContext) async {
  // Send message to chatbot API with context
  // Return chatbot response
}
```

## UI Design

The app follows the HistoriCam brand design:
- **Primary Color**: Red (#E63946)
- **Background**: Dark gray (#2B2B2B) and cream (#F5EFE6)
- **Font**: Roboto

## Development Workflow

1. **Camera Screen** ([lib/screens/camera_screen.dart](lib/screens/camera_screen.dart:1))
   - Initialize camera
   - Capture photo
   - Navigate to result screen

2. **Result Screen** ([lib/screens/result_screen.dart](lib/screens/result_screen.dart:1))
   - Display captured image
   - Show building information
   - Integrate chatbot widget

3. **Chatbot Widget** ([lib/widgets/chatbot_widget.dart](lib/widgets/chatbot_widget.dart:1))
   - Handle user messages
   - Display conversation
   - Connect to chatbot API

## Troubleshooting

### Camera not working
- Check that permissions are granted in device settings
- Verify camera permissions in AndroidManifest.xml / Info.plist
- Ensure device has a working camera

### Build errors
- Run `flutter clean` then `flutter pub get`
- Check Flutter version: `flutter --version`
- Update dependencies: `flutter pub upgrade`

### iOS build issues
- Run `pod repo update` in the ios directory
- Clean Xcode build: `cd ios && xcodebuild clean`

## Testing

Run tests:
```bash
flutter test
```

Check code quality:
```bash
flutter analyze
```

## Contributing

When adding new features:
1. Follow Flutter best practices
2. Maintain consistent UI design
3. Add comments for API integration points
4. Test on both Android and iOS

## License

[Your License Here]
