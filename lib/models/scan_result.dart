enum QualitativeRating { critical, poor, standard, good, great, excellent }

extension QualitativeRatingX on QualitativeRating {
  static QualitativeRating fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'excellent':
        return QualitativeRating.excellent;
      case 'great':
        return QualitativeRating.great;
      case 'good':
        return QualitativeRating.good;
      case 'standard':
        return QualitativeRating.standard;
      case 'poor':
        return QualitativeRating.poor;
      case 'critical':
      default:
        return QualitativeRating.critical;
    }
  }

  String get label {
    switch (this) {
      case QualitativeRating.excellent:
        return 'Excellent';
      case QualitativeRating.great:
        return 'Great';
      case QualitativeRating.good:
        return 'Good';
      case QualitativeRating.standard:
        return 'Standard';
      case QualitativeRating.poor:
        return 'Poor';
      case QualitativeRating.critical:
        return 'Critical';
    }
  }
}

class ScanResult {
  final String id;
  final String repoId;
  final int? securityScore;
  final int? codeQualityScore;
  final QualitativeRating? docsRating;
  final QualitativeRating? testsRating;
  final List<String> findings;
  final DateTime scannedAt;

  const ScanResult({
    required this.id,
    required this.repoId,
    this.securityScore,
    this.codeQualityScore,
    this.docsRating,
    this.testsRating,
    this.findings = const [],
    required this.scannedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        id: json['id'] as String,
        repoId: json['repo_id'] as String,
        securityScore: json['security_score'] as int?,
        codeQualityScore: json['code_quality_score'] as int?,
        docsRating: json['docs_rating'] != null
            ? QualitativeRatingX.fromLabel(json['docs_rating'] as String)
            : null,
        testsRating: json['tests_rating'] != null
            ? QualitativeRatingX.fromLabel(json['tests_rating'] as String)
            : null,
        findings: (json['findings'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        scannedAt: DateTime.parse(json['scanned_at'] as String),
      );
}
