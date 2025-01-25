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

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<DateTime>(
          valueListenable: widget.controller.focusedDayNotifier,
          builder: (context, focusedDay, _) {
            final currentMonth = DateFormat('MMMM yyyy').format(focusedDay);
            return Text(currentMonth);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<DateTime>(
              valueListenable: widget.controller.focusedDayNotifier,
              builder: (context, focusedDay, _) {
                final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
                return Column(
                  children: [
                    Row(
                      children: List.generate(7, (index) {
                        final day = startOfWeek.add(Duration(days: index));
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
                      child: FutureBuilder<List<Event>>(
                        future: Event.getEventsForDate(focusedDay),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          final events = snapshot.data ?? [];
                          return Row(
                            children: List.generate(7, (index) {
                              final day = startOfWeek.add(Duration(days: index));
                              final dayEvents = events.where((event) => _isSameDate(event.date, day)).toList();
                              final address = _selectedAddresses[day] ?? 'No Address Selected';

                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(4.0),
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Address: $address', style: const TextStyle(fontSize: 12.0)),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final selectedAddress = await showDialog<String>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AddressAutocomplete(
                                                onAddressSelected: (address) {
                                                  Navigator.of(context).pop(address);
                                                },
                                              );
                                            },
                                          );
                                          if (selectedAddress != null) {
                                            setState(() {
                                              _selectedAddresses[day] = selectedAddress;
                                            });
                                          }
                                        },
                                        child: const Text('Add Location', style: TextStyle(fontSize: 13)),
                                      ),
                                      const SizedBox(height: 8.0),
                                      ...dayEvents.map((event) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${event.title}\n(${TimeOfDay.fromDateTime(event.date).format(context)})',
                                                softWrap: true,
                                                style: const TextStyle(fontSize: 12.0),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                setState(() {
                                                  Event.removeEvent(event);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      )),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => EventDialog(
                                              date: day,
                                              onSave: () => setState(() {}),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                          child: const Text(
                                            'Add Event',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
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
    );
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}
