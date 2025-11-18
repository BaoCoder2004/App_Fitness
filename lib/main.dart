import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'features/onboarding/presentation/start_screen.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return MaterialApp(
      title: 'App Fitness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // Nút FilledButton mặc định (đen)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        // TextField / TextFormField
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 1.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 1.8),
          ),
          hintStyle: baseTextTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),

        // Toàn bộ text dùng Inter + màu đen
        textTheme: baseTextTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),

        // Icon mặc định màu đen
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // Khai báo route Trang chủ để điều hướng xoá backstack khi đăng nhập
      routes: {
        '/home': (_) => const HomeScreen(),
      },

      // Điều hướng theo trạng thái đăng nhập
      home: const _AuthGate(),
    );
  }
}

/// Stream trạng thái Auth → vào Trang chủ nếu đã đăng nhập
class _AuthGate extends StatelessWidget {
  const _AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasData) {
          return const HomeScreen();
        }
        return const StartScreen(); // chưa đăng nhập → màn hình bắt đầu/đăng nhập
      },
    );
  }
}
