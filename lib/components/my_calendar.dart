import 'package:calendar/components/event_filter.dart';
import 'package:calendar/components/upcoming_event_list.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../pages/event_filter_screen.dart';
import '../state/calendar_controller.dart';
import 'event_search.dart';

class MyCalendar extends StatefulWidget {
  final CalendarController controller;

  const MyCalendar({required this.controller, Key? key}) : super(key: key);

  @override
  State<MyCalendar> createState() => _MyCalendarState();
}

class _MyCalendarState extends State<MyCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
              return TableCalendar(
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
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: const CalendarStyle(
                  cellPadding: EdgeInsets.zero, // Remove padding
                  cellMargin: EdgeInsets.zero,
                  defaultTextStyle: TextStyle(
                      color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
                  weekendTextStyle: TextStyle(
                      color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500),
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
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left,size: 18, color: Colors.black),
                  rightChevronIcon: Icon(Icons.chevron_right, size: 18, color: Colors.black), // Smaller icon
                  leftChevronMargin: EdgeInsets.only(right: 8.0),
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
                            fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const Divider(), // Add a separator
        const UpcomingEventsList(), // Add upcoming events list
        const Divider(),
        EventFilterButton(
            onTap:(){
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
