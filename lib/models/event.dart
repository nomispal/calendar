import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  DateTime get reminderDate {
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
    return adjustedDate.subtract(Duration(
      days: reminderDays,
      minutes: reminderMinutes,
    ));
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

  static DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;

    // Handle year wrap-around
    newYear += (newMonth - 1) ~/ 12;
    newMonth = (newMonth - 1) % 12 + 1;

    // Get last day of new month
    final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0);
    final int maxDay = lastDayOfNewMonth.day;
    final int newDay = date.day > maxDay ? maxDay : date.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static Stream<List<Event>> getEventsForDateStream(DateTime start, DateTime end) {
    return FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final events = <Event>[];
      for (final doc in snapshot.docs) {
        final event = Event.fromFirestore(doc);

        // Add original event if in range
        if (event.date.isAfter(start.subtract(const Duration(days: 1))) &&
            event.date.isBefore(end.add(const Duration(days: 1)))) {
          events.add(event);
        }

        // Handle recurring events
        if (event.isRecurring) {
          DateTime nextDate = event.date;
          int safetyCounter = 0;

          while (nextDate.isBefore(end) && safetyCounter < 1000) {
            // Handle different recurrence types
            if (event.recurrenceInterval == 0) { // Custom
              nextDate = nextDate.add(Duration(
                days: event.recurrenceDays,
                minutes: event.recurrenceMinutes,
              ));
            } else { // Preset intervals
              nextDate = nextDate.add(Duration(
                days: event.recurrenceInterval!,
                minutes: event.recurrenceMinutes,
              ));
            }

            // Check if within date range
            if (nextDate.isAfter(start) && nextDate.isBefore(end)) {
              events.add(event.copyWith(
                id: '${event.id}_${nextDate.millisecondsSinceEpoch}',
                date: nextDate,
                startTime: nextDate,
              ));
            }

            safetyCounter++;
          }
        }
      }
      return events;
    });
  }}