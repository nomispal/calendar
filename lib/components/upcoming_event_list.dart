import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class UpcomingEventsList extends StatelessWidget {
  const UpcomingEventsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final nextWeek = today.add(const Duration(days: 7));
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Text(
    "Upcoming Events",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    ),
     SizedBox(
      height: MediaQuery.of(context).size.height * 0.30, // 30% of screen height
      child: StreamBuilder<List<Event>>(
        stream: Event.getEventsForDateStream(today, nextWeek),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text("No upcoming events."));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('EEE, MMM d').format(event.date)} • ${DateFormat('h:mm a').format(event.startTime)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (event.address != null && event.address!.isNotEmpty) // Check if address exists
                        Text(
                          event.address!,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.event, size: 20, color: Colors.blue),
                ),
              );
            },
          );
        },
      ),
    )]);
  }
}
