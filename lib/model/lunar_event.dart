import 'package:flutter/material.dart';

class LunarEvent {
  int? id;
  String title;
  String description;
  String date;
  int isLunar;
  int isYearly;
  String startTime; // "HH:mm" hoặc "" nếu cả ngày
  String endTime; // "HH:mm" hoặc ""
  String location; // địa điểm
  String color; // mã màu hex VD: "#E24B4A"
  String repeatType; // "none" | "daily" | "weekly" | "monthly" | "yearly"
  String reminders; // JSON list phút nhắc trước: "[5,60,1440]"

  LunarEvent({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.isLunar = 0,
    this.isYearly = 0,
    this.startTime = '',
    this.endTime = '',
    this.location = '',
    this.color = '#1A3A4A',
    this.repeatType = 'none',
    this.reminders = '[1440]',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'isLunar': isLunar,
      'isYearly': isYearly,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'color': color,
      'repeatType': repeatType,
      'reminders': reminders,
    };
  }

  factory LunarEvent.fromMap(Map<String, dynamic> map) {
    return LunarEvent(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      isLunar: map['isLunar'] ?? 0,
      isYearly: map['isYearly'] ?? 0,
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      location: map['location'] ?? '',
      color: map['color'] ?? '#1A3A4A',
      repeatType: map['repeatType'] ?? 'none',
      reminders: map['reminders'] ?? '[1440]',
    );
  }

  LunarEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? date,
    int? isLunar,
    int? isYearly,
    String? startTime,
    String? endTime,
    String? location,
    String? color,
    String? repeatType,
    String? reminders,
  }) {
    return LunarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isLunar: isLunar ?? this.isLunar,
      isYearly: isYearly ?? this.isYearly,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      color: color ?? this.color,
      repeatType: repeatType ?? this.repeatType,
      reminders: reminders ?? this.reminders,
    );
  }

  // Màu sự kiện dạng Color object
  Color get eventColor {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1A3A4A);
    }
  }
}
