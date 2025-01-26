import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String title;
  final DateTime date;
  final String id; // Unique identifier for Firestore
  final String? address; // Optional address field

  Event({required this.title, required this.date, required this.id, this.address});

  // Convert Event to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'address': address,
    };
  }

  // Create an Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'],
      date: (data['date'] as Timestamp).toDate(),
      address: data['address'],
    );
  }

  // Add event to Firestore
  static Future<void> addEvent(Event event) async {
    final docRef = FirebaseFirestore.instance.collection('events').doc();
    await docRef.set(event.toMap());
  }

  // Get events for a specific date from Firestore
  static Future<List<Event>> getEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }

  // Remove event from Firestore
  static Future<void> removeEvent(Event event) async {
    await FirebaseFirestore.instance.collection('events').doc(event.id).delete();
  }
}
