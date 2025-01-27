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
      'date': Timestamp.fromDate(date), // Store date as Firestore Timestamp
      'address': address,
    };
  }

  // Create an Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id, // Use the document ID as the event ID
      title: data['title'] ?? 'No Title', // Default to empty string if null
      date: (data['date'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      address: data['address'], // Optional field
    );
  }

  // Static method to stream events for a specific week range
  static Stream<List<Event>> getEventsForDateStream(DateTime startOfWeek, DateTime endOfWeek) {
    return FirebaseFirestore.instance
        .collection('events') // Firestore collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek)) // Compare as timestamp
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek)) // Compare as timestamp
        .orderBy('date') // Order events by date
        .snapshots() // Real-time listener
        .map((snapshot) => snapshot.docs
        .map((doc) => Event.fromFirestore(doc)) // Convert each document to Event
        .toList());
  }

  // Add an event to Firestore
  static Future<void> addEvent(Event event) async {
    try {
      // Add a new document with an auto-generated ID
      await FirebaseFirestore.instance.collection('events').add(event.toMap());
    } catch (e) {
      print("Error adding event: $e");
    }
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
    try {
      await FirebaseFirestore.instance.collection('events').doc(event.id).delete();
    } catch (e) {
      print("Error removing event: $e");
    }
  }
}