#!/bin/bash
# Format all Dart files in the mobile app
# Run this before committing to ensure code is properly formatted

echo "Formatting Dart code..."
dart format .

echo "✅ Formatting complete!"
echo ""
echo "Run 'flutter analyze' to check for any issues."
