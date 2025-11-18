import 'package:flutter/material.dart';
import 'add_goal_screen.dart';

/// Tab "Thống kê" trong bottom bar.
/// - Tông tối giản, dùng nhiều màu phẳng (không gradient).
/// - Màu nền theo ColorScheme, màu nhấn theo từng loại dữ liệu.
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  /// Lưu mục tiêu theo từng kiểu: frequency / duration / distance / calories
  final Map<GoalType, GoalConfig> _goalsByType = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final recent = <_RecentActivityData>[
      const _RecentActivityData(
        icon: Icons.directions_run,
        title: 'Chạy bộ buổi tối',
        subtitle: '6,0 km · 00:53:08',
        dateLabel: 'T2, 17/11',
      ),
      const _RecentActivityData(
        icon: Icons.directions_walk,
        title: 'Đi bộ nhẹ',
        subtitle: '4,0 km · 00:40:00',
        dateLabel: 'T5, 20/11',
      ),
      const _RecentActivityData(
        icon: Icons.fitness_center,
        title: 'Tập thể hình',
        subtitle: '320 kcal · 00:30:00',
        dateLabel: 'T6, 21/11',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Thống kê',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tổng quan tuần này và mục tiêu trong ngày.',
            style: textTheme.bodyMedium?.copyWith(
              color: cs.outline,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // --- Hàng tổng quan 3 mục (mỗi mục 1 màu accent, scroll ngang) ---
              const _WeeklySummaryRow(),
              const SizedBox(height: 20),

              // --- Biểu đồ 7 ngày ---
              const _SectionHeader(title: 'Hoạt động 7 ngày gần đây'),
              const SizedBox(height: 8),
              const _SevenDaysChartCard(),
              const SizedBox(height: 24),

              // --- Mục tiêu hôm nay ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader(title: 'Mục tiêu hôm nay'),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      final config =
                      await Navigator.of(context).push<GoalConfig>(
                        MaterialPageRoute(
                          builder: (_) => const AddGoalScreen(),
                        ),
                      );
                      if (!mounted) return;
                      if (config != null) {
                        setState(() {
                          // Cập nhật / thêm mục tiêu cho đúng kiểu
                          _goalsByType[config.goalType] = config;
                        });
                      }
                    },
                    child: const Text('Thêm'),
                  ),
                ],
              ),
              _TodayGoalsProgressCard(goalsByType: _goalsByType),
              const SizedBox(height: 24),

              // --- Hoạt động gần đây ---
              const _SectionHeader(title: 'Hoạt động gần đây'),
              const SizedBox(height: 8),
              _RecentActivitiesCard(recent: recent),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

/* ===================== HEADER NHỎ CHO CÁC SECTION ===================== */

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/* ===================== TỔNG QUAN TUẦN NÀY (SCROLL NGANG) ===================== */

class _WeeklySummaryRow extends StatelessWidget {
  const _WeeklySummaryRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget buildItem(
        String label,
        String value,
        String unit,
        IconData icon,
        Color accent,
        ) {
      return Container(
        width: 210, // card cố định, đủ để scroll ngang trên màn nhỏ
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          buildItem('Thời gian', '3,2', 'giờ', Icons.access_time, Colors.blue),
          buildItem('Quãng đường', '12,4', 'km', Icons.route, Colors.green),
          buildItem(
            'Năng lượng',
            '1.200',
            'kcal',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ],
      ),
    );
  }
}

/* ===================== BIỂU ĐỒ 7 NGÀY ===================== */

class _SevenDaysChartCard extends StatelessWidget {
  const _SevenDaysChartCard();

  static const _data = <int>[30, 45, 0, 20, 60, 40, 10];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    double maxValue =
    _data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxValue < 1) maxValue = 1;

    const barColor = Colors.teal;
    const barWidth = 18.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Phút hoạt động mỗi ngày',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Phút',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _data.length; i++)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: () {
                              final raw = _data[i] / maxValue;
                              if (raw < 0.08) return 0.08;
                              if (raw > 1.0) return 1.0;
                              return raw;
                            }(),
                            child: Container(
                              width: barWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: barColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekdayLabel(i),
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _weekdayLabel(int index) {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[index];
  }
}

/* ===================== MỤC TIÊU HÔM NAY ===================== */

class _TodayGoalsProgressCard extends StatelessWidget {
  const _TodayGoalsProgressCard({required this.goalsByType});

  final Map<GoalType, GoalConfig> goalsByType;

