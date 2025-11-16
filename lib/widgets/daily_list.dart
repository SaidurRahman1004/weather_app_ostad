import 'package:flutter/material.dart';
import '../models/weather.dart';
import 'package:intl/intl.dart';


class DailyList extends StatelessWidget {
  final DailyWeather daily;
  const DailyList({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    final n = daily.time.length;
    final allMax = daily.temperatureMax;
    final globalMax = allMax.isNotEmpty ? allMax.reduce((a, b) => a > b ? a : b) : 30.0;
    final globalMin = daily.temperatureMin.isNotEmpty ? daily.temperatureMin.reduce((a, b) => a < b ? a : b) : 10.0;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: n,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final date = DateTime.parse(daily.time[index]);
        final day = DateFormat.E().format(date);
        final min = daily.temperatureMin[index];
        final max = daily.temperatureMax[index];
        final range = (max - min).abs();
        final progress = (max - globalMin) / ((globalMax - globalMin).abs() + 0.0001);
        return Row(
          children: [
            SizedBox(width: 64, child: Text(day)),
            const SizedBox(width: 8),
            const Icon(Icons.wb_sunny, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                color: Colors.orange,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 48, child: Text("${min.toStringAsFixed(0)}°")),
            const SizedBox(width: 8),
            SizedBox(width: 48, child: Text("${max.toStringAsFixed(0)}°")),
          ],
        );
      },
    );
  }
}