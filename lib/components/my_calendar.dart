import 'package:calendar/components/event_filter.dart';
import 'package:calendar/components/upcoming_event_list.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../pages/event_filter_screen.dart';
import '../state/calendar_controller.dart';

class MyCalendar extends StatefulWidget {
  final CalendarController controller;

  const MyCalendar({required this.controller, super.key});

  @override
  State<MyCalendar> createState() => _MyCalendarState();
}

class _MyCalendarState extends State<MyCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.44,
          width: MediaQuery.of(context).size.height * 0.50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
          ),
          child: ValueListenableBuilder<DateTime>(
            valueListenable: widget.controller.focusedDayNotifier,
            builder: (context, focusedDay, _) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: TableCalendar(
                  rowHeight: 34,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2050, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      widget.controller.focusedDayNotifier.value = focusedDay;
                    });
                  },
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
                    cellPadding: EdgeInsets.zero,
                    cellMargin: EdgeInsets.zero,
                    defaultTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500
                    ),
                    weekendTextStyle: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w500
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    titleTextStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, size: 18, color: Colors.black),
                    rightChevronIcon: const Icon(Icons.chevron_right, size: 18, color: Colors.black),
                    leftChevronMargin: const EdgeInsets.only(right: 8.0),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
                      return Center(
                        child: Text(
                          text,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(),
        const UpcomingEventsList(),
        const Divider(),
        EventFilterButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventFilterScreen()),
              );
            }
        )
      ],
    );
  }
}