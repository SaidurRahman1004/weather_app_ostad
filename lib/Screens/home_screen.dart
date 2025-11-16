import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/open_meteo_service.dart';
import '../widgets/daily_list.dart';
import '../widgets/hourly_list.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _latController = TextEditingController(text: "23.8103");
  final TextEditingController _lonController = TextEditingController(text: "90.4125");
  WeatherResponse? _weather;
  bool _loading = false;
  String? _error;

  Future<void> _fetch() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat == null || lon == null) {
      setState(() => _error = "Invalid latitude or longitude");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _weather = null;
    });
    try {
      final resp = await OpenMeteoService.fetchWeather(lat, lon);
      setState(() {
        _weather = resp;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatTemp(double? t) {
    if (t == null) return "--";
    return "${t.toStringAsFixed(0)}°";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                      decoration: const InputDecoration(labelText: "Latitude"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lonController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                      decoration: const InputDecoration(labelText: "Longitude"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _fetch,
                    child: const Text("Go"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading) const CircularProgressIndicator(),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 12),
                  color: Colors.red.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!)),
                    ],
                  ),
                ),
              if (_weather != null) Expanded(child: _buildSuccess(context)),
              if (!_loading && _weather == null && _error == null)
                Expanded(
                  child: Center(
                    child: Text(
                      "Enter latitude and longitude and press Go",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final current = _weather!.current;
    final daily = _weather!.daily;
    final hourly = _weather!.hourly;
    final high = daily.temperatureMax.isNotEmpty ? daily.temperatureMax.reduce((a, b) => a > b ? a : b) : null;
    final low = daily.temperatureMin.isNotEmpty ? daily.temperatureMin.reduce((a, b) => a < b ? a : b) : null;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            "${_weather!.locationName}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTemp(current?.temperature),
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200),
          ),
          const SizedBox(height: 4),
          Text(
            OpenMeteoService.weatherCodeToString(current?.weatherCode),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (high != null && low != null)
            Text("H:${high.toStringAsFixed(0)}° L:${low.toStringAsFixed(0)}°"),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Now · Hourly", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                HourlyList(hourly: hourly),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("10-Day Forecast", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DailyList(daily: daily),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}