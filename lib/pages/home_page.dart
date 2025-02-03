import 'package:calendar/components/home_calendar.dart';
import 'package:calendar/components/my_calendar.dart';
import 'package:calendar/components/upcoming_event_list.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../state/calendar_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    final calendarController = CalendarController();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Left-side container for the calendar
          Container(
            width: screenWidth * 0.25, // 30% of the screen width
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: MyCalendar(controller: calendarController),
          ),
          // Expandable right-side container
          Expanded(
            child: HomeCalendar(controller: calendarController,),
          ),
        ],
      ),
    );
  }
}
