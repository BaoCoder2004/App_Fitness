import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_fitness/features/profile/data/user_profile_repository.dart';
import 'package:app_fitness/features/profile/domain/user_profile.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

enum _Menu { changePassword, signOut }

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _repo = UserProfileRepository();

  final _lastNameCtl = TextEditingController(); // Họ
  final _firstNameCtl = TextEditingController(); // Tên
  final _emailCtl = TextEditingController();
  final _birthCtl = TextEditingController(); // yyyy-mm-dd
  final _heightCtl = TextEditingController();
  final _weightCtl = TextEditingController();

  Gender _gender = Gender.unknown;
  DateTime? _birthDate;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _lastNameCtl.dispose();
    _firstNameCtl.dispose();
    _emailCtl.dispose();
    _birthCtl.dispose();
    _heightCtl.dispose();
    _weightCtl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final saved = await _repo.load();
    if (saved != null) {
      _apply(saved);
    } else {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        final names = _splitName(u.displayName ?? '');
        _lastNameCtl.text = names.$1;
        _firstNameCtl.text = names.$2;
        _emailCtl.text = u.email ?? '';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _apply(UserProfile p) {
    _lastNameCtl.text = p.lastName;
    _firstNameCtl.text = p.firstName;
    _emailCtl.text = p.email;
    _gender = p.gender;
    _birthDate = p.birthDate;
    _birthCtl.text = _fmtDate(p.birthDate);
    _heightCtl.text =
        p.heightCm?.toStringAsFixed(p.heightCm! % 1 == 0 ? 0 : 1) ?? '';
    _weightCtl.text =
        p.weightKg?.toStringAsFixed(p.weightKg! % 1 == 0 ? 0 : 1) ?? '';
  }

  static String _fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static (String, String) _splitName(String full) {
    final s = full.trim();
    if (s.isEmpty) return ('', '');
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 1) return ('', parts[0]);
    final first = parts.removeLast();
    final last = parts.join(' ');
    return (last, first);
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthCtl.text = _fmtDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final profile = UserProfile(
      lastName: _lastNameCtl.text.trim(),
      firstName: _firstNameCtl.text.trim(),
      email: _emailCtl.text.trim(),
      gender: _gender,
      birthDate: _birthDate,
      heightCm: _numOrNull(_heightCtl.text),
      weightKg: _numOrNull(_weightCtl.text),
    );

    await _repo.save(profile);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
  }

  double? _numOrNull(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  // --- Menu handlers ---
  Future<void> _onChangePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tài khoản hiện tại không có email để đặt lại.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Text('Gửi email đặt lại mật khẩu tới:\n$email ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi')),
        ],
      ),
    ) ??
        false;
    if (!ok) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi liên kết đặt lại tới $email')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.message ?? e.code}')),
        );
      }
    }
  }

  Future<void> _onSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    ) ??
        false;
    if (!ok) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã đăng xuất')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ người dùng'),
        actions: [
          PopupMenuButton<_Menu>(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (m) {
              switch (m) {
                case _Menu.changePassword:
                  _onChangePassword();
                  break;
                case _Menu.signOut:
                  _onSignOut();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _Menu.changePassword,
                child: Text('Đổi mật khẩu',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              PopupMenuDivider(height: 0),
              PopupMenuItem(
                value: _Menu.signOut,
                child: Text('Đăng xuất',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Avatar(
                  fullName:
                  '${_lastNameCtl.text} ${_firstNameCtl.text}'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                      child: _textField(_lastNameCtl, label: 'Họ')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _textField(_firstNameCtl, label: 'Tên')),
                ],
              ),
              const SizedBox(height: 20),

              Text('Giới tính',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<Gender>(
                segments: const [
                  ButtonSegment(
                      value: Gender.male,
                      label: Text('Nam'),
                      icon: Icon(Icons.male)),
                  ButtonSegment(
                      value: Gender.female,
                      label: Text('Nữ'),
                      icon: Icon(Icons.female)),
                ],
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                selected: {_gender},
                onSelectionChanged: (s) =>
                    setState(() => _gender = s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 20),

              _textField(
                _emailCtl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return null;
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(s);
                  return ok ? null : 'Email không hợp lệ';
                },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickBirth,
                child: AbsorbPointer(
                  child: _textField(
                    _birthCtl,
                    label: 'Ngày sinh',
                    hintText: 'yyyy-mm-dd',
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _textField(
                      _heightCtl,
                      label: 'Chiều cao',
                      hintText: '170',
                      keyboardType: TextInputType.number,
                      suffix: const Text('cm'),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null;
                        final x = _numOrNull(v!);
                        if (x == null || x < 50 || x > 260) {
                          return '50–260';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      _weightCtl,
                      label: 'Cân nặng',
                      hintText: '65',
                      keyboardType: TextInputType.number,
                      suffix: const Text('kg'),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null;
                        final x = _numOrNull(v!);
                        if (x == null || x < 20 || x > 350) {
                          return '20–350';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: const Text('Lưu thay đổi'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                  await _repo.clear();
                  if (!mounted) return;
                  _lastNameCtl.clear();
                  _firstNameCtl.clear();
                  _emailCtl.clear();
                  _birthCtl.clear();
                  _heightCtl.clear();
                  _weightCtl.clear();
                  setState(() {
                    _gender = Gender.unknown;
                    _birthDate = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label:
                const Text('Đặt lại (xoá hồ sơ lưu cục bộ)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
      TextEditingController ctl, {
        required String label,
        String? hintText,
        TextInputType? keyboardType,
        Widget? suffixIcon,
        Widget? suffix,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: ctl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        suffix: suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.fullName});
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(fullName);
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: cs.surfaceContainerHighest,
          child: Text(
            initials,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            fullName.trim().isEmpty ? 'Chưa có tên' : fullName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '🙂';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
