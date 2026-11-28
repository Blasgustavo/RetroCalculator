class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.profileId,
    required this.timestamp,
  });

  final String expression;
  final double result;
  final String profileId;
  final DateTime timestamp;

  Map<String, Object?> toJson() => <String, Object?>{
    'expression': expression,
    'result': result,
    'profileId': profileId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, Object?> json) {
    return HistoryEntry(
      expression: json['expression']! as String,
      result: (json['result']! as num).toDouble(),
      profileId: (json['profileId'] as String?) ?? 'normal',
      timestamp: DateTime.parse(json['timestamp']! as String),
    );
  }
}
