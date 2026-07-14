class DailyVisitSummary {
  const DailyVisitSummary({
    required this.date,
    required this.uniqueVisitors,
    required this.pageViews,
  });

  final DateTime date;
  final int uniqueVisitors;
  final int pageViews;

  factory DailyVisitSummary.fromJson(Map<String, dynamic> json) {
    return DailyVisitSummary(
      date: DateTime.parse(json['date'] as String),
      uniqueVisitors: (json['uniqueVisitors'] as num).toInt(),
      pageViews: (json['pageViews'] as num).toInt(),
    );
  }
}
