import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_fitness/features/auth/presentation/login_screen.dart';
import 'package:app_fitness/features/auth/presentation/register_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _goBackToLogin() {
    // Quay lại Login, giữ lại route đầu (Start) như bạn đang làm
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => route.isFirst,
    );
  }

  Future<void> _onSendLinkPressed() async {
    final email = _emailController.text.trim();

    // kiểm tra đơn giản trước khi call Firebase
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Gửi email reset; nếu email chưa tồn tại, Firebase sẽ ném lỗi user-not-found
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nếu email đã được đăng ký, hệ thống đã gửi link đặt lại mật khẩu. Hãy kiểm tra hộp thư của bạn.',
          ),
        ),
      );

      // Sau khi gửi xong quay lại Login mới (form trống)
      _goBackToLogin();
    } on FirebaseAuthException catch (e) {
      String message = 'Có lỗi xảy ra khi gửi email.';

      if (e.code == 'invalid-email') {
        message = 'Địa chỉ email không hợp lệ.';
      } else if (e.code == 'user-not-found') {
        message = 'Tài khoản chưa được đăng ký.';
      } else if (e.code == 'missing-email') {
        message = 'Vui lòng nhập email.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      debugPrint('Unknown error in _onSendLinkPressed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi không xác định. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.interTextTheme(theme.textTheme);

    return WillPopScope(
      onWillPop: () async {
        _goBackToLogin(); // nút Back hệ thống
        return false; // chặn pop mặc định
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nút back giống Login / Register
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _goBackToLogin,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Quên mật khẩu',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Nhập email bạn đã dùng để đăng ký tài khoản. '
                          'Chúng tôi sẽ gửi cho bạn đường dẫn để đặt lại mật khẩu.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email đã đăng ký',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _onSendLinkPressed(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSending ? null : _onSendLinkPressed,
                        style: FilledButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSending
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : const Text(
                          'Gửi link đặt lại mật khẩu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quay lại đăng nhập
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _goBackToLogin,
                          child: const Text('Quay về trang đăng nhập'),
                        ),
                      ],
                    ),
                    // Sang đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản?',
                          style: textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Đăng ký'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
