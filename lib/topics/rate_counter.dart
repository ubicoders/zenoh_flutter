import 'dart:collection';

/// Counts events in a sliding window (1 s by default) to report a rate in Hz.
///
/// Pure Dart; pass `now` explicitly for deterministic tests.
class RateCounter {
  RateCounter({this.window = const Duration(seconds: 1)});

  final Duration window;
  final Queue<int> _stamps = ListQueue<int>(); // microseconds since epoch
  int _total = 0;

  /// Number of ticks since creation (or the last [reset]).
  int get total => _total;

  /// Records one event at [now] (defaults to the current time).
  void tick([DateTime? now]) {
    final t = (now ?? DateTime.now()).microsecondsSinceEpoch;
    _stamps.addLast(t);
    _total++;
    _purge(t);
  }

  /// Events per second over the window ending at [now].
  double hz([DateTime? now]) {
    _purge((now ?? DateTime.now()).microsecondsSinceEpoch);
    return _stamps.length *
        Duration.microsecondsPerSecond /
        window.inMicroseconds;
  }

  void reset() {
    _stamps.clear();
    _total = 0;
  }

  void _purge(int nowMicros) {
    final cutoff = nowMicros - window.inMicroseconds;
    while (_stamps.isNotEmpty && _stamps.first <= cutoff) {
      _stamps.removeFirst();
    }
  }
}
