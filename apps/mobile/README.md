# HistoriCam Mobile App

Your Personal Tour Guide - A Flutter mobile application that uses camera and AI to identify historic buildings and provide detailed information about them.

### Create Build
```
flutter create . --platforms web
flutter run
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
│   ├── config                    # API urls
│   ├── screens/
│   │   ├── camera_screen.dart    # Camera capture screen
│   │   └── result_screen.dart    # Building info display screen
│   ├── widgets/
│   │   └── chatbot_widget.dart   # Chatbot interface widget
│   └── services/                 # Future API services
├── web/                          # Web app files
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


### Building for Release

```bash
flutter build web --release
```

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

## Testing

Run tests:
```bash
flutter test
```

Check code quality:
```bash
flutter analyze
```
