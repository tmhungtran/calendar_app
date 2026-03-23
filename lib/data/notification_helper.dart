import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:btl_nhom_15/model/lunar_event.dart';

class NotificationHelper {
  static final NotificationHelper instance = NotificationHelper._init();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  NotificationHelper._init();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Lên lịch nhiều nhắc nhở cho 1 sự kiện
  Future<void> scheduleMultipleReminders(
    LunarEvent event,
    List<int> minutesBefore,
  ) async {
    if (event.id == null) return;
    // Hủy hết cũ trước
    await cancelReminder(event.id!);

    for (int i = 0; i < minutesBefore.length; i++) {
      await _scheduleOne(event, minutesBefore[i], slotIndex: i);
    }
  }

  Future<void> _scheduleOne(
    LunarEvent event,
    int minutesBefore, {
    int slotIndex = 0,
  }) async {
    if (event.id == null) return;

    // Tính thời điểm sự kiện bắt đầu
    final dateParts = event.date.split('-');
    int year = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int day = int.parse(dateParts[2]);
    int hour = 8, minute = 0;

    if (event.startTime.isNotEmpty) {
      final timeParts = event.startTime.split(':');
      hour = int.parse(timeParts[0]);
      minute = int.parse(timeParts[1]);
    }

    final eventTime = tz.TZDateTime(tz.local, year, month, day, hour, minute);
    final scheduleTime = eventTime.subtract(Duration(minutes: minutesBefore));

    if (scheduleTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    // Dùng id = eventId * 100 + slotIndex để tránh trùng
    final notifId = event.id! * 100 + slotIndex;

    String timeLabel;
    if (minutesBefore < 60) {
      timeLabel = '$minutesBefore phút nữa';
    } else if (minutesBefore < 1440) {
      timeLabel = '${minutesBefore ~/ 60} giờ nữa';
    } else {
      timeLabel = '${minutesBefore ~/ 1440} ngày nữa';
    }

    await _plugin.zonedSchedule(
      notifId,
      '⏰ ${event.title}',
      'Còn $timeLabel${event.location.isNotEmpty ? ' · ${event.location}' : ''}',
      scheduleTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminder_$slotIndex',
          'Nhắc nhở sự kiện',
          channelDescription: 'Thông báo nhắc nhở sự kiện',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1A3A4A),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Hủy tất cả nhắc nhở của 1 sự kiện (tối đa 10 slot)
  Future<void> cancelReminder(int eventId) async {
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(eventId * 100 + i);
    }
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();
}
