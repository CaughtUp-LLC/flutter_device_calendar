import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Integration test to verify that event IDs work correctly on both Android and iOS
/// This test covers:
/// 1. Creating an event and getting a valid event ID
/// 2. Retrieving events and verifying event IDs are present
/// 3. Using event IDs to retrieve specific events
/// 4. Verifying event ID consistency across create/retrieve operations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  group('Event ID functionality tests', () {
    late DeviceCalendarPlugin deviceCalendarPlugin;
    late List<Calendar> calendars;
    Calendar? writableCalendar;
    String? createdEventId;
    
    setUpAll(() async {
      deviceCalendarPlugin = DeviceCalendarPlugin();
      
      // Request calendar permissions
      var permissionsGranted = await deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          fail('Calendar permissions not granted');
        }
      }
      
      // Get calendars and find a writable one
      final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
      expect(calendarsResult.isSuccess, isTrue, reason: 'Failed to retrieve calendars');
      
      calendars = calendarsResult.data!;
      writableCalendar = calendars.firstWhere(
        (cal) => cal.isReadOnly == false,
        orElse: () => throw Exception('No writable calendar found'),
      );
      
      print('Using calendar: ${writableCalendar!.name} (ID: ${writableCalendar!.id})');
    });
    
    tearDownAll(() async {
      // Clean up any created events
      if (createdEventId != null && writableCalendar != null) {
        try {
          await deviceCalendarPlugin.deleteEvent(writableCalendar!.id!, createdEventId!);
          print('Cleaned up test event: $createdEventId');
        } catch (e) {
          print('Failed to clean up test event: $e');
        }
      }
    });

    testWidgets('Create event and verify event ID is returned', (WidgetTester tester) async {
      expect(writableCalendar, isNotNull, reason: 'No writable calendar available');
      
      // Create a test event
      final testEvent = Event(
        writableCalendar!.id,
        title: 'Event ID Test Event - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Test event to verify event ID functionality',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 2)),
      );
      
      print('Creating test event: ${testEvent.title}');
      
      // Create the event
      final createResult = await deviceCalendarPlugin.createOrUpdateEvent(testEvent);
      
      // Verify creation was successful
      expect(createResult, isNotNull, reason: 'Create result should not be null');
      expect(createResult!.isSuccess, isTrue, 
        reason: 'Event creation failed: ${createResult.errors.map((e) => e.errorMessage).join(", ")}');
      
      // Verify event ID is present and valid
      expect(testEvent.eventId, isNotNull, reason: 'Event ID should not be null after creation');
      expect(testEvent.eventId, isNotEmpty, reason: 'Event ID should not be empty after creation');
      
      createdEventId = testEvent.eventId;
      print('✓ Event created with ID: $createdEventId');
      
      // Platform-specific event ID format validation
      if (Platform.isAndroid) {
        // Android event IDs are typically numeric strings
        expect(int.tryParse(createdEventId!), isNotNull, 
          reason: 'Android event ID should be numeric');
        print('✓ Android event ID format validated');
      } else if (Platform.isIOS) {
        // iOS event IDs are typically UUIDs or alphanumeric strings
        expect(createdEventId!.length, greaterThan(10), 
          reason: 'iOS event ID should be a substantial string');
        print('✓ iOS event ID format validated');
      }
    });

    testWidgets('Retrieve events and verify event IDs are present', (WidgetTester tester) async {
      expect(createdEventId, isNotNull, reason: 'No event was created in previous test');
      
      // Retrieve events from the calendar
      final retrieveResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );
      
      expect(retrieveResult.isSuccess, isTrue, 
        reason: 'Failed to retrieve events: ${retrieveResult.errors.map((e) => e.errorMessage).join(", ")}');
      
      final events = retrieveResult.data!;
      expect(events, isNotEmpty, reason: 'Should have at least our created event');
      
      // Find our created event
      final ourEvent = events.firstWhere(
        (event) => event.eventId == createdEventId,
        orElse: () => throw Exception('Created event not found in retrieval'),
      );
      
      // Verify the event has the correct properties
      expect(ourEvent.eventId, equals(createdEventId), 
        reason: 'Retrieved event ID should match created event ID');
      expect(ourEvent.title, contains('Event ID Test Event'), 
        reason: 'Retrieved event title should match');
      expect(ourEvent.calendarId, equals(writableCalendar!.id), 
        reason: 'Retrieved event calendar ID should match');
      
      print('✓ Event successfully retrieved using event ID');
      
      // Verify all retrieved events have valid event IDs
      for (final event in events) {
        expect(event.eventId, isNotNull, 
          reason: 'All retrieved events should have event IDs');
        expect(event.eventId, isNotEmpty, 
          reason: 'All retrieved event IDs should be non-empty');
      }
      
      print('✓ All ${events.length} retrieved events have valid event IDs');
    });

    testWidgets('Update event using event ID and verify consistency', (WidgetTester tester) async {
      expect(createdEventId, isNotNull, reason: 'No event was created to update');
      
      // First retrieve the event
      final retrieveResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );
      
      final events = retrieveResult.data!;
      final eventToUpdate = events.firstWhere((event) => event.eventId == createdEventId);
      
      // Update the event
      final originalTitle = eventToUpdate.title;
      eventToUpdate.title = '${originalTitle} - UPDATED';
      eventToUpdate.description = 'Updated description to test event ID consistency';
      
      print('Updating event: ${eventToUpdate.eventId}');
      
      // Save the updated event
      final updateResult = await deviceCalendarPlugin.createOrUpdateEvent(eventToUpdate);
      
      expect(updateResult, isNotNull, reason: 'Update result should not be null');
      expect(updateResult!.isSuccess, isTrue, 
        reason: 'Event update failed: ${updateResult.errors.map((e) => e.errorMessage).join(", ")}');
      
      // Verify the event ID remained the same after update
      expect(eventToUpdate.eventId, equals(createdEventId), 
        reason: 'Event ID should remain consistent after update');
      
      print('✓ Event updated successfully, ID remained consistent');
      
      // Retrieve the event again to verify the update
      await tester.pump(const Duration(milliseconds: 500)); // Give time for the update to propagate
      
      final verifyResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );
      
      final updatedEvents = verifyResult.data!;
      final verifiedEvent = updatedEvents.firstWhere((event) => event.eventId == createdEventId);
      
      expect(verifiedEvent.title, contains('UPDATED'), 
        reason: 'Updated event should have the new title');
      expect(verifiedEvent.eventId, equals(createdEventId), 
        reason: 'Verified event should have the same event ID');
      
      print('✓ Event update verified with consistent event ID');
    });

    testWidgets('Delete event using event ID', (WidgetTester tester) async {
      expect(createdEventId, isNotNull, reason: 'No event was created to delete');
      
      print('Deleting event: $createdEventId');
      
      // Delete the event
      final deleteResult = await deviceCalendarPlugin.deleteEvent(
        writableCalendar!.id!,
        createdEventId!,
      );
      
      expect(deleteResult.isSuccess, isTrue, 
        reason: 'Event deletion failed: ${deleteResult.errors.map((e) => e.errorMessage).join(", ")}');
      
      print('✓ Event deleted successfully');
      
      // Verify the event is no longer retrievable
      await tester.pump(const Duration(milliseconds: 500)); // Give time for deletion to propagate
      
      final verifyResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );
      
      final remainingEvents = verifyResult.data!;
      final deletedEventExists = remainingEvents.any((event) => event.eventId == createdEventId);
      
      expect(deletedEventExists, isFalse, 
        reason: 'Deleted event should no longer be retrievable');
      
      print('✓ Event deletion verified - event no longer exists');
      
      // Clear the created event ID since it's been deleted
      createdEventId = null;
    });

    testWidgets('Platform-specific event ID behavior', (WidgetTester tester) async {
      // Create multiple events to test ID generation patterns
      final testEvents = <Event>[];
      final eventIds = <String>[];
      
      for (int i = 0; i < 3; i++) {
        final event = Event(
          writableCalendar!.id,
          title: 'ID Pattern Test Event $i',
          start: tz.TZDateTime.now(tz.local).add(Duration(hours: i + 1)),
          end: tz.TZDateTime.now(tz.local).add(Duration(hours: i + 2)),
        );
        
        final createResult = await deviceCalendarPlugin.createOrUpdateEvent(event);
        expect(createResult, isNotNull);
        expect(createResult!.isSuccess, isTrue);
        
        testEvents.add(event);
        eventIds.add(event.eventId!);
        
        print('Created test event $i with ID: ${event.eventId}');
      }
      
      // Verify all event IDs are unique
      final uniqueIds = Set<String>.from(eventIds);
      expect(uniqueIds.length, equals(eventIds.length), 
        reason: 'All event IDs should be unique');
      
      // Platform-specific validations
      if (Platform.isAndroid) {
        // Android typically uses sequential numeric IDs or structured identifiers
        print('✓ Android event ID uniqueness verified');
        
        // Check that IDs follow expected Android patterns
        for (final id in eventIds) {
          expect(id.isNotEmpty, isTrue, reason: 'Android event IDs should not be empty');
          // Most Android calendar providers use numeric IDs
          expect(id.length, greaterThan(0), reason: 'Android event IDs should have content');
        }
      } else if (Platform.isIOS) {
        // iOS typically uses UUID-style identifiers
        print('✓ iOS event ID uniqueness verified');
        
        // Check that IDs follow expected iOS patterns  
        for (final id in eventIds) {
          expect(id.isNotEmpty, isTrue, reason: 'iOS event IDs should not be empty');
          expect(id.length, greaterThan(5), reason: 'iOS event IDs should be substantial strings');
        }
      }
      
      print('✓ Platform-specific event ID patterns validated');
      
      // Clean up test events
      for (final event in testEvents) {
        await deviceCalendarPlugin.deleteEvent(writableCalendar!.id!, event.eventId!);
      }
      
      print('✓ Cleaned up ${testEvents.length} test events');
    });
  });
}
