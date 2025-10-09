#!/bin/bash

# Event ID Test Runner Script
# This script runs the event ID integration test on both Android and iOS

set -e

echo "🧪 Running Event ID Integration Tests"
echo "====================================="

# Function to check if a device/simulator is available
check_device() {
    local platform=$1
    if [ "$platform" = "android" ]; then
        if ! adb devices | grep -q "device$"; then
            echo "❌ No Android device/emulator found. Please start an Android device or emulator."
            return 1
        fi
        echo "✅ Android device found"
    elif [ "$platform" = "ios" ]; then
        if ! xcrun simctl list devices | grep -q "Booted"; then
            echo "❌ No iOS simulator found running. Please start iOS simulator."
            return 1
        fi
        echo "✅ iOS simulator found"
    fi
    return 0
}

# Function to grant calendar permissions on Android
grant_android_permissions() {
    echo "📱 Granting Android calendar permissions..."
    adb shell pm grant dev.flutter_device_calendar.example android.permission.READ_CALENDAR || echo "⚠️  Permission already granted or failed"
    adb shell pm grant dev.flutter_device_calendar.example android.permission.WRITE_CALENDAR || echo "⚠️  Permission already granted or failed"
    echo "✅ Android permissions processed"
}

# Function to run the test on a specific platform
run_test() {
    local platform=$1
    echo ""
    echo "🚀 Running Event ID test on $platform..."
    echo "=================================="
    
    if [ "$platform" = "android" ]; then
        grant_android_permissions
        flutter drive \
            --driver=integration_test/integration_test_android.dart \
            --target=integration_test/event_id_test.dart \
            --device-id=$(adb devices | grep "device$" | head -1 | awk '{print $1}')
    elif [ "$platform" = "ios" ]; then
        flutter drive \
            --driver=integration_test/integration_test.dart \
            --target=integration_test/event_id_test.dart \
            --device-id=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ $platform test completed successfully!"
    else
        echo "❌ $platform test failed!"
        return 1
    fi
}

# Main execution
main() {
    echo "📍 Current directory: $(pwd)"
    echo "📱 Available devices:"
    echo "Android devices:"
    adb devices
    echo "iOS simulators:"
    xcrun simctl list devices | grep "Booted" || echo "No iOS simulators running"
    echo ""
    
    # Check what platforms are available
    local android_available=false
    local ios_available=false
    
    if check_device "android"; then
        android_available=true
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]] && check_device "ios"; then
        ios_available=true
    fi
    
    if [ "$android_available" = false ] && [ "$ios_available" = false ]; then
        echo "❌ No devices available for testing. Please start an Android device/emulator or iOS simulator."
        exit 1
    fi
    
    # Run tests on available platforms
    local test_results=()
    
    if [ "$android_available" = true ]; then
        if run_test "android"; then
            test_results+=("✅ Android: PASSED")
        else
            test_results+=("❌ Android: FAILED")
        fi
    fi
    
    if [ "$ios_available" = true ]; then
        if run_test "ios"; then
            test_results+=("✅ iOS: PASSED")
        else
            test_results+=("❌ iOS: FAILED")
        fi
    fi
    
    # Summary
    echo ""
    echo "📊 Test Results Summary"
    echo "======================"
    for result in "${test_results[@]}"; do
        echo "$result"
    done
    
    # Check if any tests failed
    for result in "${test_results[@]}"; do
        if [[ $result == *"FAILED"* ]]; then
            echo ""
            echo "❌ Some tests failed. Please check the output above."
            exit 1
        fi
    done
    
    echo ""
    echo "🎉 All Event ID tests passed!"
}

# Run the main function
main "$@"
