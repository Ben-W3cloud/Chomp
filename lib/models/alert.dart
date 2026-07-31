enum AlertSeverity { info, warning, critical }

extension AlertSeverityX on AlertSeverity {
  static AlertSeverity fromString(String? value) {
    switch (value) {
      case 'critical':
        return AlertSeverity.critical;
      case 'info':
        return AlertSeverity.info;
      case 'warning':
      default:
        return AlertSeverity.warning;
    }
  }
}

class ChompAlert {
  final String id;
  final String repoId;
  final String scanResultId;
  final String message;
  final AlertSeverity severity;
  final bool resolved;
  final DateTime createdAt;

  const ChompAlert({
    required this.id,
    required this.repoId,
    required this.scanResultId,
    required this.message,
    required this.severity,
    required this.resolved,
    required this.createdAt,
  });

  factory ChompAlert.fromJson(Map<String, dynamic> json) => ChompAlert(
        id: json['id'] as String,
        repoId: json['repo_id'] as String,
        scanResultId: json['scan_result_id'] as String,
        message: json['message'] as String,
        severity: AlertSeverityX.fromString(json['severity'] as String?),
        resolved: json['resolved'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
