import 'dart:convert';
import 'package:btl_nhom_15/model/lunar_event.dart';
import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatelessWidget {
  final LunarEvent event;
  const DetailScreen({super.key, required this.event});

  static const Color _primary = Color(0xFF1A3A4A);

  Color get _eventColor {
    try {
      return Color(int.parse('FF${event.color.replaceAll('#', '')}', radix: 16));
    } catch (_) { return _primary; }
  }

  String _getLunarDate() {
    try {
      final d = DateTime.parse(event.date);
      final lunar = Solar.fromYmd(d.year, d.month, d.day).getLunar();
      return '${lunar.getDay()}/${lunar.getMonth()}/${lunar.getYear()} âm lịch';
    } catch (_) { return ''; }
  }

  String _repeatLabel() {
    switch (event.repeatType) {
      case 'daily':   return 'Mỗi ngày';
      case 'weekly':  return 'Mỗi tuần';
      case 'monthly': return 'Mỗi tháng';
      case 'yearly':  return 'Mỗi năm';
      default:        return 'Không lặp lại';
    }
  }

  List<String> _reminderLabels() {
    try {
      final List decoded = jsonDecode(event.reminders);
      return decoded.map<String>((m) {
        final int minutes = m as int;
        if (minutes < 60)   return '$minutes phút trước';
        if (minutes < 1440) return '${minutes ~/ 60} giờ trước';
        return '${minutes ~/ 1440} ngày trước';
      }).toList();
    } catch (_) { return ['1 ngày trước']; }
  }

  String _weekdayName(DateTime d) {
    const names = ['','Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy','Chủ Nhật'];
    return names[d.weekday];
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(event.date);
    final weekday = d != null ? _weekdayName(d) : '';
    final lunarStr = _getLunarDate();
    final reminders = _reminderLabels();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0, backgroundColor: _primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết sự kiện',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => AddEditScreen(event: event))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ── Hero card ──────────────────────────────────────────────────
          Hero(
            tag: 'event_card_${event.id}',
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _eventColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Badges
                  Row(children: [
                    _badge(event.isLunar == 1 ? '🌙 Âm lịch' : '☀️ Dương lịch'),
                    if (event.repeatType != 'none') ...[
                      const SizedBox(width: 8),
                      _badge('🔁 ${_repeatLabel()}'),
                    ],
                  ]),
                  const SizedBox(height: 14),
                  // Tiêu đề
                  Text(event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 12),
                  // Ngày
                  if (d != null) _headerRow(Icons.calendar_today,
                    '$weekday, ${d.day}/${d.month}/${d.year}'),
                  if (lunarStr.isNotEmpty) _headerRow(Icons.brightness_2, lunarStr),
                  // Giờ
                  if (event.startTime.isNotEmpty)
                    _headerRow(Icons.access_time,
                      event.endTime.isNotEmpty
                          ? '${event.startTime} – ${event.endTime}'
                          : event.startTime),
                  // Địa điểm
                  if (event.location.isNotEmpty)
                    _headerRow(Icons.location_on_outlined, event.location),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Ghi chú ────────────────────────────────────────────────────
          _infoCard(
            icon: Icons.notes, title: 'Ghi chú',
            content: event.description.isEmpty ? 'Không có ghi chú.' : event.description,
            contentColor: event.description.isEmpty ? Colors.grey[400] : Colors.black87,
          ),

          const SizedBox(height: 10),

          // ── Chi tiết ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [
              _detailRow(Icons.repeat, 'Lặp lại', _repeatLabel(),
                  event.repeatType != 'none' ? Colors.teal : Colors.grey),
              Divider(height: 1, color: Colors.grey.shade100),
              _detailRow(Icons.notifications_outlined, 'Nhắc nhở',
                  reminders.join(', '), _primary),
              if (event.location.isNotEmpty) ...[
                Divider(height: 1, color: Colors.grey.shade100),
                _detailRowWithAction(
                  Icons.location_on_outlined, 'Địa điểm', event.location,
                  actionIcon: Icons.open_in_new,
                  onAction: () async {
                    final q = Uri.encodeComponent(event.location);
                    final uri = Uri.parse('https://maps.google.com/?q=$q');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                ),
              ],
              Divider(height: 1, color: Colors.grey.shade100),
              _detailRow(
                event.isLunar == 1 ? Icons.brightness_2 : Icons.wb_sunny_outlined,
                'Loại lịch',
                event.isLunar == 1 ? 'Âm lịch' : 'Dương lịch',
                event.isLunar == 1 ? const Color(0xFF7F77DD) : _primary,
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _headerRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 13))),
      ]),
    );
  }

  Widget _infoCard({
    required IconData icon, required String title,
    required String content, Color? contentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w600, color: _primary, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 10),
        Text(content, style: TextStyle(fontSize: 15,
            color: contentColor ?? Colors.black87, height: 1.5)),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor))),
      ]),
    );
  }

  Widget _detailRowWithAction(IconData icon, String label, String value,
      {required IconData actionIcon, required VoidCallback onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _primary))),
        const SizedBox(width: 8),
        GestureDetector(onTap: onAction,
          child: Icon(actionIcon, size: 18, color: _primary)),
      ]),
    );
  }
}