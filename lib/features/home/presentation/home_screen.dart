// lib/features/home/presentation/home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'stats_tab.dart';
import 'package:app_fitness/features/activity/presentation/activity_tab.dart';
import 'package:app_fitness/features/profile/presentation/profile_tab.dart';

/// Trang chủ + Bottom bar (Trang chủ | Thống kê | Hoạt động | AI Coach | Hồ sơ)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName});

  /// Nếu truyền sẵn tên từ màn đăng nhập thì dùng, nếu không sẽ tự lấy từ FirebaseAuth.currentUser.
  final String? userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  String get _resolvedUserName {
    // Ưu tiên tên truyền vào (nếu có)
    final fromWidget = widget.userName;
    if (fromWidget != null && fromWidget.trim().isNotEmpty) {
      return fromWidget.trim();
    }

    // Lấy từ FirebaseAuth.currentUser
    final user = FirebaseAuth.instance.currentUser;

    final displayName = (user?.displayName ?? '').trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }

    // Fallback: lấy phần trước @ của email nếu displayName trống
    final email = (user?.email ?? '').trim();
    if (email.contains('@')) {
      return email.split('@').first;
    }

    // Fallback cuối
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        userName: _resolvedUserName,
        onSelectTab: (tab) => setState(() => _index = tab),
      ),
      const StatsTab(),
      const ActivityTab(),
      const _PlaceholderTab(title: 'AI Coach'),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: _BottomPillNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

/* ---------------------------- COLORS theo mock ---------------------------- */
const _kPurple = Color(0xFFC9B8FF);
const _kLime = Color(0xFFD8FF6A);
const _kBarBlue = Color(0xFFCDEAFB);
const _kOutline = Color(0xFFDCDCDC);
const _kNavBg = Colors.black;

