import 'package:flutter/material.dart';
import '../../activity/domain/activity_kind.dart'; // điều chỉnh path nếu bạn đặt khác
// Nếu cấu trúc bạn là lib/features/activity/domain, dùng:
// import 'package:app_fitness/features/activity/domain/activity_kind.dart';

class ActivityDrawer extends StatefulWidget {
  final ActivityKind selected;
  final ValueChanged<ActivityKind> onSelect;
  const ActivityDrawer({super.key, required this.selected, required this.onSelect});

  @override
  State<ActivityDrawer> createState() => _ActivityDrawerState();
}

class _ActivityDrawerState extends State<ActivityDrawer> {
  final _controller = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width * 0.78;

    // Tự động lấy toàn bộ hoạt động từ enum
    List<ActivityKind> all = ActivityKind.values;
    if (_q.isNotEmpty) {
      all = all.where((k) => k.label.toLowerCase().contains(_q.toLowerCase())).toList();
    }
    final inPlace = all.where((k) => !k.isGps).toList();
    final gps     = all.where((k) =>  k.isGps).toList();

    ListTile item(ActivityKind k) => ListTile(
      dense: true,
      leading: Icon(k.icon),
      title: Text(k.label, style: const TextStyle(fontWeight: FontWeight.w600)),
      selected: k == widget.selected,
      selectedTileColor: cs.secondaryContainer.withOpacity(0.35),
      trailing: k == widget.selected ? Icon(Icons.check_circle_rounded, color: cs.secondary) : null,
      onTap: () => widget.onSelect(k),
    );

    Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(t, style: Theme.of(context).textTheme.labelLarge),
    );

    return Drawer(
      width: width,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Các hoạt động khác',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _controller,
                onChanged: (s) => setState(() => _q = s),
                decoration: InputDecoration(
                  hintText: 'Tìm hoạt động…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // List
            Expanded(
              child: ListView(
                children: [
                  if (inPlace.isNotEmpty) ...[
                    sectionTitle('Tập tại chỗ'),
                    for (final k in inPlace) item(k),
                    const Divider(height: 1),
                  ],
                  sectionTitle('Có di chuyển (GPS)'),
                  for (final k in gps) item(k),
                ],
              ),
            ),

            const Divider(height: 1),

            // Footer hint
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thể hình/Yoga dùng MET cố định; Chạy/Đi dùng GPS.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
