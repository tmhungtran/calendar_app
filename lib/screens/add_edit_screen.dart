import 'dart:convert';
import 'package:btl_nhom_15/model/lunar_event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/event_provider.dart';
import '../data/notification_helper.dart';

class AddEditScreen extends StatefulWidget {
  final LunarEvent? event;
  const AddEditScreen({super.key, this.event});
  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLunar = false;
  String _repeatType = 'none';
  String _color = '#1A3A4A';
  List<int> _reminders = [1440];

  static const Color _primary = Color(0xFF1A3A4A);

  static const List<Map<String, dynamic>> _colorOptions = [
    {'hex': '#1A3A4A', 'name': 'Xanh than'},
    {'hex': '#E24B4A', 'name': 'Đỏ'},
    {'hex': '#1D9E75', 'name': 'Xanh lá'},
    {'hex': '#BA7517', 'name': 'Cam'},
    {'hex': '#7F77DD', 'name': 'Tím'},
    {'hex': '#D4537E', 'name': 'Hồng'},
    {'hex': '#378ADD', 'name': 'Xanh dương'},
    {'hex': '#888780', 'name': 'Xám'},
  ];

  static const List<Map<String, dynamic>> _reminderOptions = [
    {'minutes': 5,    'label': '5 phút trước'},
    {'minutes': 15,   'label': '15 phút trước'},
    {'minutes': 30,   'label': '30 phút trước'},
    {'minutes': 60,   'label': '1 giờ trước'},
    {'minutes': 120,  'label': '2 giờ trước'},
    {'minutes': 1440, 'label': '1 ngày trước'},
    {'minutes': 2880, 'label': '2 ngày trước'},
  ];

