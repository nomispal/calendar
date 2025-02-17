import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/calendar_controller.dart';
import './event_dialog.dart';
import '../models/event.dart';

// Add color map and contrast function outside the class
Map<String, Color> _eventTypeColor = {
  'meeting': Colors.blue[200]!,
  'personal': Colors.green[200]!,
  'work': Colors.orange[200]!,
  'social': Colors.purple[200]!,
  'other': Colors.teal[200]!,
};


class HomeCalendar extends StatefulWidget {
  final CalendarController controller;

  const HomeCalendar({required this.controller, super.key});

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
                                                                color: _eventTypeColor[event.type.toLowerCase()] ?? Colors.grey.shade300,
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
      onTap: () => showEventOptions(event),
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
                if (event.isRecurring)
                  Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.repeat,
                        size: 16,
                        color: Colors.blue[700],
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
                if (event.reminderPeriodMonths > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          size: 10,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${event.reminderPeriodMonths} month reminder',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  )
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

  void showEventOptions(Event event) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
        elevation: 10,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_note,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Task Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Edit Option
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 1.0, end: 1.0),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                          _updateEvent(event);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Edit Task',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Delete Option
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 1.0, end: 1.0),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade100.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          Navigator.pop(context);
                          await _deleteEvent(event);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Delete Task',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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