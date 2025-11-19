# Vision API Integration Guide

This guide explains how to connect the HistoriCam Flutter mobile app to the Vision API backend.

## Overview

The mobile app now includes full integration with the Vision API service for building identification. When a user captures a photo:

1. The camera captures the image ([camera_screen.dart](lib/screens/camera_screen.dart))
2. The image is sent to the Vision API ([vision_api_service.dart](lib/services/vision_api_service.dart))
3. The API identifies the building using ML embeddings
4. Results are displayed to the user ([result_screen.dart](lib/screens/result_screen.dart))

## Setup Instructions

### 1. Deploy the Vision API

First, deploy the vision service to Google Cloud Run:

```bash
cd services/vision
./deploy-cloud-run.sh
```

After deployment, copy the Cloud Run URL from the output. It will look like:
```
https://vision-service-xxxxx-uc.a.run.app
```

### 2. Configure the Mobile App

Open [lib/config/api_config.dart](lib/config/api_config.dart) and update the `visionApiUrl`:

```dart
class ApiConfig {
  static const String visionApiUrl = 'https://your-cloud-run-url-here';
}
```

**Important:**
- Do NOT include a trailing slash
- Use the full HTTPS URL from Cloud Run
- For local testing on Android emulator, use: `http://10.0.2.2:8080`
- For local testing on iOS simulator, use: `http://localhost:8080`

### 3. Run the Mobile App

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Architecture

### Files Created/Modified

#### New Files
- **[lib/services/vision_api_service.dart](lib/services/vision_api_service.dart)** - API service for communicating with Vision API
- **[lib/config/api_config.dart](lib/config/api_config.dart)** - Configuration for API endpoints

#### Modified Files
- **[lib/screens/result_screen.dart](lib/screens/result_screen.dart)** - Updated to call Vision API instead of using dummy data

### API Service (VisionApiService)

The `VisionApiService` class handles all communication with the Vision API:

#### Key Methods

**`identifyBuilding(String imagePath)`**
- Sends image to Vision API for identification
- Returns raw API response as Map
- Throws exceptions on failure

**`parseResponse(Map<String, dynamic> apiResponse)`**
- Parses API response into usable format
- Returns success/failure status with parsed data

**`getBuildingName(String buildingId)`**
- Converts building ID to human-readable name
- TODO: Implement proper building database lookup

**`getBuildingDescription(String buildingId)`**
- Gets building description text
- TODO: Implement proper building information fetching

### API Response Format

The Vision API returns responses in the following format:

#### Successful Identification (Confident)
```json
{
  "status": "confident",
  "building_id": "widener_library",
  "confidence": 0.87,
  "matches": [
    {"building_id": "widener_library", "similarity": 0.87},
    {"building_id": "widener_library", "similarity": 0.85}
  ]
}
```

#### Low Confidence Match (Uncertain)
```json
{
  "status": "uncertain",
  "building_id": "memorial_hall",
  "confidence": 0.52,
  "message": "Low confidence match - building might be nearby",
  "matches": [
    {"building_id": "memorial_hall", "similarity": 0.52}
  ]
}
```

#### No Match Found
```json
{
  "status": "no_match",
  "building_id": null,
  "confidence": 0.32,
  "message": "No similar buildings found in database"
}
```

## Error Handling

The app includes comprehensive error handling:

### 1. API Configuration Check
If the API URL is not configured, the app throws a clear error message directing users to update the config.

### 2. Network Failures
If the API is unreachable, the app falls back to dummy data (if available) and shows a warning message.

### 3. Building Not Found
If the API cannot identify the building, the app displays a helpful message suggesting the building may not be in the database.

### 4. Parse Errors
If the API response is malformed, the app catches the error and displays an error state.

## Testing

### Test with Local API

1. Start the Vision API locally:
```bash
cd services/vision
./docker-shell.sh
```

2. Update [lib/config/api_config.dart](lib/config/api_config.dart):
```dart
// Android emulator
static const String visionApiUrl = 'http://10.0.2.2:8080';

// iOS simulator
static const String visionApiUrl = 'http://localhost:8080';
```

3. Run the app and test with building photos

### Test API Directly

You can test the API directly using curl:

```bash
curl -X POST http://localhost:8080/identify \
  -F "image=@path/to/building.jpg"
```

## Next Steps / TODOs

### 1. Implement Building Database
Currently, `getBuildingName()` and `getBuildingDescription()` return placeholder text. You should:

- Create a building information database (Firebase, Cloud Firestore, etc.)
- Add an API endpoint to fetch building details
- Update the service to fetch real building information

### 2. Add Caching
Implement local caching for:
- Previously identified buildings
- Building information
- Recent API responses

### 3. Add Analytics
Track:
- Successful identifications
- Failed identifications
- API response times
- User engagement metrics

### 4. Improve Error Messages
Add more specific error messages for different failure scenarios.

### 5. Add Retry Logic
Implement automatic retry for transient network failures.

## Troubleshooting

### Issue: "Vision API URL not configured"
**Solution:** Update [lib/config/api_config.dart](lib/config/api_config.dart) with your Cloud Run URL.

### Issue: "Connection refused" or "Network error"
**Solutions:**
- Verify the API URL is correct
- Check that the Vision API is running
- For local testing, use correct emulator/simulator URL
- Check firewall settings

### Issue: "Building Not Found" for known buildings
**Solutions:**
- Verify the embeddings database is loaded correctly
- Check that the image quality is sufficient
- Ensure the building is in the training dataset
- Try adjusting confidence thresholds in Vision API config

### Issue: App shows dummy data instead of API results
**Solution:** Check app logs for API errors. The app falls back to dummy data when the API fails.

## API Endpoints

### POST /identify
Identifies a building from an uploaded image.

**Request:**
- Method: POST
- Content-Type: multipart/form-data
- Body: image file

**Response:**
- Content-Type: application/json
- Body: Building identification result (see format above)

### GET /
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "service": "HistoriCam API",
  "version": "1.0.0"
}
```

## Performance Considerations

- Images are automatically resized before sending to reduce bandwidth
- API responses typically take 1-3 seconds
- Consider implementing request timeouts (currently none set)
- Add loading indicators for better UX

## Security Notes

- The API URL is hardcoded in the app (visible to users)
- For production, consider:
  - Adding API authentication (API keys, OAuth)
  - Rate limiting on the backend
  - Input validation and sanitization
  - HTTPS only for production endpoints
