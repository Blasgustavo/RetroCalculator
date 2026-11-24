class LocalCounters {
  static const String calculationPerformed = 'calculation_performed';
  static const String scientificModeActivated = 'scientific_mode_activated';
  static const String calculationFailed = 'calculation_failed';
  static const String angleModeChanged = 'angle_mode_changed';

  final Map<String, int> _values = <String, int>{};

  void increment(String key) {
    _values[key] = (_values[key] ?? 0) + 1;
  }

  int value(String key) => _values[key] ?? 0;

  Map<String, int> snapshot() => Map<String, int>.unmodifiable(_values);
}
