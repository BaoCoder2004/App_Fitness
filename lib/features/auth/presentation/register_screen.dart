import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:app_fitness/features/onboarding/presentation/start_screen.dart';
import 'package:app_fitness/features/auth/presentation/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible        = false;
  bool _isConfirmPasswordVisible = false;
  bool _isRegistering            = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StartScreen()),
      );
    }
  }

  Future<void> _onRegisterPressed() async {
    if (_isRegistering) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final email     = _emailController.text.trim();
    final password  = _passwordController.text.trim();
    final confirm   = _confirmPasswordController.text.trim();

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp.')),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      // Chặn case email đã tồn tại
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        final msg = methods.contains('google.com')
            ? 'Email này đã đăng ký bằng Google. Hãy bấm “Đăng nhập” và chọn Google.'
            : 'Email này đã được đăng ký. Hãy bấm “Đăng nhập”.';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = cred.user;
      if (user != null) {
        // Cập nhật tên hiển thị
        final displayName = '$firstName $lastName'.trim();
        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }

        // Lưu hồ sơ cơ bản vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'provider': 'password',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Bắt buộc đăng nhập lại → signOut và chuyển về Login
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công. Vui lòng đăng nhập.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Đã có lỗi xảy ra khi đăng ký.';
      if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email này đã được sử dụng. Hãy “Đăng nhập” hoặc dùng Google nếu đã liên kết.';
      } else if (e.code == 'invalid-email') {
        message = 'Định dạng email không hợp lệ.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Phương thức đăng ký chưa được bật trên Firebase.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi không xác định xảy ra.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    if (_isRegistering) return;
    setState(() => _isRegistering = true);

    try {
      final google = GoogleSignIn();
      // Buộc hiển thị chọn tài khoản
      await google.signOut();
      await google.disconnect().catchError((_) {});

      final googleUser = await google.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isRegistering = false);
        return; // người dùng huỷ
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        final name  = (user.displayName ?? '').trim();
        final parts = name.split(RegExp(r'\s+'));
        final first = parts.isNotEmpty ? parts.first : '';
        final last  = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        final isNew = userCred.additionalUserInfo?.isNewUser ?? false;

        final data = <String, dynamic>{
          'firstName': first,
          'lastName' : last,
          'email'    : user.email,
          'provider' : 'google',
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (isNew) data['createdAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(data, SetOptions(merge: true));

        // Bắt buộc đăng nhập lại → signOut Google + Firebase
        await google.signOut();
        await google.disconnect().catchError((_) {});
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký bằng Google thành công. Vui lòng đăng nhập.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Đã có lỗi khi đăng ký bằng Google.';
      if (e.code == 'account-exists-with-different-credential') {
        message = 'Email này đã đăng ký với phương thức khác. Hãy dùng cách đăng nhập tương ứng.';
      } else if (e.code == 'invalid-credential') {
        message = 'Thông tin xác thực không hợp lệ hoặc đã hết hạn.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Đăng nhập Google chưa được bật trên Firebase.';
      } else if ((e.message ?? '').isNotEmpty) {
        message = e.message!;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi không xác định khi đăng ký bằng Google.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final textTheme = GoogleFonts.interTextTheme(theme.textTheme);

    return Scaffold(
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _onBackPressed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo tài khoản mới',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tham gia cùng chúng tôi để bắt đầu hành trình rèn luyện sức khoẻ.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Tên',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Vui lòng nhập tên';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Họ',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Vui lòng nhập họ';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Vui lòng nhập email';
                            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                            if (!emailRegex.hasMatch(v)) {
                              return 'Vui lòng nhập email hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
                            if (v.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                            if (v != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isRegistering ? null : _onRegisterPressed,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isRegistering
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Text(
                              'Đăng ký',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Hoặc tiếp tục với',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isRegistering ? null : _registerWithGoogle,
                      icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Đã có tài khoản?', style: textTheme.bodyMedium),
                      TextButton(
                        onPressed: _goToLogin,
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
