import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A smooth wander unique to each circle. Seeded from the id, so a circle and
/// the ends of its links share one offset.
class NodeDrift {
  const NodeDrift._();

  static const reach = 5.2;

  static Offset at(String id, double seconds) {
    final seed = _hash(id);
    final x =
        _wave(seed, 1, seconds, 0.31) * 0.52 +
        _wave(seed, 2, seconds, 0.67) * 0.31 +
        _wave(seed, 3, seconds, 1.05) * 0.17;
    final y =
        _wave(seed, 4, seconds, 0.29) * 0.52 +
        _wave(seed, 5, seconds, 0.73) * 0.31 +
        _wave(seed, 6, seconds, 1.11) * 0.17;
    return Offset(x * reach, y * reach);
  }

  static double _wave(int seed, int salt, double seconds, double speed) {
    final phase = _unit(seed, salt) * math.pi * 2;
    final pace = speed * (0.75 + _unit(seed, salt + 17).abs() * 0.7);
    return math.sin(seconds * pace + phase);
  }

  static int _hash(String id) {
    var hash = 2166136261;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  static double _unit(int seed, int salt) {
    var hash = (seed ^ (salt * 0x45d9f3b)) & 0x7fffffff;
    hash = (hash ^ (hash >> 16)) * 0x7feb352d;
    hash = (hash ^ (hash >> 15)) & 0x7fffffff;
    return ((hash & 0xffff) / 0xffff) * 2 - 1;
  }
}
