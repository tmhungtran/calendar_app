import 'package:flutter/material.dart';
import '../data/prefs_helper.dart'; // Gọi chuyên gia xử lý Prefs vào

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Nhờ PrefsHelper đọc dữ liệu
  Future<void> _loadTheme() async {
    _isDarkMode = await PrefsHelper.getTheme();
    notifyListeners();
  }

  // Nhờ PrefsHelper lưu dữ liệu
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await PrefsHelper.saveTheme(_isDarkMode);
    notifyListeners();
  }
}
