import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyCountChart extends StatefulWidget {
  const WeeklyCountChart({super.key});

  @override
  State<WeeklyCountChart> createState() => _WeeklyCountChartState();
}

class _WeeklyCountChartState extends State<WeeklyCountChart> {
  List<int> _weeklyCounts = [];
  List<String> _weekLabels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyCounts();
  }

  Future<void> _loadWeeklyCounts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      // 今月の週数を計算
      final weeksInMonth = _getWeeksInMonth(currentMonth);
      List<int> counts = List.filled(weeksInMonth, 0);
      List<String> labels = [];

      for (int week = 0; week < weeksInMonth; week++) {
        final weekStart = currentMonth.add(Duration(days: week * 7));
        final weekEnd = weekStart.add(const Duration(days: 7));

        final response = await Supabase.instance.client
            .from('routes')
            .select('id')
            .eq('user_id', userId)
            .gte('created_at', weekStart.toIso8601String())
            .lt('created_at', weekEnd.toIso8601String());

        counts[week] = response.length;
        labels.add('第\${week + 1}週');
      }

      setState(() {
        _weeklyCounts = counts;
        _weekLabels = labels;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('週間カウントデータ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _getWeeksInMonth(DateTime month) {
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = nextMonth.difference(month).inDays;
    return (daysInMonth / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weeklyCounts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('データがありません'),
        ),
      );
    }

    final maxCount = _weeklyCounts.reduce((a, b) => a > b ? a : b);
    final maxY = maxCount > 0 ? (maxCount * 1.2).ceilToDouble() : 5.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '週間散歩回数 (今月)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        _weeklyCounts.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          _weeklyCounts[index].toDouble(),
                        ),
                      ),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\${value.toInt()}回',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weekLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _weekLabels[index],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