/* -------------------------------- HOME TAB -------------------------------- */
class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.userName,
    required this.onSelectTab,
  });

  final String userName;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(userName: userName)),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(
          child: _Section(
            title: 'Kế hoạch hôm nay',
            child: _TodayPlanCards(
              onTapWorkout: () => onSelectTab(2), // tab Hoạt động
              onTapGoals: () => onSelectTab(1), // tab Thống kê
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Section(
            title: 'Tiến độ tuần',
            child: const _WeeklyProgressChart(
              data: [22, 35, 42, 48, 60, 36, 30],
              labels: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
              unit: 'phút',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Section(
            title: 'Buổi gần nhất',
            child: const _LastSessionCard(
              typeIcon: Icons.directions_run,
              title: 'Chạy bộ',
              subtitle: '18:40 · 21/11',
              stats: '4.2 km · 28 phút · 235 kcal',
              progress: 0.68,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Section(
            title: 'Gợi ý với AI Coach',
            child: const _AiCoachCard(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/* --------------------------------- HEADER ---------------------------------- */
class _Header extends StatelessWidget {
  const _Header({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFEDEDED),
            child: Icon(Icons.person, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $userName',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chúc bạn có một ngày tập hiệu quả!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.black),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ SECTION WRAP -------------------------------- */
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/* ------------------------- TODAY PLAN (scroll ngang) ----------------------- */
class _TodayPlanCards extends StatelessWidget {
  const _TodayPlanCards({
    required this.onTapWorkout,
    required this.onTapGoals,
  });

  final VoidCallback onTapWorkout;
  final VoidCallback onTapGoals;

  @override
  Widget build(BuildContext context) {
    const cardHeight = 160.0;
    const cardWidth = 260.0;

    return SizedBox(
      height: cardHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          SizedBox(
            width: cardWidth,
            child: _ColoredCard(
              height: cardHeight,
              color: _kPurple,
              child: _PlanTile(
                icon: Icons.local_fire_department,
                title: 'Bài tập hôm nay',
                subtitle: '30–40 phút · Toàn thân',
                chip: 'Bắt đầu',
                onTap: onTapWorkout, // → tab Hoạt động
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: cardWidth,
            child: _ColoredCard(
              height: cardHeight,
              color: _kLime,
              child: _PlanTile(
                icon: Icons.flag_outlined,
                title: 'Mục tiêu hôm nay',
                subtitle: 'Hoàn thành 2/3 bài · 30/45 phút',
                chip: 'Xem chi tiết',
                onTap: onTapGoals, // → tab Thống kê
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColoredCard extends StatelessWidget {
  const _ColoredCard({
    required this.child,
    required this.color,
    this.height = 140,
  });
  final Widget child;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kOutline),
      ),
      child: child,
    );
  }
}

/// Bố cục: Row(icon + texts) ở trên, chip ở đáy; tất cả gói trong Column
/// mainAxisAlignment.spaceBetween để giữ chiều cao ổn định, không overflow.
class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chip,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String chip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.black87, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,        // cho phép tối đa 2 dòng
                        softWrap: true,     // tự xuống dòng, không hiển thị "..."
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _kOutline),
              ),
              child: Text(chip, style: textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ WEEKLY CHART -------------------------------- */
class _WeeklyProgressChart extends StatelessWidget {
  const _WeeklyProgressChart({
    required this.data,
    required this.labels,
    this.unit,
  });
  final List<num> data; // 7 giá trị
  final List<String> labels; // 7 nhãn
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final maxV = data.isEmpty ? 1.0 : data.reduce(math.max).toDouble();
    return _CardBase(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < data.length; i++)
                    Expanded(
                      child: _Bar(
                        value:
                        data[i].toDouble() / (maxV == 0 ? 1 : maxV),
                        label: labels[i],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (unit != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Đơn vị: $unit',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.label});
  final double value; // 0..1
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Container(
              height: 8 + v * 130,
              decoration: BoxDecoration(
                color: _kBarBlue,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

/* ------------------------------ LAST SESSION -------------------------------- */
class _LastSessionCard extends StatelessWidget {
  const _LastSessionCard({
    required this.typeIcon,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.progress,
  });
  final IconData typeIcon;
  final String title;
  final String subtitle;
  final String stats;
  final double progress; // 0..1

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(typeIcon, color: Colors.black87),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF2F2F2),
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------- AI COACH ---------------------------------- */
class _AiCoachCard extends StatelessWidget {
  const _AiCoachCard();

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.smart_toy_outlined),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hỏi AI Coach',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Tôi muốn tăng sức bền trong 4 tuần tới, hãy gợi ý lịch chạy xen kẽ ngày nghỉ và bài tập bổ trợ.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _QuickChip(label: 'Kế hoạch 4 tuần'),
                _QuickChip(label: 'Ăn gì trước khi chạy?'),
                _QuickChip(label: 'Lịch tập HIIT'),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Hỏi ngay'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kOutline),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

/* -------------------------------- CARD BASE --------------------------------- */
class _CardBase extends StatelessWidget {
  const _CardBase({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOutline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/* ------------------------------ BOTTOM PILL NAV ----------------------------- */
class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData(this.icon, this.label);
}

class _BottomPillNav extends StatelessWidget {
  const _BottomPillNav({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = <_NavItemData>[
      _NavItemData(Icons.home_rounded, 'Trang chủ'),
      _NavItemData(Icons.bar_chart_rounded, 'Thống kê'),
      _NavItemData(Icons.bolt_rounded, 'Hoạt động'),
      _NavItemData(Icons.grid_view_rounded, 'AI Coach'),
      _NavItemData(Icons.person_rounded, 'Hồ sơ'),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _kNavBg,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (i) {
            final selected = index == i;
            return _NavItem(
              icon: items[i].icon,
              label: items[i].label,
              selected: selected,
              onTap: () => onChanged(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = selected
        ? Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.black, size: 24),
    )
        : Icon(icon, color: Colors.white, size: 24);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(selected ? 1.0 : 0.85),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ PLACEHOLDER TABS ---------------------------- */
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
