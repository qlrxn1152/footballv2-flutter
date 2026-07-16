import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_navigation.dart';
import '../data/daily_analytics_repository.dart';
import '../data/daily_visit_summary.dart';

class DailyAnalyticsScreen extends ConsumerStatefulWidget {
  const DailyAnalyticsScreen({this.initialDate, super.key});

  final DateTime? initialDate;

  @override
  ConsumerState<DailyAnalyticsScreen> createState() =>
      _DailyAnalyticsScreenState();
}

class _DailyAnalyticsScreenState extends ConsumerState<DailyAnalyticsScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final initialDate = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
  }

  String get _dateKey {
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    return '${_selectedDate.year}-$month-$day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _changeDate(int days) {
    final next = _selectedDate.add(Duration(days: days));
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (next.isAfter(todayOnly)) return;
    setState(() => _selectedDate = next);
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(dailyVisitSummaryProvider(_dateKey));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '일별 사용 통계',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(
              dailyVisitSummaryProvider(_dateKey),
            ),
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const FootballPageNavigationBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _DateSelector(
            dateLabel: _dateKey,
            onPrevious: () => _changeDate(-1),
            onNext: () => _changeDate(1),
            onPickDate: _pickDate,
          ),
          const SizedBox(height: 18),
          summary.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(42),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => _ErrorCard(
              message: error.toString(),
              onRetry: () => ref.invalidate(
                dailyVisitSummaryProvider(_dateKey),
              ),
            ),
            data: (item) => _SummaryContent(summary: item),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.dateLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  final String dateLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: '이전 날짜',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_outlined),
                      const SizedBox(width: 9),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: '다음 날짜',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.summary});

  final DailyVisitSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricCard(
          icon: Icons.people_alt_outlined,
          label: '순 사용자',
          value: '${summary.uniqueVisitors}명',
          description: '해당 날짜에 앱을 이용한 중복 제외 사용자',
        ),
        const SizedBox(height: 12),
        _MetricCard(
          icon: Icons.visibility_outlined,
          label: '페이지 조회',
          value: '${summary.pageViews}회',
          description: '해당 날짜에 발생한 PAGE_VIEW 요청 수',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, color: colors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 34),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
