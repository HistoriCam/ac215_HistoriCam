@echo off
REM Format all Dart files in the mobile app
REM Run this before committing to ensure code is properly formatted

echo Formatting Dart code...
call dart format .

echo.
echo ✅ Formatting complete!
echo.
echo Run 'flutter analyze' to check for any issues.
