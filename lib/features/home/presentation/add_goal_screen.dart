import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ActivityType { all, run, walk, bike, strength }
enum TimeFrame { day, week, month, year }
enum GoalType { frequency, duration, distance, calories }

/// Cấu hình mục tiêu – dùng để trả về cho Thống kê
class GoalConfig {
  const GoalConfig({
    required this.activityType,
    required this.timeFrame,
    required this.goalType,
    required this.frequency,
    required this.duration,
    required this.distanceKm,
    required this.calories,
  });

  final ActivityType activityType;
  final TimeFrame timeFrame;
  final GoalType goalType;
  final int frequency; // số buổi
  final Duration duration; // thời lượng
  final double distanceKm; // km
  final int calories; // kcal
}

/// Màn hình "Thêm mục tiêu"
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  ActivityType _activityType = ActivityType.all;
  TimeFrame _timeFrame = TimeFrame.week;
  GoalType _goalType = GoalType.frequency;

  int _frequency = 3;
  Duration _duration = const Duration(minutes: 30);
  double _distanceKm = 5;
  int _calories = 300;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thêm mục tiêu'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- Chọn loại hoạt động --------
            Text(
              'Chọn loại hoạt động',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildAllActivitiesButton(),
            const SizedBox(height: 12),
            _buildActivityGrid(),

            const SizedBox(height: 24),

            // -------- Thời gian --------
            Text(
              'Thời gian',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimeFrameGrid(),

            const SizedBox(height: 24),

            // -------- Kiểu mục tiêu --------
            Text(
              'Kiểu mục tiêu',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildGoalTypeGrid(),
          ],
        ),
      ),
    );
  }

  /* ===================== UI HELPERS ===================== */

  Widget _buildAllActivitiesButton() {
    final cs = Theme.of(context).colorScheme;
    final selected = _activityType == ActivityType.all;

    return _ChoiceCard(
      selected: selected,
      label: 'Tất cả hoạt động',
      icon: Icons.bolt,
      onTap: () {
        setState(() {
          _activityType = ActivityType.all;
        });
      },
      borderRadius: 12,
      fullWidth: true,
      selectedColor: cs.primary.withOpacity(0.06),
    );
  }

  Widget _buildActivityGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: [
        _activityItem(ActivityType.run, Icons.directions_run, 'Chạy bộ'),
        _activityItem(ActivityType.walk, Icons.directions_walk, 'Đi bộ'),
        _activityItem(ActivityType.bike, Icons.directions_bike, 'Đạp xe'),
        _activityItem(ActivityType.strength, Icons.fitness_center, 'Thể hình'),
      ],
    );
  }

  Widget _activityItem(ActivityType type, IconData icon, String label) {
    return _ChoiceCard(
      selected: _activityType == type,
      label: label,
      icon: icon,
      onTap: () {
        setState(() {
          _activityType = type;
        });
      },
    );
  }

  Widget _buildTimeFrameGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: [
        _timeFrameItem(TimeFrame.day, 'Theo ngày'),
        _timeFrameItem(TimeFrame.week, 'Theo tuần'),
        _timeFrameItem(TimeFrame.month, 'Theo tháng'),
        _timeFrameItem(TimeFrame.year, 'Theo năm'),
      ],
    );
  }

  Widget _timeFrameItem(TimeFrame frame, String label) {
    return _ChoiceCard(
      selected: _timeFrame == frame,
      label: label,
      onTap: () {
        setState(() {
          _timeFrame = frame;
        });
      },
    );
  }

  Widget _buildGoalTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: [
        _goalTypeItem(
          GoalType.frequency,
          'Hoạt động',
          '${_frequency} buổi',
        ),
        _goalTypeItem(
          GoalType.duration,
          'Tiếng/Phút',
          _formatDuration(_duration),
        ),
        _goalTypeItem(
          GoalType.distance,
          'Quãng đường',
          '${_distanceKm.toStringAsFixed(1)} km',
        ),
        _goalTypeItem(
          GoalType.calories,
          'Năng lượng',
          '$_calories kcal',
        ),
      ],
    );
  }

  Widget _goalTypeItem(GoalType type, String label, String valueLabel) {
    final selected = _goalType == type;

    return _ChoiceCard(
      selected: selected,
      label: label,
      // chỉ ô đang chọn mới hiển thị giá trị
      subLabel: selected ? valueLabel : null,
      onTap: () => _onGoalTypeTap(type),
    );
  }

  /* ===================== POP-UP HANDLERS ===================== */

  Future<void> _onGoalTypeTap(GoalType type) async {
    switch (type) {
      case GoalType.frequency:
        final v = await _showIntSliderDialog(
          title: 'Đặt số buổi',
          min: 1,
          max: 14,
          initial: _frequency,
          unit: 'buổi',
        );
        if (v != null) {
          setState(() {
            _goalType = type;
            _frequency = v;
          });
        }
        break;

      case GoalType.duration:
        final d = await _showDurationDialog(
          title: 'Đặt thời lượng',
          initial: _duration,
        );
        if (d != null) {
          setState(() {
            _goalType = type;
            _duration = d;
          });
        }
        break;

      case GoalType.distance:
        final v = await _showDoubleSliderDialog(
          title: 'Đặt quãng đường',
          min: 0.5,
          max: 50,
          initial: _distanceKm,
          unit: 'km',
          step: 0.5,
        );
        if (v != null) {
          setState(() {
            _goalType = type;
            _distanceKm = v;
          });
        }
        break;

      case GoalType.calories:
        final v = await _showIntSliderDialog(
          title: 'Đặt năng lượng',
          min: 50,
          max: 3000,
          initial: _calories,
          unit: 'kcal',
          step: 50,
        );
        if (v != null) {
          setState(() {
            _goalType = type;
            _calories = v;
          });
        }
        break;
    }
  }

  /* ===================== DIALOGS ===================== */

  Future<int?> _showIntSliderDialog({
    required String title,
    required int min,
    required int max,
    required int initial,
    required String unit,
    int step = 1,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        int current = initial;
        if (current < min) current = min;
        if (current > max) current = max;

        final divisions = (max - min) ~/ step;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                height: 120,
                child: Column(
                  children: [
                    Text(
                      '$current $unit',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: current.toDouble(),
                      min: min.toDouble(),
                      max: max.toDouble(),
                      divisions: divisions > 0 ? divisions : null,
                      onChanged: (v) {
                        int newVal = (v / step).round() * step;
                        if (newVal < min) newVal = min;
                        if (newVal > max) newVal = max;
                        setStateDialog(() {
                          current = newVal;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, current),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<double?> _showDoubleSliderDialog({
    required String title,
    required double min,
    required double max,
    required double initial,
    required String unit,
    double step = 0.5,
  }) async {
    return showDialog<double>(
      context: context,
      builder: (ctx) {
        double current = initial;
        if (current < min) current = min;
        if (current > max) current = max;

        final divisions = ((max - min) / step).round();

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                height: 120,
                child: Column(
                  children: [
                    Text(
                      '${current.toStringAsFixed(1)} $unit',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: current,
                      min: min,
                      max: max,
                      divisions: divisions > 0 ? divisions : null,
                      onChanged: (v) {
                        final steps = (v / step).round();
                        double newVal = steps * step;
                        if (newVal < min) newVal = min;
                        if (newVal > max) newVal = max;
                        setStateDialog(() {
                          current = newVal;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, current),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Duration?> _showDurationDialog({
    required String title,
    required Duration initial,
  }) async {
    return showDialog<Duration>(
      context: context,
      builder: (ctx) {
        int hour = initial.inHours;
        if (hour < 0) hour = 0;
        if (hour > 23) hour = 23;

        int minute = initial.inMinutes % 60;
        if (minute < 0) minute = 0;
        if (minute > 59) minute = 59;

        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCupertinoNumberPicker(
                  initial: hour,
                  min: 0,
                  max: 23,
                  label: 'h',
                  onChanged: (v) => hour = v,
                ),
                _buildCupertinoNumberPicker(
                  initial: minute,
                  min: 0,
                  max: 59,
                  label: 'min',
                  onChanged: (v) => minute = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, Duration(hours: hour, minutes: minute)),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCupertinoNumberPicker({
    required int initial,
    required int min,
    required int max,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    int initialItem = initial - min;
    if (initialItem < 0) initialItem = 0;
    if (initialItem > max - min) initialItem = max - min;

    final controller = FixedExtentScrollController(initialItem: initialItem);

    return Column(
      children: [
        SizedBox(
          height: 120,
          width: 80,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 32,
            onSelectedItemChanged: (index) {
              onChanged(min + index);
            },
            children: [
              for (int v = min; v <= max; v++)
                Center(
                  child: Text(
                    v.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  /* ===================== SAVE ===================== */

  void _onSave() {
    final config = GoalConfig(
      activityType: _activityType,
      timeFrame: _timeFrame,
      goalType: _goalType,
      frequency: _frequency,
      duration: _duration,
      distanceKm: _distanceKm,
      calories: _calories,
    );

    Navigator.pop(context, config);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '$m phút';
    if (m == 0) return '$h giờ';
    return '${h}h ${m}m';
  }
}

/* ===================== CARD CHỌN CHUNG ===================== */

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.label,
    required this.onTap,
    this.icon,
    this.subLabel,
    this.fullWidth = false,
    this.borderRadius = 12,
    this.selectedColor,
  });

  final bool selected;
  final String label;
  final String? subLabel;
  final IconData? icon;
  final VoidCallback onTap;
  final bool fullWidth;
  final double borderRadius;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = selected ? cs.primary : cs.outlineVariant;
    final bgColor =
    selected ? (selectedColor ?? cs.primary.withOpacity(0.06)) : null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(height: 4),
        ],
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            subLabel!,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: cs.outline,
            ),
          ),
        ],
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          color: bgColor,
        ),
        child: Center(child: content),
      ),
    );
  }
}
