import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// DÙNG package import cho chắc đường dẫn (đổi app_fitness nếu tên package khác)
import 'package:app_fitness/features/activity/domain/activity_kind.dart';
import 'package:app_fitness/features/activity/presentation/activity_drawer.dart';

/// Dữ liệu mục tiêu hôm nay (nhận từ màn Thống kê)
class DailyGoal {
  final Duration target;
  final Duration progress;
  const DailyGoal({required this.target, required this.progress});
  static const DailyGoal default30 =
  DailyGoal(target: Duration(minutes: 30), progress: Duration.zero);
}

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key, this.dailyGoal});
  final ValueListenable<DailyGoal>? dailyGoal;

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Map & GPS
  final MapController _map = MapController();
  final Distance _dist = const Distance();
  LatLng? _current;
  double? _accuracy;
  StreamSubscription<Position>? _gpsSub;
  bool _serviceEnabled = true;
  LocationPermission? _perm;

  // Trạng thái phiên
  bool _isTracking = false;
  bool _hasStarted = false;
  bool _wasMoving = false;

  // Tuyến đường
  final List<List<LatLng>> _segments = [];
  int _activeSeg = -1;

  double _distanceMeters = 0;
  LatLng? _lastAccepted;
  LatLng? _lastRaw;
  DateTime? _lastObsAt;

  LatLng? _startMarker;
  LatLng? _endMarker;

  // Timer & thống kê
  Timer? _timer;                 // timer cho phiên
  Timer? _clockTimer;            // đồng hồ màn hình (cập nhật 1s)
  DateTime _now = DateTime.now();
  Duration _elapsed = Duration.zero;
  Duration _moving  = Duration.zero;

  // kcal (MET)
  final double _userWeightKg = 65;
  double _kcal = 0;

  ActivityKind _activity = ActivityKind.run;

  // Ngưỡng
  static const double _kMinSegMeters = 5.0;
  static const double _kMinSpeedMps  = 0.8;
  static const double _kMaxHumanMps  = 12.0;
  static const double _kMaxAccuracy  = 20.0;

  // EMA tốc độ
  double? _speedEma;
  static const double _kSpeedTau = 3.0;

  // Goal
  late DailyGoal _dailyGoal;

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.dailyGoal?.value ?? DailyGoal.default30;
    widget.dailyGoal?.addListener(_onGoalChanged);
    if (_activity.isGps) _initLocation();

    // Đồng hồ HH:mm cho layout “tại chỗ”
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant ActivityTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyGoal != widget.dailyGoal) {
      oldWidget.dailyGoal?.removeListener(_onGoalChanged);
      _dailyGoal = widget.dailyGoal?.value ?? _dailyGoal;
      widget.dailyGoal?.addListener(_onGoalChanged);
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.dailyGoal?.removeListener(_onGoalChanged);
    _gpsSub?.cancel();
    _timer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onGoalChanged() {
    final v = widget.dailyGoal?.value;
    if (v != null) setState(() => _dailyGoal = v);
  }

  /* ================== Location ================== */

  Future<void> _initLocation() async {
    try {
      if (!_activity.isGps) return;

      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) { setState(() {}); return; }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      _perm = p;
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) { setState(() {}); return; }

      final first = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      _onPosition(first);
      _map.move(LatLng(first.latitude, first.longitude), 16);

      await _gpsSub?.cancel();
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen(_onPosition, onError: (_) {});
    } catch (_) { setState(() {}); }
  }

  Future<void> _stopLocation() async {
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  void _onPosition(Position pos) {
    if (!_activity.isGps) return;

    final here = LatLng(pos.latitude, pos.longitude);
    _current = here;
    _accuracy = pos.accuracy;

    final accOk = _accuracy != null && _accuracy! <= _kMaxAccuracy;

    if (mounted && _map.camera.zoom < 14) _map.move(here, 16);

    if (!_isTracking || !accOk) {
      _lastObsAt = DateTime.now();
      _lastRaw = here;
      if (mounted) setState(() {});
      return;
    }

    final nowT = DateTime.now();
    final prevT = _lastObsAt;
    double segSec = 0.0;
    if (prevT != null) {
      final ds = (nowT.difference(prevT).inMilliseconds / 1000.0);
      if (ds.isFinite) segSec = ds.clamp(0.0, 60.0);
    }

    double segMetersRaw = 0.0;
    if (_lastRaw != null) {
      segMetersRaw = _dist.as(LengthUnit.Meter, _lastRaw!, here);
    }

    final speedInst = (pos.speed.isFinite && pos.speed > 0)
        ? pos.speed
        : (segSec > 0 ? segMetersRaw / segSec : 0.0);

    if (_speedEma == null) {
      _speedEma = speedInst;
    } else {
      final alpha = segSec > 0 ? segSec / (_kSpeedTau + segSec) : 1.0;
      _speedEma = _speedEma! + alpha * (speedInst - _speedEma!);
    }
    final speedSm = (_speedEma ?? 0).clamp(0.0, _kMaxHumanMps);

    final isMoving = speedSm >= _kMinSpeedMps && segSec > 0;

    if (isMoving) {
      _moving += Duration(milliseconds: (segSec * 1000).round());
    }

    double segMetersAccepted = 0.0;
    bool accept = false;
    if (_lastAccepted != null) {
      segMetersAccepted = _dist.as(LengthUnit.Meter, _lastAccepted!, here);
      accept = _acceptPoint(
        segMeters: segMetersAccepted,
        speed: speedSm,
        accuracy: _accuracy ?? 50.0,
        isMoving: isMoving,
      );
    }

    if (accept) {
      if (segMetersAccepted >= _kMinSegMeters) {
        _distanceMeters += segMetersAccepted;
      }
      if (isMoving && segMetersAccepted >= _kMinSegMeters) {
        final vMPerMin = speedSm * 60.0;
        final met = _metFromContext(vMPerMin);
        final segMin = segSec / 60.0;
        _kcal += (met * 3.5 * _userWeightKg / 200.0) * segMin;
      }
      _appendPointToActiveSegment(here);
      _lastAccepted = here;
    }

    if (!isMoving && _wasMoving && _lastAccepted != null) {
      final minStep = math.max(_kMinSegMeters, (_accuracy ?? 50.0) * 0.5);
      final segStop = _dist.as(LengthUnit.Meter, _lastAccepted!, here);
      if (segStop >= minStep) {
        _distanceMeters += segStop;
        _appendPointToActiveSegment(here);
        _lastAccepted = here;
      }
    }

    _lastObsAt = nowT;
    _lastRaw = here;
    _wasMoving = isMoving;

    if (mounted) setState(() {});
  }

  bool _acceptPoint({
    required double segMeters,
    required double speed,
    required double accuracy,
    required bool isMoving,
  }) {
    if (segMeters > 200 && speed < 2.0) return false;
    if (speed > _kMaxHumanMps) return false;
    if (accuracy > _kMaxAccuracy) return false;
    final minStep = math.max(_kMinSegMeters, accuracy * 0.5);
    return (segMeters >= minStep && isMoving) || speed >= _kMinSpeedMps * 2;
  }

  void _startNewSegment(LatLng seed) {
    _segments.add([seed]);
    _activeSeg = _segments.length - 1;
  }

  void _appendPointToActiveSegment(LatLng p) {
    if (_activeSeg < 0) _startNewSegment(p);
    else _segments[_activeSeg].add(p);
  }

  Future<LatLng?> _captureFix() async {
    if (_current != null && (_accuracy ?? 999) <= _kMaxAccuracy) return _current;
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 8),
      );
      _current = LatLng(p.latitude, p.longitude);
      _accuracy = p.accuracy;
      if ((_accuracy ?? 999) <= _kMaxAccuracy) return _current;
    } catch (_) {}
    return null;
  }

  void _snapEndAt(LatLng fix, {required bool addDistance}) {
    if (_activeSeg < 0 || _lastAccepted == null) return;
    final minStep = math.max(_kMinSegMeters, (_accuracy ?? 50.0) * 0.5);
    final seg = _dist.as(LengthUnit.Meter, _lastAccepted!, fix);
    if (seg >= minStep) {
      if (addDistance) _distanceMeters += seg;
      _segments[_activeSeg].add(fix);
      _lastAccepted = fix;
    }
  }

  void _recenter() {
    if (!_activity.isGps) return;
    if (_current != null) _map.move(_current!, 16);
    else _initLocation();
  }

  /* ================== MET (kcal) ================== */
  double _metFromContext(double vMPerMin) {
    switch (_activity) {
      case ActivityKind.walk:
        final vo2w = 0.1 * vMPerMin + 3.5; return vo2w / 3.5;
      case ActivityKind.run:
        final vo2r = 0.2 * vMPerMin + 3.5; return vo2r / 3.5;
      case ActivityKind.strength: return 6.0;
      case ActivityKind.yoga:     return 3.0;
    }
  }

  /* ================== Controls ================== */

  Future<void> _start() async {
    if (_isTracking) return;

    // TẠI CHỖ
    if (!_activity.isGps) {
      if (!_hasStarted) {
        _resetMetricsForNewSession(keepMap: false);
        _hasStarted = true;
      }
      _isTracking = true;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isTracking) {
          setState(() {
            _elapsed += const Duration(seconds: 1);
            _kcal += (_activity.met * 3.5 * _userWeightKg / 200.0) / 60.0;
          });
        }
      });
      setState(() {});
      return;
    }

    // GPS
    final fix = await _captureFix();
    if (fix == null) {
      _showSnack('Không thể lấy toạ độ đủ chính xác (≤ ${_kMaxAccuracy.toStringAsFixed(0)}m).');
      return;
    }

    if (!_hasStarted) {
      _resetMetricsForNewSession(keepMap: true);
      _startMarker = fix;
      _endMarker = null;

      _segments.clear();
      _startNewSegment(fix);
      _lastAccepted = fix;
      _lastRaw = fix;
      _lastObsAt = DateTime.now();
      _speedEma = null;
      _wasMoving = false;

      _hasStarted = true;
    } else {
      _startNewSegment(fix);
      _lastAccepted = fix;
      _lastRaw = fix;
      _lastObsAt = DateTime.now();
      _speedEma = null;
      _wasMoving = false;
    }

    _isTracking = true;
    _map.move(fix, 17);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking) setState(() => _elapsed += const Duration(seconds: 1));
    });
    setState(() {});
  }

  void _pause() {
    if (!_isTracking) return;
    _isTracking = false;
    _timer?.cancel();
    setState(() {});
  }

  Future<void> _finish() async {
    if (!_hasStarted) {
      _showSnack('Chưa có phiên nào để hoàn thành.');
      return;
    }

    if (_activity.isGps) {
      final fix = await _captureFix();
      if (fix != null && _isTracking) {
        _snapEndAt(fix, addDistance: true);
        _endMarker = fix;
      }
    }
    // TODO: lưu thống kê nếu cần

    _resetAll();
    setState(() {});
  }

  void _resetMetricsForNewSession({required bool keepMap}) {
    _elapsed = Duration.zero;
    _moving  = Duration.zero;
    _distanceMeters = 0;
    _kcal = 0;
    _speedEma = null;
    _wasMoving = false;

    if (!keepMap) {
      _segments.clear();
      _activeSeg = -1;
      _lastAccepted = null;
      _lastRaw = null;
      _lastObsAt = null;
      _startMarker = null;
      _endMarker = null;
    }
  }

  void _resetAll() {
    _isTracking = false;
    _hasStarted = false;
    _wasMoving = false;

    _segments.clear();
    _activeSeg = -1;

    _distanceMeters = 0;
    _lastAccepted = null;
    _lastRaw = null;
    _lastObsAt = null;

    _startMarker = null;
    _endMarker = null;

    _timer?.cancel();
    _elapsed = Duration.zero;
    _moving  = Duration.zero;
    _kcal    = 0;
    _speedEma = null;
  }

  /* =========== Đổi hoạt động từ Sidebar =========== */

  Future<void> _onSelectActivity(ActivityKind k) async {
    if (_isTracking || _hasStarted) {
      _showSnack('Đang có phiên hoạt động. Tạm dừng/Hoàn thành trước khi đổi.');
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _activity = k);
    Navigator.of(context).maybePop();

    if (_activity.isGps) {
      await _initLocation();
    } else {
      await _stopLocation();
      setState(() {
        _segments.clear(); _activeSeg = -1;
        _startMarker = null; _endMarker = null;
        _current = null; _accuracy = null; _perm = null;
      });
    }
  }

  /* ================== UI helpers ================== */

  String _fmtTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  String _fmtMMSS(Duration d) {
    final m = d.inMinutes, s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(m)}:${two(s)}';
  }

  String get _distanceKmStr => (_distanceMeters / 1000).toStringAsFixed(2);
  String get _kcalStr      => _kcal.toStringAsFixed(0);

  String get _avgSpeedStr {
    if (_moving.inSeconds == 0) return '0.00';
    final km = _distanceMeters / 1000.0;
    final h  = _moving.inSeconds / 3600.0;
    final v  = km / h;
    if (!v.isFinite) return '0.00';
    return v.clamp(0.0, 60.0).toStringAsFixed(2);
  }

  double get _goalProgress {
    final t = _dailyGoal.target.inSeconds;
    if (t <= 0) return 0;
    return (_dailyGoal.progress.inSeconds / t).clamp(0.0, 1.0);
  }

  String get _clockHHmm {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(_now.hour)}:${two(_now.minute)}';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGps = _activity.isGps;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.surface,
      drawerScrimColor: Colors.black.withOpacity(0.35),
      drawer: ActivityDrawer(
        selected: _activity,
        onSelect: _onSelectActivity,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header chung: TIMER + tiêu đề =====
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: 'Các hoạt động khác',
                    ),
                  ),
                  Column(
                    children: [
                      FittedBox(
                        child: Text(
                          _fmtTime(_elapsed),
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Thời gian', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),

                      // Hàng 3 số liệu:
                      // - GPS: Quãng đường | Năng lượng | Tốc độ TB
                      // - Tại chỗ: Giờ hiện tại | Năng lượng | Nhịp tim
                      Row(
                        children: [
                          if (isGps) ...[
                            Expanded(child: _Stat(label: 'Quãng đường (km)', value: _distanceKmStr)),
                            const SizedBox(width: 8),
                            Expanded(child: _Stat(label: 'Năng lượng (cal)', value: _kcalStr)),
                            const SizedBox(width: 8),
                            Expanded(child: _Stat(label: 'Tốc độ TB (km/h)', value: _avgSpeedStr)),
                          ] else ...[
                            Expanded(child: _Stat(label: 'Giờ', value: _clockHHmm)),
                            const SizedBox(width: 8),
                            Expanded(child: _Stat(label: 'Năng lượng (cal)', value: _kcalStr)),
                            const SizedBox(width: 8),
                            const Expanded(child: _Stat(label: 'Nhịp tim (bpm)', value: '-')),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ===== Thân giữa =====
            if (isGps)
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: const LatLng(0, 0),
                        initialZoom: 3,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app_fitness',
                          maxNativeZoom: 19,
                          maxZoom: 19,
                        ),
                        if (_segments.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              for (final seg in _segments)
                                if (seg.length > 1)
                                  Polyline(points: seg, strokeWidth: 4, color: cs.primary),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            if (_startMarker != null)
                              Marker(
                                point: _startMarker!,
                                width: 14, height: 14, alignment: Alignment.center,
                                child: _SmallDot(
                                  fill: Theme.of(context).colorScheme.tertiary,
                                  border: Colors.white,
                                  size: 12,
                                ),
                              ),
                            if (_endMarker != null)
                              Marker(
                                point: _endMarker!,
                                width: 14, height: 14, alignment: Alignment.center,
                                child: _SmallDot(
                                  fill: Theme.of(context).colorScheme.secondary,
                                  border: Colors.white,
                                  size: 12,
                                ),
                              ),
                            if (_current != null)
                              Marker(
                                point: _current!,
                                width: 20, height: 20, alignment: Alignment.center,
                                child: _RingDot(
                                  fill: cs.primary,
                                  ringColor: Colors.white,
                                  size: 16,
                                  ringWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // Attribution
                    Positioned(
                      left: 8, bottom: 88,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text('© OpenStreetMap contributors', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ),

                    // Goal card
                    Positioned(
                      left: 16, top: 12, right: 16,
                      child: _GoalCard(
                        progress: _goalProgress,
                        label: 'Mục tiêu hôm nay',
                        trailing: '${_fmtMMSS(_dailyGoal.progress)}/${_fmtMMSS(_dailyGoal.target)}',
                      ),
                    ),

                    // Permission banner
                    if (!_serviceEnabled ||
                        _perm == LocationPermission.denied ||
                        _perm == LocationPermission.deniedForever)
                      Align(
                        alignment: Alignment.topCenter,
                        child: _PermissionBanner(
                          serviceEnabled: _serviceEnabled,
                          deniedForever: _perm == LocationPermission.deniedForever,
                          onRetry: _initLocation,
                        ),
                      ),

                    // Recenter
                    Positioned(
                      right: 16, bottom: 16,
                      child: FloatingActionButton.small(
                        onPressed: _recenter,
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _GoalCard(
                        progress: _goalProgress,
                        label: 'Mục tiêu hôm nay',
                        trailing: '${_fmtMMSS(_dailyGoal.progress)}/${_fmtMMSS(_dailyGoal.target)}',
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),

            // ===== Controls =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isTracking ? _pause : null,
                        child: _btnLabel('TẠM DỪNG'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isTracking ? null : _start,
                        child: _btnLabel(_hasStarted ? 'TIẾP TỤC' : 'BẮT ĐẦU'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _finish,
                        child: _btnLabel('HOÀN THÀNH'),
                      ),
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

  Widget _btnLabel(String text) =>
      Text(text, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis);
}

/* ================== UI atoms ================== */

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold, color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SmallDot extends StatelessWidget {
  final Color fill;
  final Color border;
  final double size;
  const _SmallDot({required this.fill, required this.border, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: fill, shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4, offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _RingDot extends StatelessWidget {
  final Color fill;
  final Color ringColor;
  final double size;
  final double ringWidth;
  const _RingDot({
    required this.fill,
    required this.ringColor,
    this.size = 16,
    this.ringWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: fill, shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: ringWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final double progress;
  final String label;
  final String trailing;
  const _GoalCard({required this.progress, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 2, color: cs.surface, borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trailing,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final bool serviceEnabled;
  final bool deniedForever;
  final VoidCallback onRetry;
  const _PermissionBanner({required this.serviceEnabled, required this.deniedForever, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = !serviceEnabled
        ? 'Hãy bật Dịch vụ Vị trí (GPS) để hiển thị bản đồ.'
        : deniedForever
        ? 'Bạn đã từ chối quyền Vị trí vĩnh viễn. Mở Cài đặt để cấp lại.'
        : 'Ứng dụng cần quyền Vị trí để hiển thị bản đồ.';
    return Material(
      color: cs.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.location_off, color: cs.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: TextStyle(color: cs.onErrorContainer))),
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}
