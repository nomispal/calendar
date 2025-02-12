import 'package:calendar/components/home_calendar.dart';
import 'package:calendar/components/my_calendar.dart';
import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: Colors.grey[200],
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
          const SizedBox(width: 8),
          // Expandable right-side container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Set the background color
              ),
              child: ClipRRect(  // This ensures the child content stays within the rounded corners
                borderRadius: BorderRadius.circular(27.0),
                child: HomeCalendar(controller: calendarController),
              ),
            ),
          )
        ],
      ),
    );
  }
}
