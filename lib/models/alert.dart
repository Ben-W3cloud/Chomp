enum AlertSeverity { info, warning, critical }

/// Extension methods for [AlertSeverity].
///
/// Provides conversion between enum values and string representations
/// for JSON serialization/deserialization.
extension AlertSeverityX on AlertSeverity {
  /// Creates an [AlertSeverity] from a string value.
  /// Defaults to [AlertSeverity.warning] if the value is unrecognized.
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

/// Individual alert/notification about a repository finding.
///
/// Created by the server when a scan discovers new issues or when
/// a security score drops below the configured threshold.
class ChompAlert {
  /// Unique identifier for this alert.
  final String id;

  /// Foreign key to the repository this alert is for.
  final String repoId;

  /// Foreign key to the scan result that triggered this alert.
  final String scanResultId;

  /// Human-readable description of the issue.
  final String message;

  /// Severity level of this alert.
  final AlertSeverity severity;

  /// Whether this alert has been marked as resolved by the user.
  final bool resolved;

  /// Timestamp when the alert was created.
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

  /// Creates a [ChompAlert] from a JSON map returned by the backend.
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
