import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/firebase_service.dart';
import '../providers/event_provider.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color _primary = Color(0xFF1A3A4A);
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    final user = await FirebaseService.instance.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      // Sau khi đăng nhập: sync dữ liệu local lên cloud
      final provider = Provider.of<EventProvider>(context, listen: false);
      await provider.syncAfterLogin();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thất bại, thử lại nhé!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo / Icon ───────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 28),

              // ── Tiêu đề ──────────────────────────────────────────────
              const Text(
                'Sổ Tay Âm Lịch',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A4A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Đăng nhập để đồng bộ sự kiện\ntrên tất cả thiết bị của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // ── Nút Google Sign-In ────────────────────────────────────
              _isLoading
                  ? const CircularProgressIndicator(color: _primary)
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _signIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google logo bằng icon đơn giản
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Đăng nhập với Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A3A4A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

              const SizedBox(height: 16),

              // ── Bỏ qua đăng nhập ────────────────────────────────────
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
                child: Text(
                  'Dùng không cần đăng nhập',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),

              const Spacer(),

              // ── Ghi chú ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Dữ liệu được bảo mật và mã hóa\nbởi Google Firebase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
