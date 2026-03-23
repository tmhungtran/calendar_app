import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../model/lunar_event.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const Color _primary = Color(0xFF1A3A4A);
  static const Color _lunar = Color(0xFF7F77DD); // tím
  static const Color _solar = Color(0xFF2D6A7F); // xanh than

  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);
    final now = DateTime.now();

    // Thống kê tháng này
    final thisMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final thisMonth = provider.events
        .where((e) => e.date.startsWith(thisMonthStr))
        .toList();
    final lunarCount = thisMonth.where((e) => e.isLunar == 1).length;
    final solarCount = thisMonth.where((e) => e.isLunar == 0).length;
    final totalMonth = thisMonth.length;

    // Thống kê tổng
    final totalAll = provider.events.length;
    final totalLunar = provider.events.where((e) => e.isLunar == 1).length;
    final totalSolar = provider.events.where((e) => e.isLunar == 0).length;
    final totalYearly = provider.events.where((e) => e.isYearly == 1).length;

    // Thống kê 6 tháng gần đây (bar chart data)
    final monthlyData = _buildMonthlyData(provider.events, now);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thống kê',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.events.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Header tháng ──
                _buildMonthHeader(now),
                const SizedBox(height: 16),

                // ── Metric cards ──
                Row(
                  children: [
                    _buildMetricCard(
                      'Tổng tháng này',
                      '$totalMonth',
                      Icons.calendar_month,
                      _primary,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      'Âm lịch',
                      '$lunarCount',
                      Icons.brightness_2,
                      _lunar,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      'Dương lịch',
                      '$solarCount',
                      Icons.wb_sunny_outlined,
                      _solar,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Pie chart ──
                if (totalMonth > 0) ...[
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardTitle(
                          'Phân loại sự kiện tháng này',
                          Icons.pie_chart_outline,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (event, response) {
                                        setState(() {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              response == null ||
                                              response.touchedSection == null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex = response
                                              .touchedSection!
                                              .touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    sections: [
                                      PieChartSectionData(
                                        value: lunarCount.toDouble(),
                                        color: _lunar,
                                        title: lunarCount > 0
                                            ? '${((lunarCount / totalMonth) * 100).round()}%'
                                            : '',
                                        radius: _touchedIndex == 0 ? 80 : 70,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: solarCount.toDouble(),
                                        color: _solar,
                                        title: solarCount > 0
                                            ? '${((solarCount / totalMonth) * 100).round()}%'
                                            : '',
                                        radius: _touchedIndex == 1 ? 80 : 70,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegend(
                                    'Âm lịch',
                                    '$lunarCount sự kiện',
                                    _lunar,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLegend(
                                    'Dương lịch',
                                    '$solarCount sự kiện',
                                    _solar,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Bar chart 6 tháng ──
                if (totalAll > 0) ...[
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardTitle(
                          'Sự kiện 6 tháng gần đây',
                          Icons.bar_chart,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY:
                                  (monthlyData
                                              .map((d) => d['total'] as int)
                                              .reduce((a, b) => a > b ? a : b) +
                                          2)
                                      .toDouble(),
                              barGroups: List.generate(
                                monthlyData.length,
                                (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (monthlyData[i]['total'] as int)
                                          .toDouble(),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2D6A7F),
                                          Color(0xFF1A3A4A),
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                      width: 22,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (v, _) => Text(
                                      v.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final idx = v.toInt();
                                      if (idx < 0 ||
                                          idx >= monthlyData.length) {
                                        return const SizedBox();
                                      }
                                      return Text(
                                        'T${monthlyData[idx]['month']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.grey.withOpacity(0.15),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Tổng quan ──
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardTitle(
                        'Tổng quan tất cả sự kiện',
                        Icons.summarize_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        'Tổng số sự kiện',
                        '$totalAll',
                        Icons.event_note,
                        _primary,
                      ),
                      _buildDivider(),
                      _buildStatRow(
                        'Sự kiện âm lịch',
                        '$totalLunar',
                        Icons.brightness_2,
                        _lunar,
                      ),
                      _buildDivider(),
                      _buildStatRow(
                        'Sự kiện dương lịch',
                        '$totalSolar',
                        Icons.wb_sunny_outlined,
                        _solar,
                      ),
                      _buildDivider(),
                      _buildStatRow(
                        'Lặp lại hàng năm',
                        '$totalYearly',
                        Icons.repeat,
                        Colors.teal,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }

  List<Map<String, int>> _buildMonthlyData(
    List<LunarEvent> events,
    DateTime now,
  ) {
    final result = <Map<String, int>>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final monthStr = "${d.year}-${d.month.toString().padLeft(2, '0')}";
      final count = events.where((e) => e.date.startsWith(monthStr)).length;
      result.add({'month': d.month, 'total': count});
    }
    return result;
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu để thống kê',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm sự kiện để xem biểu đồ',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(DateTime now) {
    final months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_view_month, color: _primary, size: 20),
          const SizedBox(width: 10),
          Text(
            '${months[now.month]} ${now.year}',
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildCardTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, String sub, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100);
  }
}
