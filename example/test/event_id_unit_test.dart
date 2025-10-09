import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Unit tests for Event ID functionality
/// These tests verify the basic Event model behavior and ID handling
void main() {
  group('Event ID Unit Tests', () {
    setUpAll(() {
      tz.initializeTimeZones();
    });

    test('Event ID should be settable and retrievable', () {
      const testId = 'test-event-id-123';
      const calendarId = 'test-calendar-id';
      
      final event = Event(
        calendarId,
        title: 'Test Event',
        eventId: testId,
      );
      
      expect(event.eventId, equals(testId));
      expect(event.calendarId, equals(calendarId));
    });

    test('Event ID should persist through property updates', () {
      const originalId = 'original-id-456';
      const calendarId = 'test-calendar-id';
      
      final event = Event(
        calendarId,
        title: 'Original Title',
        eventId: originalId,
      );
      
      // Verify initial state
      expect(event.eventId, equals(originalId));
      
      // Update other properties
      event.title = 'Updated Title';
      event.description = 'Updated Description';
      event.location = 'Updated Location';
      
      // Event ID should remain unchanged
      expect(event.eventId, equals(originalId));
      expect(event.title, equals('Updated Title'));
    });

    test('Event ID should handle null values correctly', () {
      const calendarId = 'test-calendar-id';
      
      final event = Event(
        calendarId,
        title: 'Test Event',
        // eventId not specified, should be null
      );
      
      expect(event.eventId, isNull);
      
      // Should be able to set ID later
      const newId = 'newly-assigned-id';
      event.eventId = newId;
      expect(event.eventId, equals(newId));
    });

    test('Event ID should handle empty string correctly', () {
      const calendarId = 'test-calendar-id';
      
      final event = Event(
        calendarId,
        title: 'Test Event',
        eventId: '',
      );
      
      expect(event.eventId, equals(''));
      expect(event.eventId?.isEmpty, isTrue);
    });

    test('Event should maintain ID consistency with start/end dates', () {
      const eventId = 'date-test-id';
      const calendarId = 'test-calendar-id';
      
      final startTime = tz.TZDateTime.now(tz.local);
      final endTime = startTime.add(const Duration(hours: 1));
      
      final event = Event(
        calendarId,
        title: 'Date Test Event',
        eventId: eventId,
        start: startTime,
        end: endTime,
      );
      
      expect(event.eventId, equals(eventId));
      expect(event.start, equals(startTime));
      expect(event.end, equals(endTime));
      
      // Update dates
      final newStart = startTime.add(const Duration(hours: 2));
      final newEnd = endTime.add(const Duration(hours: 2));
      
      event.start = newStart;
      event.end = newEnd;
      
      // ID should remain consistent
      expect(event.eventId, equals(eventId));
      expect(event.start, equals(newStart));
      expect(event.end, equals(newEnd));
    });

    test('Multiple events should have different IDs when created', () {
      const calendarId = 'test-calendar-id';
      
      final event1 = Event(
        calendarId,
        title: 'Event 1',
        eventId: 'id-1',
      );
      
      final event2 = Event(
        calendarId,
        title: 'Event 2', 
        eventId: 'id-2',
      );
      
      final event3 = Event(
        calendarId,
        title: 'Event 3',
        eventId: 'id-3',
      );
      
      expect(event1.eventId, isNot(equals(event2.eventId)));
      expect(event1.eventId, isNot(equals(event3.eventId)));
      expect(event2.eventId, isNot(equals(event3.eventId)));
      
      // All should be non-null and non-empty
      expect(event1.eventId, isNotNull);
      expect(event2.eventId, isNotNull);
      expect(event3.eventId, isNotNull);
      
      expect(event1.eventId?.isNotEmpty, isTrue);
      expect(event2.eventId?.isNotEmpty, isTrue);
      expect(event3.eventId?.isNotEmpty, isTrue);
    });

    test('Event ID should work with recurring events', () {
      const eventId = 'recurring-event-id';
      const calendarId = 'test-calendar-id';
      
      final recurrenceRule = RecurrenceRule(
        RecurrenceFrequency.Daily,
        interval: 1,
        totalOccurrences: 5,
      );
      
      final event = Event(
        calendarId,
        title: 'Recurring Event',
        eventId: eventId,
        recurrenceRule: recurrenceRule,
      );
      
      expect(event.eventId, equals(eventId));
      expect(event.recurrenceRule, isNotNull);
      expect(event.recurrenceRule?.totalOccurrences, equals(5));
      
      // Update recurrence rule
      event.recurrenceRule = RecurrenceRule(
        RecurrenceFrequency.Weekly,
        interval: 2,
      );
      
      // ID should remain consistent
      expect(event.eventId, equals(eventId));
      expect(event.recurrenceRule?.recurrenceFrequency, equals(RecurrenceFrequency.Weekly));
    });

    test('Event ID validation helpers', () {
      // Test helper functions for ID validation
      bool isValidEventId(String? id) {
        return id != null && id.isNotEmpty && id.trim() == id;
      }
      
      // Valid IDs
      expect(isValidEventId('valid-id-123'), isTrue);
      expect(isValidEventId('1234567890'), isTrue);
      expect(isValidEventId('UUID-STYLE-ID-HERE'), isTrue);
      
      // Invalid IDs
      expect(isValidEventId(null), isFalse);
      expect(isValidEventId(''), isFalse);
      expect(isValidEventId(' id-with-spaces '), isFalse);
      expect(isValidEventId('  '), isFalse);
    });
  });
}
