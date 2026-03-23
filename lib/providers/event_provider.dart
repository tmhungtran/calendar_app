import 'package:btl_nhom_15/model/lunar_event.dart';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class EventProvider extends ChangeNotifier {
  List<LunarEvent> _events = [];
  String _searchQuery = '';
  int? _filterType;

  List<LunarEvent> get events => _events;
  String get searchQuery => _searchQuery;
  int? get filterType => _filterType;

  List<LunarEvent> get filteredEvents {
    List<LunarEvent> result = _events;
    if (_filterType != null) {
      result = result.where((e) => e.isLunar == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q) ||
                e.location.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  // Lấy sự kiện cho một ngày cụ thể — hỗ trợ lặp daily/weekly/monthly/yearly
  List<LunarEvent> getEventsForDay(String dateStr) {
    final target = DateTime.tryParse(dateStr);
    if (target == null) return [];

    return _events.where((e) {
      final eventDate = DateTime.tryParse(e.date);
      if (eventDate == null) return false;

      // Khớp ngày chính xác
      if (e.date == dateStr) return true;

      // Kiểm tra lặp lại
      switch (e.repeatType) {
        case 'daily':
          return !target.isBefore(eventDate);
        case 'weekly':
          return !target.isBefore(eventDate) &&
              target.weekday == eventDate.weekday;
        case 'monthly':
          return !target.isBefore(eventDate) && target.day == eventDate.day;
        case 'yearly':
          return !target.isBefore(eventDate) &&
              target.month == eventDate.month &&
              target.day == eventDate.day;
        default:
          return false;
      }
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(int? type) {
    _filterType = type;
    notifyListeners();
  }

  void clearFilter() {
    _searchQuery = '';
    _filterType = null;
    notifyListeners();
  }

  Future<void> fetchEvents() async {
    _events = await DatabaseHelper.instance.getAllEvents();
    notifyListeners();
  }

  Future<void> addEvent(LunarEvent event) async {
    await DatabaseHelper.instance.insertEvent(event);
    await fetchEvents();
  }

  Future<void> updateEvent(LunarEvent event) async {
    await DatabaseHelper.instance.updateEvent(event);
    await fetchEvents();
  }

  Future<void> deleteEvent(int id) async {
    await DatabaseHelper.instance.deleteEvent(id);
    await fetchEvents();
  }

  Future<Map<String, int>> getMonthStats(int year, int month) async {
    return await DatabaseHelper.instance.getMonthStats(year, month);
  }

  Future<void> syncAfterLogin() async {}
  // --- BIẾN VÀ HÀM CHO CHỨC NĂNG ĐỒNG BỘ CLOUD ---
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> syncFromCloud() async {
    // Bật trạng thái đang đồng bộ để xoay xoay vòng loading
    _isSyncing = true;
    notifyListeners();

    try {
      // Tạm thời cho hệ thống chờ 2 giây để giả lập việc tải dữ liệu.
      // Khi nào code xong file FirebaseService, ta sẽ gọi hàm tải thật ở đây.
      await Future.delayed(const Duration(seconds: 2));
      print("Đã đồng bộ dữ liệu xong!");
    } catch (e) {
      print("Lỗi đồng bộ: $e");
    } finally {
      // Tắt trạng thái đồng bộ
      _isSyncing = false;
      notifyListeners();
    }
  }
}
