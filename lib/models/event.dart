import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id; // Firestore document ID
  final String title;
  final DateTime date;
  final DateTime startTime;
  final String? address;
  final String? description;
  final String type; // Add this field

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    this.address,
    this.description,
    required this.type, // Add this to the constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'address': address,
      'description': description,
      'type': type, // Include type in the map
    };
  }

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      address: data['address'],
      description: data['description'],
      type: data['type'] ?? 'other', // Default to 'other' if type is not specified
    );
  }

  static Stream<List<Event>> getEventsForDateStream(DateTime start, DateTime end) {
    return FirebaseFirestore.instance
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  static Future<void> addEvent(Event event) async {
    await FirebaseFirestore.instance.collection('events').add(event.toMap());
  }

  static Future<void> updateEvent(Event event) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(event.id) // Use document ID here
        .update(event.toMap());
  }

  static Future<void> removeEvent(Event event) async {
    await FirebaseFirestore.instance.collection('events').doc(event.id).delete();
  }

  // Get all events stream
  static Stream<List<Event>> getAllEventsStream() {
    return FirebaseFirestore.instance
        .collection('events') // Firestore collection name
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }
}