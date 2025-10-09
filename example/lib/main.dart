import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'common/app_routes.dart';
import 'presentation/pages/calendars.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(),
      themeMode: ThemeMode.system,
      darkTheme: ThemeData.dark(),
      routes: {
        AppRoutes.calendars: (context) {
          return const CalendarsPage(key: Key('calendarsPage'));
        }
      },
    );
  }
}
