#!/usr/bin/env python3
"""
Test script for Vision API - Building Identification Service

Usage:
    Local testing:  uv run python test_api.py
    With custom URL: uv run python test_api.py --url http://localhost:8000
    GitHub Actions:  python test_api.py --url $API_URL

This script tests:
- Health check endpoint
- Building identification with test images
- Response format validation
- Similarity score ranges
"""
import argparse
import sys
import time
from pathlib import Path
from typing import Dict, List
import requests


class VisionAPITester:
    """Test the Vision API service"""

    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url.rstrip("/")
        self.tests_passed = 0
        self.tests_failed = 0

    def log(self, message: str, level: str = "INFO"):
        """Simple logging"""
        prefix = {
            "INFO": "ℹ️ ",
            "SUCCESS": "✅",
            "ERROR": "❌",
            "WARNING": "⚠️ "
        }.get(level, "  ")
        print(f"{prefix} {message}")

    def test_health(self) -> bool:
        """Test health check endpoint"""
        self.log("Testing health endpoint...", "INFO")
        try:
            response = requests.get(f"{self.base_url}/")
            if response.status_code == 200:
                data = response.json()
                if data.get("status") == "healthy":
                    self.log("Health check passed", "SUCCESS")
                    return True
                else:
                    self.log(f"Unexpected health response: {data}", "ERROR")
                    return False
            else:
                self.log(f"Health check failed with status {response.status_code}", "ERROR")
                return False
        except Exception as e:
            self.log(f"Health check exception: {e}", "ERROR")
            return False

    def test_identify_endpoint_validation(self) -> bool:
        """Test that the identify endpoint validates input correctly"""
        self.log("Testing input validation...", "INFO")
        try:
            # Test with no file
            response = requests.post(f"{self.base_url}/identify")
            if response.status_code == 422:  # Unprocessable Entity
                self.log("Input validation works (rejects missing file)", "SUCCESS")
                return True
            else:
                self.log(f"Expected 422 for missing file, got {response.status_code}", "ERROR")
                return False
        except Exception as e:
            self.log(f"Validation test exception: {e}", "ERROR")
            return False

    def test_identify_with_image(self, image_path: Path, expected_building_id: str = None) -> Dict:
        """Test building identification with an actual image"""
        self.log(f"Testing identification with: {image_path.name}", "INFO")

        if not image_path.exists():
            self.log(f"Image not found: {image_path}", "WARNING")
            return None

        try:
            with open(image_path, "rb") as f:
                files = {"image": (image_path.name, f, "image/jpeg")}
                response = requests.post(f"{self.base_url}/identify", files=files)

            if response.status_code != 200:
                self.log(f"Identification failed: HTTP {response.status_code}", "ERROR")
                self.log(f"Response: {response.text}", "ERROR")
                return None

            result = response.json()

            # Validate response structure
            required_fields = ["status", "building_id", "confidence"]
            missing = [f for f in required_fields if f not in result]
            if missing:
                self.log(f"Response missing fields: {missing}", "ERROR")
                return None

            # Log result
            status = result["status"]
            building_id = result.get("building_id")
            confidence = result.get("confidence", 0)

            self.log(f"Result: {status} | Building: {building_id} | Confidence: {confidence:.3f}", "INFO")

            # Check expected building if provided
            if expected_building_id and status in ["confident", "uncertain"]:
                if str(building_id) == str(expected_building_id):
                    self.log(f"Correct building identified!", "SUCCESS")
                else:
                    self.log(f"Expected {expected_building_id}, got {building_id}", "WARNING")

            # Validate confidence ranges
            if status == "confident" and confidence < 0.7:
                self.log(f"Confident status but low confidence: {confidence}", "WARNING")
            if status == "no_match" and building_id is not None:
                self.log("No match status but building_id is set", "WARNING")

            return result

        except Exception as e:
            self.log(f"Identification test exception: {e}", "ERROR")
            return None

    def run_all_tests(self, test_images: List[Dict] = None) -> bool:
        """Run all tests"""
        print("\n" + "="*60)
        print("VISION API TEST SUITE")
        print("="*60 + "\n")
        print(f"Testing API at: {self.base_url}\n")

        results = []

        # Test 1: Health check
        results.append(("Health Check", self.test_health()))

        # Test 2: Input validation
        results.append(("Input Validation", self.test_identify_endpoint_validation()))

        # Test 3: Image identification (if test images provided)
        if test_images:
            for test_case in test_images:
                image_path = test_case["path"]
                expected_id = test_case.get("expected_building_id")
                result = self.test_identify_with_image(image_path, expected_id)
                results.append((f"Identify: {image_path.name}", result is not None))
        else:
            self.log("No test images provided - skipping image tests", "WARNING")

        # Summary
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)

        for test_name, passed in results:
            status = "✅ PASS" if passed else "❌ FAIL"
            print(f"{status:10s} | {test_name}")

        total = len(results)
        passed = sum(1 for _, p in results if p)
        failed = total - passed

        print(f"\nTotal: {total} | Passed: {passed} | Failed: {failed}")

        if failed == 0:
            print("\n🎉 All tests passed!")
            return True
        else:
            print(f"\n❌ {failed} test(s) failed")
            return False


def discover_test_images(vision_dir: Path) -> List[Dict]:
    """Try to find test images in the test_images directory"""
    test_images_dir = vision_dir / "test_images"

    if not test_images_dir.exists():
        return []

    test_images = []
    for img in test_images_dir.glob("*"):
        if img.suffix.lower() in ['.jpg', '.jpeg', '.png']:
            # Try to parse building ID from filename (e.g., "building_5_test.jpg" -> "5")
            parts = img.stem.split('_')
            expected_id = None
            if len(parts) >= 2 and parts[0] == "building":
                try:
                    expected_id = parts[1]
                except ValueError:
                    pass

            test_images.append({
                "path": img,
                "expected_building_id": expected_id
            })

    return test_images


def main():
    parser = argparse.ArgumentParser(description="Test Vision API")
    parser.add_argument(
        "--url",
        default="http://localhost:8080",
        help="Base URL of the API (default: http://localhost:8080)"
    )
    parser.add_argument(
        "--image",
        type=Path,
        help="Path to a single test image"
    )
    parser.add_argument(
        "--expected-building",
        help="Expected building ID for the test image"
    )
    args = parser.parse_args()

    # Initialize tester
    tester = VisionAPITester(base_url=args.url)

    # Prepare test images
    test_images = []

    if args.image:
        # Single image from command line
        test_images.append({
            "path": args.image,
            "expected_building_id": args.expected_building
        })
    else:
        # Try to discover test images
        vision_dir = Path(__file__).parent
        test_images = discover_test_images(vision_dir)
        if test_images:
            tester.log(f"Found {len(test_images)} test images", "INFO")

    # Wait a moment for API to be ready
    time.sleep(1)

    # Run tests
    success = tester.run_all_tests(test_images)

    # Exit with appropriate code for CI/CD
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
