import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static const String _themeKey = 'isDarkMode';

  // Lưu trạng thái Theme
  static Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  // Đọc trạng thái Theme (Mặc định trả về false - Light mode nếu chưa lưu)
  static Future<bool> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }
}