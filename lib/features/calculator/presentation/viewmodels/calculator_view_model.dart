import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/calculator_exception.dart';
import '../../../../core/i18n/number_formatting.dart';
import '../../data/local/history_store.dart';
import '../../data/local/local_counters.dart';
import '../../data/models/history_entry.dart';
import '../../domain/engine/angle_mode.dart';
import '../../domain/engine/calculator_engine.dart';
import '../../domain/profiles/calculator_profile.dart';
import '../../domain/profiles/profiles.dart';

class CalculatorViewModel extends ChangeNotifier {
  CalculatorViewModel(this._history, this._counters) {
    unawaited(loadHistory());
  }

  final HistoryStore _history;
  final LocalCounters _counters;
  final CalculatorEngine _engine = const CalculatorEngine();

  CalculatorProfile _profile = CalculatorProfiles.normal;
  AngleMode _angleMode = AngleMode.degrees;
  DecimalSeparator _separator = DecimalSeparator.comma;
  String _expression = '';
  String? _errorKey;
  double? _lastResult;
  double _memory = 0;
  List<HistoryEntry> _historyEntries = <HistoryEntry>[];

  CalculatorProfile get profile => _profile;
  AngleMode get angleMode => _angleMode;
  String? get errorKey => _errorKey;
  List<HistoryEntry> get history =>
      List<HistoryEntry>.unmodifiable(_historyEntries);
  String get expressionText => _expression.isEmpty ? '0' : _expression;
  String get displayText => _errorKey != null
      ? ''
      : _lastResult == null
      ? expressionText
      : _format(_lastResult!);

  void setLocaleName(String localeName) {
    final DecimalSeparator next = separatorForLocale(localeName);
    if (next == _separator) {
      return;
    }
    _separator = next;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _historyEntries = await _history.load();
    notifyListeners();
  }

  void input(String key) {
    switch (key) {
      case '=':
        unawaited(submit());
      case 'C':
        _clear();
      case '⌫':
        _backspace();
      case '±':
        _toggleSign();
      case 'MODE':
        toggleProfile();
      case 'DEG':
        setAngleMode(AngleMode.degrees);
      case 'RAD':
        setAngleMode(AngleMode.radians);
      case 'MC':
        _memory = 0;
      case 'MR':
        _append(_format(_memory));
      case 'M+':
        _memory += _lastResult ?? 0;
      case 'M-':
        _memory -= _lastResult ?? 0;
      default:
        _append(_canonical(key));
    }
  }

  void toggleProfile() {
    _profile = _profile.isScientific
        ? CalculatorProfiles.normal
        : CalculatorProfiles.scientific;
    if (_profile.isScientific) {
      _counters.increment(LocalCounters.scientificModeActivated);
    }
    _clear();
  }

  void setAngleMode(AngleMode mode) {
    if (_angleMode == mode) {
      return;
    }
    _angleMode = mode;
    _counters.increment(LocalCounters.angleModeChanged);
    notifyListeners();
  }

  Future<void> submit() async {
    if (_expression.trim().isEmpty) {
      _errorKey = 'emptyExpression';
      notifyListeners();
      return;
    }
    try {
      final double result = _engine.evaluate(
        _expression,
        _profile,
        angleMode: _angleMode,
      );
      await _history.append(
        HistoryEntry(
          expression: _expression,
          result: result,
          profileId: _profile.id,
          timestamp: DateTime.now(),
        ),
      );
      _historyEntries = await _history.load();
      _lastResult = result;
      _errorKey = null;
      _counters.increment(LocalCounters.calculationPerformed);
    } on CalculatorException catch (error) {
      _errorKey = error.message;
      _counters.increment(LocalCounters.calculationFailed);
    }
    notifyListeners();
  }

  String _canonical(String key) {
    return switch (key) {
      'π' => 'pi',
      'x^y' => '^',
      '√' => 'sqrt(',
      'n!' => '!',
      '1/x' => 'inv(',
      'x²' => 'sqr(',
      _ => key,
    };
  }

  void _append(String token) {
    _expression += token;
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  void _clear() {
    _expression = '';
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  void _backspace() {
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  void _toggleSign() {
    _expression = _expression.isEmpty ? '-' : '-$_expression';
    _errorKey = null;
    _lastResult = null;
    notifyListeners();
  }

  String _format(double value) {
    return formatNumber(
      value,
      separator: _separator,
      maxFractionDigits: _profile.decimalDigits,
    );
  }
}
