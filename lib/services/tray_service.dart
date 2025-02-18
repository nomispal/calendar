// tray_service.dart
import 'dart:io';

import 'package:system_tray/system_tray.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrayService {
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  bool _hasNotifications = false;

  Future<void> initialize() async {
    await _initSystemTray();
    _startReminderListener();
  }

  Future<void> _initSystemTray() async {
    await _systemTray.initSystemTray(
      iconPath: 'assets/app_icon.ico',
      toolTip: ' Reminders',
    );

    await _menu.buildFrom([
    MenuItemLabel(
    label: 'Show Reminders',
    onClicked: (_) => _handleShowReminders(),
    ),
    MenuItemLabel(
    label: 'Exit',
    onClicked: (_) => exit(0),
    )]);

    await _systemTray.setContextMenu(_menu);
    _systemTray.registerSystemTrayEventHandler(_handleTrayEvent);
    }

  void _startReminderListener() {
    FirebaseFirestore.instance
        .collection('events')
        .snapshots()
        .listen((snapshot) {
      final hasReminders = _checkForTodayReminders(snapshot.docs);
      if (hasReminders != _hasNotifications) {
        _hasNotifications = hasReminders;
        _updateTrayIcon();
      }
    });
  }

  bool _checkForTodayReminders(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final eventDate = (data['date'] as Timestamp).toDate();
      final reminderDays = data['reminderDays'] as int? ?? 0;

      final reminderDate = eventDate.subtract(Duration(days: reminderDays));
      return _isSameDate(reminderDate, today);
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _updateTrayIcon() async {
    final iconPath = _hasNotifications
        ? 'assets/app_icon_alert.ico'
        : 'assets/app_icon.ico';

    await _systemTray.setImage(iconPath); // Changed to setImage
  }

  void _handleTrayEvent(String eventName) {
    if (eventName == kSystemTrayEventClick) {
      _handleShowReminders();
    }

  }


  void _handleShowReminders() {
    // Your code to show reminders
    _hasNotifications = false;
    _updateTrayIcon();
  }
}