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

class _HomeCalendarState extends State<HomeCalendar> with SingleTickerProviderStateMixin {
  final Map<DateTime, String> _selectedAddresses = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: ValueListenableBuilder<DateTime>(
          valueListenable: widget.controller.focusedDayNotifier,
          builder: (context, focusedDay, _) {
            final currentMonth = DateFormat('MMMM yyyy').format(focusedDay);
            return AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.bodyMedium!,
              child: Text(currentMonth),
            );
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.all(8.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                color: Colors.grey[300],
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                                  child: GestureDetector(
                                    onTap: () {
                                      if (dayEvents.isEmpty) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => EventDialog(
                                            date: day,
                                            onSave: () {},
                                            selectedAddresses: _selectedAddresses,
                                          ),
                                        );
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.all(1.0),
                                      padding: const EdgeInsets.all(1.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white),
                                        borderRadius: BorderRadius.circular(8.0),
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
                                            Expanded(
                                              child: ListView(
                                                shrinkWrap: true,
                                                children: [
                                                  for (final event in dayEvents)
                                                    TweenAnimationBuilder<double>(
                                                      duration: const Duration(milliseconds: 200),
                                                      tween: Tween(begin: 0.0, end: 1.0),
                                                      builder: (context, value, child) {
                                                        return Transform.scale(
                                                          scale: 0.9 + (0.1 * value),
                                                          child: MouseRegion(
                                                            cursor: SystemMouseCursors.click,
                                                            onEnter: (_) => _animationController.forward(),
                                                            onExit: (_) => _animationController.reverse(),
                                                            child: AnimatedContainer(
                                                              duration: const Duration(milliseconds: 200),
                                                              width: double.infinity,
                                                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                                                              padding: const EdgeInsets.all(8.0),
                                                              decoration: BoxDecoration(
                                                                color: _eventTypeColor[event.type?.toLowerCase()] ?? Colors.grey.shade300,
                                                                borderRadius: BorderRadius.circular(8.0),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors.black.withOpacity(0.1),
                                                                    spreadRadius: 1,
                                                                    blurRadius: 3,
                                                                    offset: const Offset(0, 2),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: _buildEventContent(event),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8.0),
                                            _buildAddTaskButton(day),
                                          ],
                                        ),
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

  Widget _buildEventContent(Event event) {
    return GestureDetector(
      onTap: () => _showEventOptions(event),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('h:mm a').format(event.startTime),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  event.address ?? 'No Location',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(
                    event.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskButton(DateTime day) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showAddEventDialog(day),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween(begin: 1.0, end: 1.05),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                margin: const EdgeInsets.all(2.0),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Add Tasks",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEventOptions(Event event) {
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
              title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _deleteEvent(event);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog(DateTime day) {
    showDialog(
      context: context,
      builder: (context) => EventDialog(
        date: day,
        onSave: () {},
        selectedAddresses: _selectedAddresses,
      ),
    );
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _deleteEvent(Event event) async {
    try {
      await Event.removeEvent(event);
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
        onSave: () {},
        selectedAddresses: _selectedAddresses,
        event: event,
      ),
    );
  }
}