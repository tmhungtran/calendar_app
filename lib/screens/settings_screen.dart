import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/event_provider.dart';
import '../data/firebase_service.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _primary = Color(0xFF1A3A4A);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final user = FirebaseService.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cài đặt',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Tài khoản ──────────────────────────────────────────────────
          _sectionTitle('Tài khoản'),
          _buildCard(children: [
            if (user != null) ...[
              // Đã đăng nhập
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _primary.withOpacity(0.1),
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                                color: _primary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName ?? 'Người dùng',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(user.email ?? '',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[500])),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('☁️ Đã đồng bộ',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  )),
                ]),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              // Sync thủ công
              _buildListTile(
                icon: Icons.sync,
                iconColor: Colors.blue,
                title: 'Đồng bộ ngay',
                subtitle: eventProvider.isSyncing
                    ? 'Đang đồng bộ...'
                    : 'Kéo dữ liệu từ cloud về máy',
                trailing: eventProvider.isSyncing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right,
                        color: Colors.grey),
                onTap: eventProvider.isSyncing
                    ? null
                    : () async {
                        await eventProvider.syncFromCloud();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đồng bộ xong!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              // Đăng xuất
              _buildListTile(
                icon: Icons.logout,
                iconColor: Colors.redAccent,
                title: 'Đăng xuất',
                subtitle: 'Dữ liệu local vẫn được giữ lại',
                onTap: () => _confirmSignOut(context),
              ),
            ] else ...[
              // Chưa đăng nhập
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Icon(Icons.cloud_off,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Chưa đăng nhập',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600])),
                  const SizedBox(height: 6),
                  Text('Đăng nhập để đồng bộ dữ liệu\ntrên nhiều thiết bị',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[400])),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      icon: const Text('G',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4285F4))),
                      label: const Text('Đăng nhập với Google'),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AuthScreen()),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ]),

          const SizedBox(height: 20),

          // ── Giao diện ──────────────────────────────────────────────────
          _sectionTitle('Giao diện'),
          _buildCard(children: [
            SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              secondary: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Colors.indigo, size: 18,
                ),
              ),
              title: const Text('Giao diện tối',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                  themeProvider.isDarkMode ? 'Đang bật' : 'Đang tắt',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
              value: themeProvider.isDarkMode,
              activeColor: _primary,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ]),

          const SizedBox(height: 20),

          // ── Thông tin app ──────────────────────────────────────────────
          _sectionTitle('Thông tin'),
          _buildCard(children: [
            _buildListTile(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: 'Phiên bản',
              subtitle: '1.0.0',
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            _buildListTile(
              icon: Icons.group_outlined,
              iconColor: Colors.grey,
              title: 'Nhóm',
              subtitle: 'Nhóm 15 — Lập trình Mobile',
            ),
          ]),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất?'),
        content: const Text(
            'Dữ liệu trên máy vẫn được giữ lại. Bạn có thể đăng nhập lại bất cứ lúc nào.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await FirebaseService.instance.signOut();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
              textBaseline: TextBaseline.alphabetic)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}