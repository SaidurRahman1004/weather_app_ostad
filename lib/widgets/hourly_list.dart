import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/open_meteo_service.dart';
import 'package:intl/intl.dart';



class HourlyList extends StatelessWidget {
  final HourlyWeather hourly;
  const HourlyList({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    final count = hourly.time.length;
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        itemBuilder: (context, index) {
          final time = DateTime.parse(hourly.time[index]);
          final hourLabel = DateFormat.j().format(time);
          final temp = hourly.temperature[index];
          final code = hourly.weatherCode[index];
          return Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(hourLabel, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Icon(_iconForCode(code), size: 20),
                const SizedBox(height: 6),
                Text("${temp.toStringAsFixed(0)}°", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForCode(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2) return Icons.wb_cloudy;
    if (code == 3) return Icons.cloud;
    if (code >= 61 && code <= 65) return Icons.grain;
    if (code >= 71 && code <= 75) return Icons.ac_unit;
    if (code >= 95) return Icons.flash_on;
    return Icons.wb_sunny;
  }
}