  static const List<Map<String, dynamic>> _repeatOptions = [
    {'value': 'none',    'label': 'Không lặp',  'icon': Icons.block},
    {'value': 'daily',   'label': 'Mỗi ngày',   'icon': Icons.today},
    {'value': 'weekly',  'label': 'Mỗi tuần',   'icon': Icons.view_week},
    {'value': 'monthly', 'label': 'Mỗi tháng',  'icon': Icons.calendar_view_month},
    {'value': 'yearly',  'label': 'Mỗi năm',    'icon': Icons.event_repeat},
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl    = TextEditingController(text: e?.title ?? '');
    _descCtrl     = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    if (e != null) {
      if (e.date.isNotEmpty) _selectedDate = DateTime.parse(e.date);
      _isLunar    = e.isLunar == 1;
      _repeatType = e.repeatType.isEmpty ? 'none' : e.repeatType;
      _color      = e.color.isEmpty ? '#1A3A4A' : e.color;
      if (e.startTime.isNotEmpty) {
        final p = e.startTime.split(':');
        _startTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      if (e.endTime.isNotEmpty) {
        final p = e.endTime.split(':');
        _endTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      try {
        final d = jsonDecode(e.reminders);
        if (d is List) _reminders = d.cast<int>();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Color _hexColor(String hex) {
    try { return Color(int.parse('FF${hex.replaceAll('#','')}', radix: 16)); }
    catch (_) { return _primary; }
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime(1900), lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _primary, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (p != null) setState(() => _selectedDate = p);
  }

  Future<void> _pickTime(bool isStart) async {
    final p = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: _primary, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (p != null) setState(() { if (isStart) _startTime = p; else _endTime = p; });
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime != null && _endTime != null) {
      final s = _startTime!.hour * 60 + _startTime!.minute;
      final e = _endTime!.hour * 60 + _endTime!.minute;
      if (e <= s) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Giờ kết thúc phải sau giờ bắt đầu!'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
    }
    final newEvent = LunarEvent(
      id: widget.event?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      date: _formatDate(_selectedDate),
      isLunar: _isLunar ? 1 : 0,
      isYearly: _repeatType == 'yearly' ? 1 : 0,
      startTime: _startTime != null ? _timeStr(_startTime!) : '',
      endTime: _endTime != null ? _timeStr(_endTime!) : '',
      location: _locationCtrl.text.trim(),
      color: _color,
      repeatType: _repeatType,
      reminders: jsonEncode(_reminders),
    );
    final provider = Provider.of<EventProvider>(context, listen: false);
    if (widget.event?.id == null) {
      await provider.addEvent(newEvent);
    } else {
      await provider.updateEvent(newEvent);
      await NotificationHelper.instance.cancelReminder(widget.event!.id!);
    }
    final saved = provider.events.lastWhere(
      (e) => e.date == newEvent.date && e.title == newEvent.title,
      orElse: () => newEvent,
    );
    await NotificationHelper.instance.scheduleMultipleReminders(saved, _reminders);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event?.id != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0, backgroundColor: _primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Chỉnh sửa sự kiện' : 'Thêm sự kiện mới',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildColorPicker(),
            const SizedBox(height: 16),
            _sectionLabel('Tiêu đề', Icons.title),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: _inputDeco('Nhập tiêu đề sự kiện...'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Ngày', Icons.calendar_month),
            const SizedBox(height: 8),
            _buildDateRow(),
            const SizedBox(height: 16),
            _sectionLabel('Thời gian bắt đầu – kết thúc', Icons.schedule),
            const SizedBox(height: 8),
            _buildTimeRow(),
            const SizedBox(height: 16),
            _sectionLabel('Địa điểm', Icons.location_on_outlined),
            const SizedBox(height: 8),
            _buildLocationRow(),
            const SizedBox(height: 16),
            _sectionLabel('Ghi chú', Icons.notes),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: _inputDeco('Thêm ghi chú (tùy chọn)...'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Lặp lại', Icons.repeat),
            const SizedBox(height: 8),
            _buildRepeatPicker(),
            const SizedBox(height: 16),
            _sectionLabel('Nhắc nhở (chọn nhiều)', Icons.notifications_outlined),
            const SizedBox(height: 8),
            _buildReminderPicker(),
            const SizedBox(height: 16),
            _buildToggleCard(
              icon: Icons.brightness_2_outlined,
              iconColor: const Color(0xFF7F77DD),
              title: 'Sự kiện Âm lịch',
              subtitle: 'Ngày tính theo lịch âm',
              value: _isLunar,
              onChanged: (v) => setState(() => _isLunar = v),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(isEditing ? 'Lưu thay đổi' : 'Tạo sự kiện',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _saveData,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Màu nhãn', Icons.palette_outlined),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10,
          children: _colorOptions.map((c) {
            final selected = _color == c['hex'];
            return GestureDetector(
              onTap: () => setState(() => _color = c['hex']),
              child: Tooltip(
                message: c['name'],
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _hexColor(c['hex']), shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.black54 : Colors.transparent,
                      width: selected ? 2.5 : 2),
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildDateRow() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          const Icon(Icons.event, color: _primary, size: 20),
          const SizedBox(width: 12),
          Text('${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Đổi ngày',
                style: TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }

  Widget _buildTimeRow() {
    return Row(children: [
      Expanded(child: _buildTimeTile(
        label: 'Bắt đầu', time: _startTime, onTap: () => _pickTime(true),
        onClear: _startTime != null ? () => setState(() { _startTime = null; _endTime = null; }) : null,
      )),
      const SizedBox(width: 10),
      Expanded(child: _buildTimeTile(
        label: 'Kết thúc', time: _endTime, onTap: () => _pickTime(false),
        onClear: _endTime != null ? () => setState(() => _endTime = null) : null,
        enabled: _startTime != null,
      )),
    ]);
  }

  Widget _buildTimeTile({
    required String label, required TimeOfDay? time,
    required VoidCallback onTap, VoidCallback? onClear, bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(Icons.access_time, color: enabled ? _primary : Colors.grey[400], size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(time != null ? _timeStr(time) : 'Chọn giờ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: time != null ? _primary : Colors.grey[400])),
          ])),
          if (onClear != null)
            GestureDetector(onTap: onClear,
                child: Icon(Icons.close, size: 16, color: Colors.grey[400])),
        ]),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(children: [
      Expanded(child: TextFormField(
        controller: _locationCtrl,
        style: const TextStyle(fontSize: 15),
        decoration: _inputDeco('Nhập địa điểm...'),
        onChanged: (_) => setState(() {}),
      )),
      if (_locationCtrl.text.isNotEmpty) ...[
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final q = Uri.encodeComponent(_locationCtrl.text);
            final uri = Uri.parse('https://maps.google.com/?q=$q');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
          child: Container(
            width: 46, height: 50,
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.map_outlined, color: Colors.white, size: 22),
          ),
        ),
      ],
    ]);
  }

  Widget _buildRepeatPicker() {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: _repeatOptions.asMap().entries.map((entry) {
        final i = entry.key; final opt = entry.value;
        final selected = _repeatType == opt['value'];
        return Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _repeatType = opt['value']),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(children: [
                Icon(opt['icon'] as IconData, size: 20,
                    color: selected ? _primary : Colors.grey[400]),
                const SizedBox(width: 12),
                Text(opt['label'], style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? _primary : Colors.black87)),
                const Spacer(),
                if (selected) const Icon(Icons.check, color: _primary, size: 18),
              ]),
            ),
          ),
          if (i < _repeatOptions.length - 1)
            Divider(height: 1, color: Colors.grey.shade100),
        ]);
      }).toList()),
    );
  }

  Widget _buildReminderPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: _reminderOptions.map((opt) {
        final minutes = opt['minutes'] as int;
        final selected = _reminders.contains(minutes);
        return InkWell(
          onTap: () => setState(() {
            if (selected) { _reminders.remove(minutes); }
            else { _reminders.add(minutes); _reminders.sort(); }
            if (_reminders.isEmpty) _reminders = [1440];
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: selected ? _primary : Colors.grey.shade300, width: 1.5),
                ),
                child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
              const SizedBox(width: 12),
              Text(opt['label'], style: TextStyle(
                  fontSize: 14,
                  color: selected ? _primary : Colors.black87,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildToggleCard({
    required IconData icon, required Color iconColor,
    required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: value ? _primary.withOpacity(0.3) : Colors.grey.shade200,
            width: value ? 1.5 : 1),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        value: value, activeColor: _primary, onChanged: onChanged,
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.grey[600]),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: Colors.grey[600], letterSpacing: 0.3)),
    ]);
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }
}