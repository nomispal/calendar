import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../services/notification_service.dart';

class Event {
  final String id;
  final String title;
  final DateTime date;
  final DateTime startTime;
  final String? description;
  final String? address;
  final String type;
  final bool isRecurring;
  final int? recurrenceInterval;
  final int reminderPeriodMonths;
  final int reminderDays;
  final int reminderMinutes;
  final int recurrenceDays;
  final int recurrenceMinutes;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    this.description,
    this.address,
    required this.type,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.reminderPeriodMonths = 0,
    this.reminderDays = 0,
    this.reminderMinutes = 0,
    this.recurrenceDays = 0,
    this.recurrenceMinutes = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'description': description,
      'address': address,
      'type': type,
      'isRecurring': isRecurring,
      'recurrenceInterval': recurrenceInterval,
      'reminderPeriodMonths': reminderPeriodMonths,
      'reminderDays': reminderDays,
      'reminderMinutes': reminderMinutes,
      'recurrenceDays': recurrenceDays,
      'recurrenceMinutes': recurrenceMinutes,
    };
  }

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      description: data['description'],
      address: data['address'],
      type: data['type'] ?? 'other',
      isRecurring: data['isRecurring'] ?? false,
      recurrenceInterval: data['recurrenceInterval'],
      reminderPeriodMonths: data['reminderPeriodMonths'] ?? 0,
      reminderDays: data['reminderDays'] ?? 0,
      reminderMinutes: data['reminderMinutes'] ?? 0,
      recurrenceDays: data['recurrenceDays'] ?? 0,
      recurrenceMinutes: data['recurrenceMinutes'] ?? 0,
    );
  }

  /// Computes the reminder date by subtracting the reminder offsets.
  DateTime get reminderDate {
    // Adjust the date by the number of months specified.
    // The DateTime constructor handles out-of-range months (e.g., month 0 becomes December of previous year).
    DateTime adjustedDate = DateTime(
      date.year,
      date.month + reminderPeriodMonths,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
    // Then subtract the days and minutes.
    return adjustedDate.subtract(Duration(days: reminderDays, minutes: reminderMinutes));
  }



  static Future<void> addEvent(Event event) async {
    await FirebaseFirestore.instance.collection('events').add(event.toFirestore());
  }

  static Future<void> updateEvent(Event event) async {
    await FirebaseFirestore.instance.collection('events').doc(event.id).update(event.toFirestore());
  }

  static Future<void> removeEvent(Event event) async {
    await FirebaseFirestore.instance.collection('events').doc(event.id).delete();
  }

  Event copyWith({
    String? id,
    String? title,
    DateTime? date,
    DateTime? startTime,
    String? description,
    String? address,
    String? type,
    bool? isRecurring,
    int? recurrenceInterval,
    int? reminderPeriodMonths,
    int? reminderDays,
    int? reminderMinutes,
    int? recurrenceDays,
    int? recurrenceMinutes,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      description: description ?? this.description,
      address: address ?? this.address,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      reminderPeriodMonths: reminderPeriodMonths ?? this.reminderPeriodMonths,
      reminderDays: reminderDays ?? this.reminderDays,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      recurrenceMinutes: recurrenceMinutes ?? this.recurrenceMinutes,
    );
  }

  static Stream<List<Event>> getAllEventsStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  static Stream<List<Event>> getEventsForDateStream(DateTime start, DateTime end) {
    return FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .map((snapshot) {
      List<Event> events = [];
      for (var doc in snapshot.docs) {
        Event event = Event.fromFirestore(doc);
        if (event.date.isAfter(start.subtract(const Duration(days: 1))) &&
            event.date.isBefore(end.add(const Duration(days: 1)))) {
          events.add(event);
        }
        if (event.isRecurring && event.recurrenceInterval != null) {
          DateTime nextDate = event.date;
          while (nextDate.isBefore(end)) {
            nextDate = DateTime(
              nextDate.year,
              nextDate.month + event.recurrenceInterval!,
              nextDate.day + event.recurrenceDays,
              nextDate.hour,
              nextDate.minute + event.recurrenceMinutes,
            );
            if (nextDate.isAfter(start) && nextDate.isBefore(end)) {
              events.add(event.copyWith(
                id: '${event.id}_${nextDate.millisecondsSinceEpoch}',
                date: nextDate,
                startTime: nextDate,
              ));
            }
          }
        }
      }
      return events;
    });
  }
}