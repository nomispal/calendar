import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class EventFilterScreen extends StatefulWidget {
  @override
  _EventFilterScreenState createState() => _EventFilterScreenState();
}

class _EventFilterScreenState extends State<EventFilterScreen> {
  String eventType = '';
  String address = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Filter Tasks"),
        backgroundColor: Colors.grey[200],
      ),
      body: Container(
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Event Type",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                onChanged: (value) {
                  setState(() {
                    eventType = value;
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (value) {
                  setState(() {
                    address = value;
                  });
                },
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Event>>(
                  stream: _filterEvents(eventType, address),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final events = snapshot.data!;
                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          color: Colors.white,
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<List<Event>> _filterEvents(String type, String addr) {
    Query query = FirebaseFirestore.instance.collection('events');

    if (type.isNotEmpty) {
      query = query.where('title', isGreaterThanOrEqualTo: type).where('title', isLessThan: type + 'z');
    }
    if (addr.isNotEmpty) {
      query = query.where('address', isGreaterThanOrEqualTo: addr).where('address', isLessThan: addr + 'z');
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }
}
