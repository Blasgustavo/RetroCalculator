import '../../domain/profiles/calculator_profile.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.profileId,
    required this.timestamp,
  });

  final String expression;
  final double result;
  final CalculatorProfileId profileId;
  final DateTime timestamp;

  Map<String, Object?> toJson() => <String, Object?>{
    'expression': expression,
    'result': result,
    'profileId': profileId.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, Object?> json) {
    return HistoryEntry(
      expression: json['expression']! as String,
      result: (json['result']! as num).toDouble(),
      profileId: CalculatorProfileId.values.firstWhere(
        (CalculatorProfileId id) => id.name == json['profileId'],
      ),
      timestamp: DateTime.parse(json['timestamp']! as String),
    );
  }
}