  String _formatDurationMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m phút';
    if (m == 0) return '$h giờ';
    return '${h}h ${m}m';
  }

  String _labelForGoalType(GoalType type) {
    switch (type) {
      case GoalType.frequency:
        return 'Buổi tập';
      case GoalType.duration:
        return 'Thời gian';
      case GoalType.distance:
        return 'Quãng đường';
      case GoalType.calories:
        return 'Kcal';
    }
  }

  Color _colorForGoalType(GoalType type) {
    // Mỗi loại mục tiêu 1 màu phẳng khác nhau
    switch (type) {
      case GoalType.frequency:
        return Colors.indigo;
      case GoalType.duration:
        return Colors.blue;
      case GoalType.distance:
        return Colors.orange;
      case GoalType.calories:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget buildRow({
      required GoalType type,
      required String value,
      required double progress,
    }) {
      double p = progress;
      if (p < 0) p = 0;
      if (p > 1) p = 1;

      final label = _labelForGoalType(type);
      final accent = _colorForGoalType(type);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 6,
                backgroundColor: cs.surface.withOpacity(0.7),
                valueColor: AlwaysStoppedAnimation<Color>(
                  accent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Chưa có mục tiêu -> hiển thị gợi ý
    if (goalsByType.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chưa có mục tiêu cho hôm nay.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Thêm ít nhất một mục tiêu để theo dõi tiến độ.',
              style: textTheme.bodySmall?.copyWith(
                color: cs.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Đã có mục tiêu -> hiển thị từng mục tiêu theo kiểu
    const doneFreq = 0; // TODO: sau này bind dữ liệu thật
    const doneDurationMin = 0;
    const doneDistance = 0.0;
    const doneCalories = 0;

    final rows = <Widget>[];

    // Thứ tự cố định
    final orderedTypes = [
      GoalType.frequency,
      GoalType.duration,
      GoalType.distance,
      GoalType.calories,
    ];

    for (final type in orderedTypes) {
      final g = goalsByType[type];
      if (g == null) continue;

      switch (type) {
        case GoalType.frequency:
          final t = g.frequency;
          final value = '$doneFreq / $t buổi';
          final progress = t <= 0 ? 0.0 : doneFreq / t;
          rows.add(
            buildRow(
              type: type,
              value: value,
              progress: progress,
            ),
          );
          break;

        case GoalType.duration:
          final tMin = g.duration.inMinutes;
          final value =
              '${_formatDurationMinutes(doneDurationMin)} / ${_formatDurationMinutes(tMin)}';
          final progress =
          tMin <= 0 ? 0.0 : doneDurationMin / tMin;
          rows.add(
            buildRow(
              type: type,
              value: value,
              progress: progress,
            ),
          );
          break;

        case GoalType.distance:
          final tKm = g.distanceKm;
          final value =
              '${doneDistance.toStringAsFixed(1)} / ${tKm.toStringAsFixed(1)} km';
          final progress =
          tKm <= 0 ? 0.0 : doneDistance / tKm;
          rows.add(
            buildRow(
              type: type,
              value: value,
              progress: progress,
            ),
          );
          break;

        case GoalType.calories:
          final tCal = g.calories;
          final value = '$doneCalories / $tCal kcal';
          final progress =
          tCal <= 0 ? 0.0 : doneCalories / tCal;
          rows.add(
            buildRow(
              type: type,
              value: value,
              progress: progress,
            ),
          );
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withOpacity(0.2),
        ),
      ),
      child: Column(children: rows),
    );
  }
}

/* ===================== HOẠT ĐỘNG GẦN ĐÂY ===================== */

class _RecentActivityData {
  const _RecentActivityData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String dateLabel;
}

class _RecentActivitiesCard extends StatelessWidget {
  const _RecentActivitiesCard({required this.recent});

  final List<_RecentActivityData> recent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.7,
                color: cs.outline.withOpacity(0.1),
              ),
            _RecentActivityTile(data: recent[i]),
          ],
        ],
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.data});

  final _RecentActivityData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: cs.surface,
        foregroundColor: Colors.blueGrey,
        child: Icon(
          data.icon,
          size: 20,
        ),
      ),
      title: Text(
        data.title,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        data.subtitle,
        style: textTheme.bodySmall?.copyWith(
          color: cs.outline,
        ),
      ),
      trailing: Text(
        data.dateLabel,
        style: textTheme.bodySmall?.copyWith(
          color: cs.outline,
        ),
      ),
    );
  }
}
