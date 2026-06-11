import 'scan_result.dart';

class HistoryEntry {
  final ScanResult result;
  final DateTime scanDate;

  HistoryEntry({required this.result, required this.scanDate});

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      result: ScanResult.fromJson(json['result'] ?? {}),
      scanDate: DateTime.parse(json['scanDate'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'result': result.toJson(),
    'scanDate': scanDate.toIso8601String(),
  };
}
