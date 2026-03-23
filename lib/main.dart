import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // tự sinh bởi flutterfire configure
import 'providers/event_provider.dart';
import 'providers/theme_provider.dart';
import 'data/notification_helper.dart';
import 'data/firebase_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo thông báo local
  await NotificationHelper.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()..fetchEvents()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Sổ Tay Âm Lịch',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            // Tự động điều hướng: đã login → Dashboard, chưa login → Auth
            home: StreamBuilder(
              stream: FirebaseService.instance.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A3A4A),
                      ),
                    ),
                  );
                }
                // Đã đăng nhập → Dashboard
                if (snapshot.hasData) {
                  return const DashboardScreen();
                }
                // Chưa đăng nhập → AuthScreen
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
