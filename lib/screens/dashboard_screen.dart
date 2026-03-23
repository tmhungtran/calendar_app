import 'package:btl_nhom_15/model/lunar_event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lunar/lunar.dart';

import '../providers/event_provider.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _primary = Color(0xFF1A3A4A);

  late DateTime _focusedDay;
  late DateTime _selectedDay;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  int? _filterType; // null=tất cả, 0=dương, 1=âm

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = DateTime(now.year, now.month, now.day);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Lunar _getLunarInfo(DateTime date) =>
      Solar.fromYmd(date.year, date.month, date.day).getLunar();

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Tên thứ trong tuần
  String _weekdayName(DateTime d) {
    const names = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return names[d.weekday];
  }

  // Hiện dialog chọn năm
  void _showYearPicker() {
    final currentYear = _focusedDay.year;
    final scrollController = ScrollController(
      initialScrollOffset: (currentYear - 1924) * 48.0,
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Chọn năm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 201,
                  itemBuilder: (ctx, i) {
                    final year = 1924 + i;
                    final isSelected = year == currentYear;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _focusedDay = DateTime(year, _focusedDay.month, 1);
                          _selectedDay = DateTime(
                            year,
                            _selectedDay.month,
                            _selectedDay.day.clamp(
                              1,
                              DateUtils.getDaysInMonth(
                                year,
                                _selectedDay.month,
                              ),
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primary.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: isSelected ? 18 : 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? _primary : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    Provider.of<EventProvider>(context, listen: false).setSearchQuery('');
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _filterType = null;
    });
    _searchController.clear();
    Provider.of<EventProvider>(context, listen: false).clearFilter();
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
            SizedBox(width: 10),
            Text('Xác nhận xóa', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: const Text('Bạn có chắc muốn xóa sự kiện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Provider.of<EventProvider>(
                context,
                listen: false,
              ).deleteEvent(id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isSearching ? _buildSearchBody() : _buildCalendarBody(),
      floatingActionButton: _isSearching ? null : _buildFAB(),
    );
  }

  // ─────────────────────────────────────────────
  // AppBar: chuyển đổi giữa title bình thường và search bar
  // ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _closeSearch,
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white70,
          decoration: const InputDecoration(
            hintText: 'Tìm "Sinh nhật", "Giỗ"...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (q) {
            Provider.of<EventProvider>(
              context,
              listen: false,
            ).setSearchQuery(q);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
                Provider.of<EventProvider>(
                  context,
                  listen: false,
                ).setSearchQuery('');
              },
            ),
        ],
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: _primary,
      centerTitle: true,
      title: const Text(
        'Sổ Tay Âm Lịch',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Tìm kiếm',
          onPressed: _openSearch,
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_outlined, color: Colors.white),
          tooltip: 'Thống kê',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatsScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          tooltip: 'Cài đặt',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Giao diện khi đang tìm kiếm
  // ─────────────────────────────────────────────
  Widget _buildSearchBody() {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        final results = provider.filteredEvents;

        return Column(
          children: [
            // Filter chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Dương lịch', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('Âm lịch', 1),
                ],
              ),
            ),

            // Kết quả
            Expanded(
              child: results.isEmpty
                  ? _buildSearchEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      itemBuilder: (ctx, i) =>
                          _buildEventCard(results[i], provider),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int? type) {
    final active = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
        Provider.of<EventProvider>(context, listen: false).setFilterType(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            'Không tìm thấy sự kiện nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thử từ khóa khác hoặc đổi bộ lọc',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Giao diện chính: lịch + danh sách theo ngày
  // ─────────────────────────────────────────────
  Widget _buildCalendarBody() {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        final selectedDateStr = _formatDate(_selectedDay);
        final selectedEvents = provider.getEventsForDay(selectedDateStr);

        return Column(
          children: [
            // ── Calendar ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TableCalendar<LunarEvent>(
                  firstDay: DateTime(1900),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = _normalize(selectedDay);
                      _focusedDay = _normalize(focusedDay);
                    });
                  },
                  eventLoader: (day) {
                    return provider.getEventsForDay(_formatDate(day));
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: false,
                    leftChevronVisible: true,
                    rightChevronVisible: true,
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: _primary),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: _primary,
                    ),
                    headerPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (ctx, date, _) =>
                        _buildDayCell(date, isSelected: false, isToday: false),
                    selectedBuilder: (ctx, date, _) =>
                        _buildDayCell(date, isSelected: true, isToday: false),
                    todayBuilder: (ctx, date, _) {
                      final sel = _isSameDay(date, _selectedDay);
                      return _buildDayCell(
                        date,
                        isSelected: sel,
                        isToday: !sel,
                      );
                    },
                    headerTitleBuilder: (ctx, focusedDay) {
                      final months = [
                        '',
                        'Tháng 1',
                        'Tháng 2',
                        'Tháng 3',
                        'Tháng 4',
                        'Tháng 5',
                        'Tháng 6',
                        'Tháng 7',
                        'Tháng 8',
                        'Tháng 9',
                        'Tháng 10',
                        'Tháng 11',
                        'Tháng 12',
                      ];
                      return GestureDetector(
                        onTap: _showYearPicker,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${months[focusedDay.month]} ${focusedDay.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: _primary,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  rowHeight: 52,
                  daysOfWeekHeight: 24,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    markerDecoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    markerSize: 5.0,
                    markersAnchor: 1.5,
                  ),
                ),
              ),
            ),

            // ── Header ngày được chọn ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_weekdayName(_selectedDay)}, ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selectedEvents.isEmpty
                          ? Colors.grey[100]
                          : _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${selectedEvents.length} sự kiện',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selectedEvents.isEmpty ? Colors.grey : _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Danh sách sự kiện ──
            Expanded(
              child: selectedEvents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: selectedEvents.length,
                      itemBuilder: (ctx, i) =>
                          _buildEventCard(selectedEvents[i], provider),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Event card với Hero animation
  // ─────────────────────────────────────────────
  Widget _buildEventCard(LunarEvent event, EventProvider provider) {
    final isLunar = event.isLunar == 1;
    final iconColor = isLunar ? const Color(0xFF7F77DD) : _primary;
    final iconBg = isLunar
        ? const Color(0xFF7F77DD).withOpacity(0.1)
        : _primary.withOpacity(0.08);

    return Hero(
      tag: 'event_card_${event.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(event: event)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isLunar ? Icons.brightness_2 : Icons.calendar_today,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (event.isYearly == 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.repeat,
                                  size: 14,
                                  color: Colors.teal[400],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.description.isEmpty
                              ? 'Không có ghi chú'
                              : event.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Actions
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditScreen(event: event),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context, event.id!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Ô ngày trong lịch
  // ─────────────────────────────────────────────
  Widget _buildDayCell(
    DateTime date, {
    required bool isSelected,
    bool isToday = false,
  }) {
    final lunar = _getLunarInfo(date);
    final isSpecial = lunar.getDay() == 1 || lunar.getDay() == 15;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF1A3A4A), Color(0xFF2D6A7F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: (!isSelected && isToday)
            ? _primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: (!isSelected && isToday)
            ? Border.all(color: _primary.withOpacity(0.4), width: 1.2)
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : (isToday ? _primary : Colors.black87),
              ),
            ),
            Text(
              '${lunar.getDay()}/${lunar.getMonth()}',
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? Colors.white70
                    : (isSpecial ? Colors.redAccent : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 72,
            color: _primary.withOpacity(0.2),
          ),
          const SizedBox(height: 14),
          Text(
            'Ngày này thật rảnh rỗi!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn + để thêm sự kiện mới',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      backgroundColor: _primary,
      elevation: 3,
      onPressed: () {
        final newEvent = LunarEvent(title: '', date: _formatDate(_selectedDay));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditScreen(event: newEvent)),
        );
      },
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Thêm sự kiện',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
