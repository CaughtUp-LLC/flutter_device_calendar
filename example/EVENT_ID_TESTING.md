# Event ID Testing Documentation

This document describes the comprehensive testing suite created to verify that event IDs work correctly on both Android and iOS platforms for the device_calendar plugin.

## Overview

Event IDs are critical for calendar event management as they:
- Uniquely identify events within a calendar
- Enable event updates and deletions
- Provide consistency across calendar operations
- Support recurring event management
- Enable proper parent-child relationships for recurring events

## Test Suite Components

### 1. Unit Tests (`test/event_id_unit_test.dart`)

Basic functionality tests that verify Event model behavior:

- ✅ Event ID setting and retrieval
- ✅ ID persistence through property updates  
- ✅ Null value handling
- ✅ Empty string handling
- ✅ ID consistency with date changes
- ✅ Unique ID generation validation
- ✅ Recurring event ID support
- ✅ ID validation helpers

**Running unit tests:**
```bash
flutter test test/event_id_unit_test.dart
```

### 2. Integration Tests (`integration_test/event_id_test.dart`)

Comprehensive end-to-end tests that verify real device/platform behavior:

#### Test Coverage:
- ✅ **Event Creation**: Verify event IDs are returned after creation
- ✅ **Event Retrieval**: Confirm event IDs are present when fetching events
- ✅ **Event Updates**: Ensure event IDs remain consistent during updates
- ✅ **Event Deletion**: Validate events can be deleted using their IDs
- ✅ **Platform Validation**: Check platform-specific ID formats
- ✅ **ID Uniqueness**: Verify multiple events get unique IDs

#### Platform-Specific Validations:
- **Android**: Numeric ID format validation
- **iOS**: UUID/alphanumeric ID format validation

**Running integration tests:**
```bash
# Automated script (recommended)
./run_event_id_tests.sh

# Manual execution
# Android
flutter drive --driver=integration_test/integration_test_android.dart --target=integration_test/event_id_test.dart

# iOS  
flutter drive --driver=integration_test/integration_test.dart --target=integration_test/event_id_test.dart
```

### 3. Test Runner Script (`run_event_id_tests.sh`)

Automated script that:
- Detects available Android/iOS devices
- Grants necessary calendar permissions on Android
- Runs tests on both platforms if available
- Provides detailed progress reporting
- Summarizes test results

## Prerequisites

### For Android Testing:
- Connected Android device or running Android emulator
- ADB available in PATH (for permission grants)
- Calendar read/write permissions granted to the app

### For iOS Testing:
- macOS development environment
- Running iOS simulator
- Calendar permissions granted through iOS settings

## Test Scenarios Covered

### 1. Basic Event Lifecycle
```dart
// Create event
Event event = Event(calendarId, title: 'Test Event');
Result<String?> createResult = await plugin.createOrUpdateEvent(event);

// Verify ID is assigned
assert(event.eventId != null);
assert(event.eventId!.isNotEmpty);

// Retrieve event using ID
List<Event> events = await plugin.retrieveEvents(calendarId, params);
Event retrievedEvent = events.firstWhere((e) => e.eventId == event.eventId);

// Update event
retrievedEvent.title = 'Updated Title';
await plugin.createOrUpdateEvent(retrievedEvent);

// Delete event
await plugin.deleteEvent(calendarId, event.eventId!);
```

### 2. Platform-Specific ID Formats

**Android Event IDs:**
- Typically numeric strings (e.g., "12345")
- May include provider-specific prefixes
- Should be parseable as integers in most cases

**iOS Event IDs:**
- UUID-style identifiers or structured strings
- Longer alphanumeric strings
- Case-sensitive identifiers

### 3. Edge Cases Tested
- Multiple event creation with unique ID verification
- Event updates preserving original IDs
- Null and empty ID handling
- Calendar permission scenarios
- Recurring event ID consistency

## Error Scenarios and Handling

The tests include proper error handling for:
- Missing calendar permissions
- Invalid calendar IDs
- Network connectivity issues
- Platform-specific limitations
- Device/simulator availability

## Integration with Parent ID Feature

These tests complement the new parent ID functionality for recurring events by ensuring:
- Base event IDs work correctly
- Parent-child relationships can be established
- Recurring event instances maintain proper ID references

## Usage in CI/CD

The test suite is designed to work in automated environments:

```yaml
# Example GitHub Actions step
- name: Run Event ID Tests
  run: |
    cd example
    # Start Android emulator
    $ANDROID_HOME/emulator/emulator -avd test_avd -no-window &
    # Wait for emulator
    adb wait-for-device
    # Run tests
    ./run_event_id_tests.sh
```

## Troubleshooting

### Common Issues:

1. **Permission Denied Errors**
   - Ensure calendar permissions are granted
   - Check app has proper manifest permissions

2. **Device Not Found**
   - Verify Android emulator/device is running
   - Check iOS simulator is booted

3. **ADB Command Not Found**
   - Install Android SDK tools
   - Add platform-tools to PATH

4. **Test Timeouts**
   - Increase test timeout values
   - Check device performance/resources

### Debug Information:

Tests provide detailed logging:
- Event creation timestamps
- Generated event IDs
- Platform detection results
- Permission grant status
- Test execution progress

## Validation Results

Expected outcomes for successful test runs:
- All unit tests pass (8/8)
- Integration tests complete on available platforms
- Event IDs are non-null and unique
- Platform-specific format validation passes
- Event CRUD operations work correctly

This comprehensive testing ensures reliable event ID functionality across Android and iOS platforms, supporting both basic calendar operations and advanced features like recurring events with parent-child relationships.
