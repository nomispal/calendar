import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/calendar_controller.dart';
import './event_dialog.dart';
import '../models/event.dart';
import '../components/address_search_field.dart';

class HomeCalendar extends StatefulWidget {
  final CalendarController controller;

  const HomeCalendar({required this.controller, Key? key}) : super(key: key);

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  final Map<DateTime, String> _selectedAddresses = {};

  // Function to calculate the start of the week (Monday)
  DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1)); // Subtract days to get Monday
  }

  // Function to calculate the end of the week (Sunday)
  DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    final sunday = date.add(Duration(days: 7 - weekday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
  }

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: ValueListenableBuilder<DateTime>(
          valueListenable: widget.controller.focusedDayNotifier,
          builder: (context, focusedDay, _) {
            final currentMonth = DateFormat('MMMM yyyy').format(focusedDay);
            return Text(currentMonth);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<DateTime>(
                valueListenable: widget.controller.focusedDayNotifier,
                builder: (context, focusedDay, _) {
                  final startOfWeekDate = startOfWeek(focusedDay);  // Calculate start of the week
                  final endOfWeekDate = endOfWeek(focusedDay);


                  return Column(
                    children: [
                      Row(
                        children: List.generate(7, (index) {
                          final day = startOfWeekDate.add(Duration(days: index));
                          return Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    daysOfWeek[index],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      Expanded(
                        child: StreamBuilder<List<Event>>(
                          stream: Event.getEventsForDateStream(startOfWeekDate, endOfWeekDate), // Pass today's date (or any date within the week)
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }

                            final events = snapshot.data ?? [];
                            return Row(
                              children: List.generate(7, (index) {
                                final day = startOfWeekDate.add(Duration(days: index));
                                final dayEvents = events.where((event) => _isSameDate(event.date, day)).toList();
                                final address = _selectedAddresses[day] ?? 'No Property Selected';

                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(4.0),
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Container(
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Events Widget
                                          if (dayEvents.isEmpty)
                                            Text(
                                              'No Events',
                                              style: const TextStyle(fontSize: 12.0),
                                            ),
                                          for (final event in dayEvents)
                                            GestureDetector(
                                              onTap: () {
                                                // Show options to delete or update the event
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Event Options'),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          leading: const Icon(Icons.edit),
                                                          title: const Text('Update Event'),
                                                          onTap: () {
                                                            Navigator.pop(context); // Close the dialog
                                                            _updateEvent(event); // Open the update dialog

                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.delete, color: Colors.red),
                                                          title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
                                                          onTap: () async {
                                                            await _deleteEvent(event); // Delete the event
                                                            Navigator.pop(context); // Close the dialog
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: double.infinity, // Make the event container take full width
                                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                                padding: const EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          // Time Range
                                                          Text(
                                                            DateFormat('h:mm a').format(event.startTime), // 12-hour format with AM/PM
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4.0),
                                                          // Event Title
                                                          Text(
                                                            event.title,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          Text(
                                                            event.address ?? 'No Location',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                          // Event Description (if any)
                                                          if (event.description != null && event.description!.isNotEmpty)
                                                            Text(
                                                              event.description!,
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 8.0),
                                          // Add Event Button (Updated)
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => EventDialog(
                                                  date: day,
                                                  onSave: () {
                                                    setState(() {}); // Trigger refresh after adding event
                                                  },
                                                  selectedAddresses: _selectedAddresses,
                                                ),
                                              );
                                            },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  "Add Tasks",
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    final date1Only = DateTime(date1.year, date1.month, date1.day); // Strips the time part
    final date2Only = DateTime(date2.year, date2.month, date2.day); // Strips the time part
    return date1Only.isAtSameMomentAs(date2Only); // Compares the date only
  }

  Future<void> _deleteEvent(Event event) async {

    Navigator.pop(context);

    try {
      await Event.removeEvent(event);  // Call removeEvent from the Event class
      setState(() {});  // Refresh the UI after deletion
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting event: $e'),
      ));
    }
  }

  Future<void> _updateEvent(Event event) async {
    // Show a dialog to update the event
    await showDialog(
      context: context,
      builder: (context) => EventDialog(
        date: event.date,
        onSave: () {
          setState(() {}); // Refresh the UI after updating the event
        },
        selectedAddresses: _selectedAddresses,
        event: event, // Pass the event to pre-fill the dialog
      ),
    );
  }
}