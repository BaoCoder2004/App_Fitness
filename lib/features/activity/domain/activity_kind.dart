import 'package:flutter/material.dart';

enum ActivityKind { run, walk, strength, yoga }

extension ActivityKindX on ActivityKind {
  String get label {
    switch (this) {
      case ActivityKind.run:      return 'Chạy bộ';
      case ActivityKind.walk:     return 'Đi bộ';
      case ActivityKind.strength: return 'Thể hình';
      case ActivityKind.yoga:     return 'Yoga';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityKind.run:      return Icons.directions_run_rounded;
      case ActivityKind.walk:     return Icons.directions_walk_rounded;
      case ActivityKind.strength: return Icons.fitness_center_rounded;
      case ActivityKind.yoga:     return Icons.self_improvement_rounded;
    }
  }

  /// Hoạt động có di chuyển (cần GPS + map)
  bool get isGps => this == ActivityKind.run || this == ActivityKind.walk;

  /// MET mặc định cho hoạt động tại chỗ (GPS sẽ tính theo tốc độ)
  double get met {
    switch (this) {
      case ActivityKind.run:      return 8.8; // fallback
      case ActivityKind.walk:     return 3.5;
      case ActivityKind.strength: return 6.0;
      case ActivityKind.yoga:     return 3.0;
    }
  }
}
