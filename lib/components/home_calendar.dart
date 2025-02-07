import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/calendar_controller.dart';
import './event_dialog.dart';
import '../models/event.dart';
import '../components/address_search_field.dart';

// Add color map and contrast function outside the class
 Map<String, Color> _eventTypeColor = {
   'meeting': Colors.blue[200]!,
   'personal': Colors.green[200]!,
   'work': Colors.orange[200]!,
   'social': Colors.purple[200]!,
   'other': Colors.teal[200]!,
 };

Color _getContrastColor(Color background) {
  return background.computeLuminance() > 0.4 ? Colors.black87 : Colors.black;
}

class HomeCalendar extends StatefulWidget {
  final CalendarController controller;

  const HomeCalendar({required this.controller, Key? key}) : super(key: key);

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  final Map<DateTime, String> _selectedAddresses = {};

  DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    final sunday = date.add(Duration(days: 7 - weekday));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
  }

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
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
                  final startOfWeekDate = startOfWeek(focusedDay);
                  final endOfWeekDate = endOfWeek(focusedDay);

                  return Column(
                    children: [
                      Row(
                        children: List.generate(7, (index) {
                          final day = startOfWeekDate.add(Duration(days: index));
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.grey[300],
                                border: const Border(
                                  bottom: BorderSide(color: Colors.grey),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    daysOfWeek[index],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 12.0),
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
                          stream: Event.getEventsForDateStream(startOfWeekDate, endOfWeekDate),
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
                                    margin: const EdgeInsets.all(1.0),
                                    padding: const EdgeInsets.all(1.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(4.0),
                                      padding: const EdgeInsets.all(2.0),
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (dayEvents.isEmpty)
                                            Text(
                                              'No Events',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.grey.shade600,

                                              ),
                                            ),
                                          for (final event in dayEvents)
                                            GestureDetector(
                                              onTap: () {
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
                                                            Navigator.pop(context);
                                                            _updateEvent(event);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(Icons.delete, color: Colors.red),
                                                          title: const Text('Delete Event',
                                                              style: TextStyle(color: Colors.red)),
                                                          onTap: () async {
                                                            await _deleteEvent(event);
                                                            Navigator.pop(context);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                                padding: const EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  color: _eventTypeColor[event.type?.toLowerCase()]
                                                      ?? Colors.grey.shade300,
                                                  borderRadius: BorderRadius.circular(8.0),

                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            DateFormat('h:mm a').format(event.startTime),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: _getContrastColor(
                                                                  _eventTypeColor[event.type?.toLowerCase()]
                                                                      ?? Colors.grey.shade300
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4.0),
                                                          Text(
                                                            event.title,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: _getContrastColor(
                                                                  _eventTypeColor[event.type?.toLowerCase()]?.withOpacity(0.2)
                                                                      ?? Colors.grey.shade300
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            event.address ?? 'No Location',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: _getContrastColor(
                                                                  _eventTypeColor[event.type?.toLowerCase()]?.withOpacity(0.2)
                                                                      ?? Colors.grey.shade300
                                                              ).withOpacity(0.8),
                                                            ),
                                                          ),
                                                          if (event.description != null && event.description!.isNotEmpty)
                                                            Text(
                                                              event.description!,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: _getContrastColor(
                                                                    _eventTypeColor[event.type?.toLowerCase()]?.withOpacity(0.2)
                                                                        ?? Colors.grey.shade300
                                                                ).withOpacity(0.6),
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
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => EventDialog(
                                                  date: day,
                                                  onSave: () => setState(() {}),
                                                  selectedAddresses: _selectedAddresses,
                                                ),
                                              );
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.all(2.0),
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
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _deleteEvent(Event event) async {
    Navigator.pop(context);
    try {
      await Event.removeEvent(event);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error deleting event: $e'),
      ));
    }
  }

  Future<void> _updateEvent(Event event) async {
    await showDialog(
      context: context,
      builder: (context) => EventDialog(
        date: event.date,
        onSave: () => setState(() {}),
        selectedAddresses: _selectedAddresses,
        event: event,
      ),
    );
  }
}