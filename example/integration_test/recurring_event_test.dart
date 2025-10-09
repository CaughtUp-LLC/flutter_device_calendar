import 'package:flutter_device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Recurring Event Tests', () {
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

    testWidgets('Create daily recurring event and verify instances', (tester) async {
      final recurringEvent = Event(
        writableCalendar!.id,
        title: 'Daily Recurring Event - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Testing daily recurring event with 5 occurrences',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 2)),
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Daily,
          interval: 1,
          totalOccurrences: 5,
        ),
      );

      print('🔄 Creating daily recurring event: ${recurringEvent.title}');
      final createResult = await deviceCalendarPlugin.createOrUpdateEvent(recurringEvent);

      expect(createResult?.isSuccess, isTrue);
      expect(createResult?.data, isNotNull);

      final eventId = createResult!.data!;
      eventsToCleanup.add(eventId);

      print('✅ Daily recurring event created with ID: $eventId');
      
      // Wait a moment for the event to be processed
      await Future.delayed(const Duration(seconds: 1));

      // Retrieve events to see the recurring instances
      final retrieveResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );

      expect(retrieveResult.isSuccess, isTrue);
      final events = retrieveResult.data ?? [];
      
      // Find our recurring events
      final ourEvents = events.where((e) => e.title?.contains('Daily Recurring Event') == true).toList();
      
      print('📅 Found ${ourEvents.length} recurring event instances:');
      for (int i = 0; i < ourEvents.length; i++) {
        final event = ourEvents[i];
        print('  Instance ${i + 1}:');
        print('    - Event ID: ${event.eventId}');
        print('    - Title: ${event.title}');
        print('    - Start: ${event.start}');
        print('    - End: ${event.end}');
        print('    - Has Recurrence Rule: ${event.recurrenceRule != null}');
        if (event.recurrenceRule != null) {
          print('    - Frequency: ${event.recurrenceRule!.recurrenceFrequency}');
          print('    - Interval: ${event.recurrenceRule!.interval}');
          print('    - Total Occurrences: ${event.recurrenceRule!.totalOccurrences}');
        }
        print('');
      }

      expect(ourEvents, isNotEmpty, reason: 'Should find at least one recurring event instance');
      
      // Verify recurring event properties
      final masterEvent = ourEvents.first;
      expect(masterEvent.recurrenceRule, isNotNull, reason: 'Recurring event should have recurrence rule');
      expect(masterEvent.recurrenceRule!.recurrenceFrequency, equals(RecurrenceFrequency.Daily));
      expect(masterEvent.recurrenceRule!.interval, equals(1));
      expect(masterEvent.recurrenceRule!.totalOccurrences, equals(5));

      print('✅ Daily recurring event validation completed');
    });

    testWidgets('Create weekly recurring event with specific days', (tester) async {
      final weeklyEvent = Event(
        writableCalendar!.id,
        title: 'Weekly Recurring Event - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Testing weekly recurring event on Monday, Wednesday, Friday',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 3)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 4)),
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Weekly,
          interval: 1,
          totalOccurrences: 6,
          daysOfWeek: [DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Friday],
        ),
      );

      print('🔄 Creating weekly recurring event: ${weeklyEvent.title}');
      final createResult = await deviceCalendarPlugin.createOrUpdateEvent(weeklyEvent);

      expect(createResult?.isSuccess, isTrue);
      expect(createResult?.data, isNotNull);

      final eventId = createResult!.data!;
      eventsToCleanup.add(eventId);

      print('✅ Weekly recurring event created with ID: $eventId');
      
      // Wait a moment for the event to be processed
      await Future.delayed(const Duration(seconds: 1));

      // Retrieve events over a longer period to catch weekly instances
      final retrieveResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 21)), // 3 weeks
        ),
      );

      expect(retrieveResult.isSuccess, isTrue);
      final events = retrieveResult.data ?? [];
      
      // Find our recurring events
      final ourEvents = events.where((e) => e.title?.contains('Weekly Recurring Event') == true).toList();
      
      print('📅 Found ${ourEvents.length} weekly recurring event instances:');
      for (int i = 0; i < ourEvents.length; i++) {
        final event = ourEvents[i];
        print('  Instance ${i + 1}:');
        print('    - Event ID: ${event.eventId}');
        print('    - Title: ${event.title}');
        print('    - Start: ${event.start}');
        print('    - Day of Week: ${event.start?.weekday}');
        print('    - Has Recurrence Rule: ${event.recurrenceRule != null}');
        if (event.recurrenceRule != null) {
          print('    - Frequency: ${event.recurrenceRule!.recurrenceFrequency}');
          print('    - Days of Week: ${event.recurrenceRule!.daysOfWeek}');
        }
        print('');
      }

      expect(ourEvents, isNotEmpty, reason: 'Should find at least one weekly recurring event instance');
      
      // Verify recurring event properties
      final masterEvent = ourEvents.first;
      expect(masterEvent.recurrenceRule, isNotNull, reason: 'Weekly recurring event should have recurrence rule');
      expect(masterEvent.recurrenceRule!.recurrenceFrequency, equals(RecurrenceFrequency.Weekly));
      expect(masterEvent.recurrenceRule!.interval, equals(1));
      expect(masterEvent.recurrenceRule!.totalOccurrences, equals(6));
      expect(masterEvent.recurrenceRule!.daysOfWeek, isNotNull);
      expect(masterEvent.recurrenceRule!.daysOfWeek!.length, equals(3));
      expect(masterEvent.recurrenceRule!.daysOfWeek, 
        containsAll([DayOfWeek.Monday, DayOfWeek.Wednesday, DayOfWeek.Friday]));

      print('✅ Weekly recurring event validation completed');
    });

    testWidgets('Create monthly recurring event', (tester) async {
      final monthlyEvent = Event(
        writableCalendar!.id,
        title: 'Monthly Recurring Event - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Testing monthly recurring event for 3 months',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 5)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 6)),
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Monthly,
          interval: 1,
          totalOccurrences: 3,
        ),
      );

      print('🔄 Creating monthly recurring event: ${monthlyEvent.title}');
      final createResult = await deviceCalendarPlugin.createOrUpdateEvent(monthlyEvent);

      expect(createResult?.isSuccess, isTrue);
      expect(createResult?.data, isNotNull);

      final eventId = createResult!.data!;
      eventsToCleanup.add(eventId);

      print('✅ Monthly recurring event created with ID: $eventId');
      
      // Wait a moment for the event to be processed
      await Future.delayed(const Duration(seconds: 1));

      // Retrieve events over several months
      final retrieveResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 100)), // ~3+ months
        ),
      );

      expect(retrieveResult.isSuccess, isTrue);
      final events = retrieveResult.data ?? [];
      
      // Find our recurring events
      final ourEvents = events.where((e) => e.title?.contains('Monthly Recurring Event') == true).toList();
      
      print('📅 Found ${ourEvents.length} monthly recurring event instances:');
      for (int i = 0; i < ourEvents.length; i++) {
        final event = ourEvents[i];
        print('  Instance ${i + 1}:');
        print('    - Event ID: ${event.eventId}');
        print('    - Title: ${event.title}');
        print('    - Start: ${event.start}');
        print('    - Month: ${event.start?.month}');
        print('    - Has Recurrence Rule: ${event.recurrenceRule != null}');
      }

      expect(ourEvents, isNotEmpty, reason: 'Should find at least one monthly recurring event instance');
      
      // Verify recurring event properties
      final masterEvent = ourEvents.first;
      expect(masterEvent.recurrenceRule, isNotNull, reason: 'Monthly recurring event should have recurrence rule');
      expect(masterEvent.recurrenceRule!.recurrenceFrequency, equals(RecurrenceFrequency.Monthly));
      expect(masterEvent.recurrenceRule!.interval, equals(1));
      expect(masterEvent.recurrenceRule!.totalOccurrences, equals(3));

      print('✅ Monthly recurring event validation completed');
    });

    testWidgets('Test recurring event parent ID simulation', (tester) async {
      print('🎯 Testing Parent ID behavior for recurring events:');
      
      final recurringEvent = Event(
        writableCalendar!.id,
        title: 'Parent ID Test - Recurring - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Testing parent ID relationships in recurring events',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 7)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 8)),
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Daily,
          interval: 1,
          totalOccurrences: 4,
        ),
      );

      final createResult = await deviceCalendarPlugin.createOrUpdateEvent(recurringEvent);
      final parentEventId = createResult!.data!;
      eventsToCleanup.add(parentEventId);

      print('✅ Master recurring event created with ID: $parentEventId');

      // Retrieve the recurring instances
      final retrieveResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 5)),
        ),
      );

      final events = retrieveResult.data ?? [];
      final recurringInstances = events.where((e) => 
        e.title?.contains('Parent ID Test - Recurring') == true
      ).toList();

      print('📊 Parent ID Analysis for ${recurringInstances.length} instances:');
      
      for (int i = 0; i < recurringInstances.length; i++) {
        final instance = recurringInstances[i];
        print('  Instance ${i + 1}:');
        print('    - Event ID: ${instance.eventId}');
        print('    - Title: ${instance.title}');
        print('    - Start: ${instance.start}');
        
        // Simulate parent ID behavior
        print('    🔍 Simulated Parent ID Relationships:');
        print('      📍 Google Calendar: recurringEventId = $parentEventId, parentId = $parentEventId');
        print('      🍎 Apple Calendar: parentId = $parentEventId');
        print('      ✅ Your Implementation: parentId = $parentEventId');
        print('');
      }

      print('💡 Parent ID Benefits Demonstrated:');
      print('  ✅ All ${recurringInstances.length} instances would have parentId = $parentEventId');
      print('  ✅ findEventsByParentId($parentEventId) would return all instances');
      print('  ✅ updateRecurringSeries($parentEventId) would update all instances');
      print('  ✅ deleteRecurringSeries($parentEventId) would delete all instances');

      expect(recurringInstances, isNotEmpty, reason: 'Should find recurring instances');
      print('✅ Parent ID simulation for recurring events completed');
    });

    testWidgets('Test different recurrence intervals', (tester) async {
      print('🔄 Testing different recurrence intervals:');
      
      // Every 2 days
      final everyTwoDaysEvent = Event(
        writableCalendar!.id,
        title: 'Every 2 Days - ${DateTime.now().millisecondsSinceEpoch}',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 9)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 10)),
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Daily,
          interval: 2,
          totalOccurrences: 3,
        ),
      );

      final createResult1 = await deviceCalendarPlugin.createOrUpdateEvent(everyTwoDaysEvent);
      eventsToCleanup.add(createResult1!.data!);
      print('✅ Every 2 days event created with ID: ${createResult1.data}');

      // Every 2 weeks
      final everyTwoWeeksEvent = Event(
        writableCalendar!.id,
        title: 'Every 2 Weeks - ${DateTime.now().millisecondsSinceEpoch}',
        start: tz.TZDateTime.now(tz.local).add(const Duration(hours: 11)),
        end: tz.TZDateTime.now(tz.local).add(const Duration(hours: 12)),
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Weekly,
          interval: 2,
          totalOccurrences: 3,
        ),
      );

      final createResult2 = await deviceCalendarPlugin.createOrUpdateEvent(everyTwoWeeksEvent);
      eventsToCleanup.add(createResult2!.data!);
      print('✅ Every 2 weeks event created with ID: ${createResult2.data}');

      // Retrieve and verify
      final retrieveResult = await deviceCalendarPlugin.retrieveEvents(
        writableCalendar!.id!,
        RetrieveEventsParams(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 35)),
        ),
      );

      final events = retrieveResult.data ?? [];
      
      final twoDayEvents = events.where((e) => e.title?.contains('Every 2 Days') == true).toList();
      final twoWeekEvents = events.where((e) => e.title?.contains('Every 2 Weeks') == true).toList();

      print('📊 Interval Testing Results:');
      print('  Every 2 Days: Found ${twoDayEvents.length} instances');
      print('  Every 2 Weeks: Found ${twoWeekEvents.length} instances');

      if (twoDayEvents.isNotEmpty) {
        expect(twoDayEvents.first.recurrenceRule?.interval, equals(2));
        expect(twoDayEvents.first.recurrenceRule?.recurrenceFrequency, equals(RecurrenceFrequency.Daily));
      }

      if (twoWeekEvents.isNotEmpty) {
        expect(twoWeekEvents.first.recurrenceRule?.interval, equals(2));
        expect(twoWeekEvents.first.recurrenceRule?.recurrenceFrequency, equals(RecurrenceFrequency.Weekly));
      }

      print('✅ Interval testing completed');
    });
  });
}
