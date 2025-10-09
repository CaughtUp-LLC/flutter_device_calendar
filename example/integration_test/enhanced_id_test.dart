import 'package:flutter_device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Enhanced Event ID and Parent ID Tests', () {
    late DeviceCalendarPlugin deviceCalendarPlugin;
    Calendar? writableCalendar;
    final List<String> eventsToCleanup = [];

    setUpAll(() async {
      deviceCalendarPlugin = DeviceCalendarPlugin();
      tz_data.initializeTimeZones();
      
      // Request calendar permissions
      final permissionsGranted = await deviceCalendarPlugin.requestPermissions();
      expect(permissionsGranted.isSuccess, isTrue);
      expect(permissionsGranted.data, isTrue);

      // Get calendars and find writable one
      final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
      expect(calendarsResult.isSuccess, isTrue);
      expect(calendarsResult.data, isNotNull);

      final calendars = calendarsResult.data!;
      expect(calendars, isNotEmpty);

      writableCalendar = calendars.firstWhere(
        (cal) => cal.isReadOnly == false,
        orElse: () => throw Exception('No writable calendar found'),
      );

      print('Using calendar: ${writableCalendar!.name} (ID: ${writableCalendar!.id})');
    });

    tearDownAll(() async {
      // Clean up all created events
      for (final eventId in eventsToCleanup) {
        try {
          await deviceCalendarPlugin.deleteEvent(writableCalendar!.id!, eventId);
        } catch (e) {
          print('Warning: Could not clean up event $eventId: $e');
        }
      }
    });

    testWidgets('Print detailed Event ID and Parent ID information', (tester) async {
      print('\n🔍 === DETAILED EVENT ID AND PARENT ID ANALYSIS ===\n');
      
      // Test 1: Non-recurring event
      print('📅 TEST 1: NON-RECURRING EVENT');
      final singleEvent = Event(
        writableCalendar!.id,
        title: 'Single Event - ID Test - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Testing single event ID patterns',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 2)),
      );

      final singleResult = await deviceCalendarPlugin.createOrUpdateEvent(singleEvent);
      final singleEventId = singleResult!.data!;
      eventsToCleanup.add(singleEventId);
      
      print('┌─────────────────────────────────────────────────┐');
      print('│ CURRENT IMPLEMENTATION                          │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Event ID: $singleEventId');
      print('│ Parent ID: NOT YET IMPLEMENTED');
      print('│ Recurring ID: NOT APPLICABLE');
      print('└─────────────────────────────────────────────────┘');
      
      print('┌─────────────────────────────────────────────────┐');
      print('│ GOOGLE CALENDAR PATTERN SIMULATION              │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Event ID: $singleEventId');
      print('│ Recurring Event ID: null');
      print('│ Parent ID (simulated): $singleEventId');
      print('└─────────────────────────────────────────────────┘');
      
      print('┌─────────────────────────────────────────────────┐');
      print('│ APPLE CALENDAR PATTERN SIMULATION               │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Event Identifier: $singleEventId');
      print('│ Parent ID (simulated): $singleEventId');
      print('│ Occurrence Date: N/A (single event)');
      print('└─────────────────────────────────────────────────┘');
      
      print('┌─────────────────────────────────────────────────┐');
      print('│ YOUR UNIFIED APPROACH (PROPOSED)                │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Event ID: $singleEventId');
      print('│ Parent ID: $singleEventId (same as eventId)');
      print('│ Cross-platform: ✅ CONSISTENT');
      print('└─────────────────────────────────────────────────┘\n');

      // Test 2: Recurring event
      print('🔄 TEST 2: RECURRING EVENT SERIES');
      final recurringEvent = Event(
        writableCalendar!.id,
        title: 'Recurring Event - ID Test - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Testing recurring event ID patterns',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 3)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 4)),
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Daily,
          interval: 1,
          totalOccurrences: 4,
        ),
      );

      final recurringResult = await deviceCalendarPlugin.createOrUpdateEvent(recurringEvent);
      final masterEventId = recurringResult!.data!;
      eventsToCleanup.add(masterEventId);

      // Wait a moment for instances to be created
      await Future.delayed(const Duration(seconds: 1));

      // Retrieve instances
      final instancesResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 5)),
        ),
      );

      final instances = instancesResult.data?.where((e) => 
        e.title?.contains('Recurring Event - ID Test') == true
      ).toList() ?? [];

      print('┌─────────────────────────────────────────────────┐');
      print('│ CURRENT IMPLEMENTATION                          │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Master Event ID: $masterEventId');
      print('│ Number of instances found: ${instances.length}');
      print('│ Parent ID: NOT YET IMPLEMENTED');
      for (int i = 0; i < instances.length; i++) {
        print('│ Instance ${i + 1} ID: ${instances[i].eventId}');
        print('│ Instance ${i + 1} Start: ${instances[i].start}');
      }
      print('└─────────────────────────────────────────────────┘');

      print('┌─────────────────────────────────────────────────┐');
      print('│ GOOGLE CALENDAR PATTERN SIMULATION              │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Master Event:');
      print('│   ID: $masterEventId');
      print('│   Recurring Event ID: null (this IS the master)');
      print('│   Parent ID (simulated): $masterEventId');
      print('│');
      for (int i = 0; i < instances.length; i++) {
        final dateStr = instances[i].start?.toIso8601String().split('T')[0].replaceAll('-', '') ?? 'unknown';
        final timeStr = instances[i].start?.toIso8601String().split('T')[1].replaceAll(':', '').substring(0, 6) ?? 'unknown';
        print('│ Instance ${i + 1}:');
        print('│   ID (Google style): ${masterEventId}_${dateStr}T${timeStr}Z');
        print('│   Recurring Event ID: $masterEventId');
        print('│   Parent ID (simulated): $masterEventId');
      }
      print('└─────────────────────────────────────────────────┘');

      print('┌─────────────────────────────────────────────────┐');
      print('│ APPLE CALENDAR PATTERN SIMULATION               │');
      print('├─────────────────────────────────────────────────┤');
      print('│ All instances share same Event Identifier:');
      print('│   Event Identifier: $masterEventId');
      print('│   Parent ID (simulated): $masterEventId');
      print('│');
      for (int i = 0; i < instances.length; i++) {
        print('│ Instance ${i + 1}:');
        print('│   Event Identifier: $masterEventId (same for all)');
        print('│   Occurrence Date: ${instances[i].start}');
        print('│   Parent ID (simulated): $masterEventId');
      }
      print('└─────────────────────────────────────────────────┘');

      print('┌─────────────────────────────────────────────────┐');
      print('│ YOUR UNIFIED APPROACH (PROPOSED)                │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Master Event:');
      print('│   Event ID: $masterEventId');
      print('│   Parent ID: $masterEventId (points to itself)');
      print('│');
      for (int i = 0; i < instances.length; i++) {
        final dateStr = instances[i].start?.toIso8601String().split('T')[0].replaceAll('-', '') ?? 'unknown';
        final timeStr = instances[i].start?.toIso8601String().split('T')[1].replaceAll(':', '').substring(0, 6) ?? 'unknown';
        print('│ Instance ${i + 1}:');
        print('│   Event ID: $masterEventId-${dateStr}T$timeStr (unique)');
        print('│   Parent ID: $masterEventId (unified)');
        print('│   Start: ${instances[i].start}');
      }
      print('│ Cross-platform: ✅ CONSISTENT');
      print('└─────────────────────────────────────────────────┘\n');

      // Test 3: Compare approaches
      print('⚖️  COMPARISON SUMMARY:');
      print('┌─────────────────────────────────────────────────┐');
      print('│ CURRENT STATE vs PROPOSED PARENT ID FEATURE     │');
      print('├─────────────────────────────────────────────────┤');
      print('│ ❌ Current: All instances share same eventId');
      print('│    - Cannot distinguish individual instances');
      print('│    - No parent-child relationship tracking');
      print('│    - Platform differences cause confusion');
      print('│');
      print('│ ✅ With Parent ID: Best of all worlds');
      print('│    - Unique eventId per instance (like Google)');
      print('│    - Shared parentId for series operations');
      print('│    - Works consistently on Android & iOS');
      print('│    - Enables both individual & bulk operations');
      print('└─────────────────────────────────────────────────┘\n');

      // Test 4: Practical operations demonstration
      print('🎯 PRACTICAL OPERATIONS WITH PARENT ID:');
      print('┌─────────────────────────────────────────────────┐');
      print('│ OPERATIONS YOU COULD DO WITH PARENT ID          │');
      print('├─────────────────────────────────────────────────┤');
      print('│ 1. Find all instances in a series:');
      print('│    findEventsByParentId("$masterEventId")');
      print('│    → Returns all ${instances.length} instances');
      print('│');
      print('│ 2. Update single instance:');
      if (instances.isNotEmpty) {
        final dateStr = instances[0].start?.toIso8601String().split('T')[0].replaceAll('-', '') ?? 'unknown';
        final timeStr = instances[0].start?.toIso8601String().split('T')[1].replaceAll(':', '').substring(0, 6) ?? 'unknown';
        print('│    updateEvent("$masterEventId-${dateStr}T$timeStr")');
        print('│    → Updates only first instance');
      }
      print('│');
      print('│ 3. Update entire series:');
      print('│    updateEventsByParentId("$masterEventId")');
      print('│    → Updates all ${instances.length} instances');
      print('│');
      print('│ 4. Delete entire series:');
      print('│    deleteEventsByParentId("$masterEventId")');
      print('│    → Deletes all ${instances.length} instances');
      print('│');
      print('│ 5. Delete from date forward:');
      print('│    findEventsByParentId("$masterEventId")');
      print('│    .where((e) => e.start.isAfter(cutoffDate))');
      print('│    .forEach((e) => deleteEvent(e.eventId))');
      print('└─────────────────────────────────────────────────┘\n');

      print('🚀 CONCLUSION:');
      print('┌─────────────────────────────────────────────────┐');
      print('│ Your Parent ID feature will provide:             │');
      print('│ ✅ Cross-platform consistency                   │');
      print('│ ✅ Individual instance control                  │');
      print('│ ✅ Bulk series operations                       │');
      print('│ ✅ Clear parent-child relationships            │');
      print('│ ✅ Future-proof architecture                   │');
      print('└─────────────────────────────────────────────────┘\n');

      // Verify we found the right events
      expect(instances, isNotEmpty, reason: 'Should find recurring instances');
      print('✅ Test completed successfully with ${instances.length} recurring instances analyzed');
    });
  });
}
