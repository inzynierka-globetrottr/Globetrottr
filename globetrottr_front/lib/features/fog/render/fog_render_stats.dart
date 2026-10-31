/// Rolling record of how long the fog layer takes to paint, for the
/// developer diagnostics panel.
class FogRenderStats {
  FogRenderStats({this.window = 120});

  final int window;
  final List<int> _micros = [];
  int _frames = 0;

  int get frames => _frames;

  void record(int micros) {
    _frames++;
    _micros.add(micros);
    if (_micros.length > window) _micros.removeAt(0);
  }

  double get averageMillis {
    if (_micros.isEmpty) return 0;
    return _micros.reduce((a, b) => a + b) / _micros.length / 1000.0;
  }

  double get maxMillis {
    if (_micros.isEmpty) return 0;
    return _micros.reduce((a, b) => a > b ? a : b) / 1000.0;
  }
}
