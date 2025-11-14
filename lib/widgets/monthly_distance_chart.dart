import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyDistanceChart extends StatefulWidget {
  const MonthlyDistanceChart({super.key});

  @override
  State<MonthlyDistanceChart> createState() => _MonthlyDistanceChartState();
}

class _MonthlyDistanceChartState extends State<MonthlyDistanceChart> {
  List<double> _monthlyDistances = List.filled(12, 0.0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyDistances();
  }

  Future<void> _loadMonthlyDistances() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final year = now.year;

      // 各月のデータを取得
      for (int month = 1; month <= 12; month++) {
        final startDate = DateTime(year, month, 1);
        final endDate = month == 12
            ? DateTime(year + 1, 1, 1)
            : DateTime(year, month + 1, 1);

        final response = await Supabase.instance.client
            .from('routes')
            .select('distance')
            .eq('user_id', userId)
            .gte('created_at', startDate.toIso8601String())
            .lt('created_at', endDate.toIso8601String());

        double totalDistance = 0;
        for (var route in response) {
          totalDistance += (route['distance'] as num).toDouble();
        }

        setState(() {
          _monthlyDistances[month - 1] = totalDistance / 1000; // km単位
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('月間距離データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxDistance = _monthlyDistances.reduce((a, b) => a > b ? a : b);
    final maxY = maxDistance > 0 ? (maxDistance * 1.2).ceilToDouble() : 10.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '月間走行距離 (${DateTime.now().year}年)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: List.generate(
                    12,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _monthlyDistances[index],
                          color: Colors.blue,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\${value.toInt()}km',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            '1月',
                            '2月',
                            '3月',
                            '4月',
                            '5月',
                            '6月',
                            '7月',
                            '8月',
                            '9月',
                            '10月',
                            '11月',
                            '12月'
                          ];
                          if (value.toInt() >= 0 && value.toInt() < 12) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()],
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
