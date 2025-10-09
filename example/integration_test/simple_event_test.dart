import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_device_calendar/flutter_device_calendar.dart';

/// Simple test to debug event creation issues
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Simple Event Tests', () {
    late DeviceCalendarPlugin deviceCalendarPlugin;
    late Calendar? testCalendar;

    setUpAll(() async {
      deviceCalendarPlugin = DeviceCalendarPlugin();
      print('Requesting calendar permissions...');
      
      final permissionsResult = await deviceCalendarPlugin.requestPermissions();
      print('Permissions result: ${permissionsResult.isSuccess}, data: ${permissionsResult.data}');
      
      if (!permissionsResult.isSuccess || permissionsResult.data != true) {
        throw Exception('Calendar permissions not granted: ${permissionsResult.errors}');
      }

      print('Getting calendars...');
      final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
      print('Calendars result: ${calendarsResult.isSuccess}');
      
      if (calendarsResult.isSuccess) {
        final calendars = calendarsResult.data ?? [];
        print('Found ${calendars.length} calendars');
        
        for (var calendar in calendars) {
          print('Calendar: ${calendar.name} (ID: ${calendar.id}) - isReadOnly: ${calendar.isReadOnly}');
        }
        
        // Find a writable calendar
        testCalendar = calendars
            .where((cal) => cal.isReadOnly == false)
            .firstOrNull;
            
        if (testCalendar == null) {
          throw Exception('No writable calendar found');
        }
        
        print('Using calendar: ${testCalendar!.name} (ID: ${testCalendar!.id})');
      } else {
        throw Exception('Failed to retrieve calendars: ${calendarsResult.errors}');
      }
    });

    testWidgets('Test simple event creation', (WidgetTester tester) async {
      final event = Event(testCalendar!.id);
      event.title = 'Simple Test Event';
      event.description = 'Testing event creation';
      event.start = TZDateTime.now(local).add(Duration(hours: 1));
      event.end = TZDateTime.now(local).add(Duration(hours: 2));

      print('Creating event: ${event.title}');
      print('Calendar ID: ${event.calendarId}');
      print('Start: ${event.start}');
      print('End: ${event.end}');

      final createResult = await deviceCalendarPlugin.createOrUpdateEvent(event);
      print('Create result: success=${createResult?.isSuccess}');
      
      if (createResult?.errors.isNotEmpty == true) {
        print('Errors: ${createResult?.errors}');
      }
      
      if (createResult?.isSuccess == true) {
        print('Created event ID: ${createResult?.data}');
        expect(createResult?.data, isNotNull);
        expect(createResult?.data, isNotEmpty);
      } else {
        fail('Event creation failed: ${createResult?.errors}');
      }
    });
  });
}
