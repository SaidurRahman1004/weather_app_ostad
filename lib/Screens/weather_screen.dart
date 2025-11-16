import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _searchController = TextEditingController(text: "Dhaka");
  bool _isLoading = true;
  String? _error;
  String? _resolvedCity;

  // Current
  double? _tempC;
  double? _windKph;
  int? _wCode;
  String? _wText;
  double? _hi, _lo;

  List<_Hourly> _hourly = [];
  List<_Daily> _daily = [];

  // Geocoding API কল করে শহর থেকে lat/lon বের করা
  Future<({String? city, double? lat, double? lon})> geolocation(
    String city,
  ) async {
    try {
      final url = Uri.parse(
        "https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&format=json",
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("Geocoding failed ${response.statusCode}");
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data["results"] as List?) ?? [];
      if (results.isEmpty) throw Exception("No City found for '$city'");

      final m = results.first as Map<String, dynamic>;
      final lat = (m["latitude"] as num).toDouble();
      final lon = (m["longitude"] as num).toDouble();
      final name = "${m["name"]}, ${m["country"]}";

      return (city: name, lat: lat, lon: lon);
    } catch (e) {
      if (e.toString().contains("No City found")) {
        throw Exception("City '$city' not found. Please try again.");
      }
      throw Exception("Failed to get location. Check connection.");
    }
  }

  Future<void> _fetchData(String city) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: Get Lat/Lon from city name
      final getGeoData = await geolocation(city);
      if (getGeoData.lat == null || getGeoData.lon == null) {
        throw Exception("Could not resolve location.");
      }
      final url = Uri.parse(
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=${getGeoData.lat}&longitude=${getGeoData.lon}"
        "&current=temperature_2m,weather_code,wind_speed_10m"
        "&hourly=temperature_2m,weather_code"
        "&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset"
        "&forecast_days=10"
        "&timezone=Asia%2FDhaka",
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception("Weather forecast failed ${response.statusCode}");
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Current weather parsing
      final current = data["current"] as Map<String, dynamic>;
      final tempC = (current["temperature_2m"] as num).toDouble();
      final windKph = (current["wind_speed_10m"] as num).toDouble();
      final wCode = (current["weather_code"] as num).toInt();
      final wText = _codeToText(wCode);

      final hourly = data["hourly"] as Map<String, dynamic>;
      final hTimes = List<String>.from(hourly["time"] as List);
      final hTemps = List<num>.from(hourly["temperature_2m"] as List);
      final hCodes = List<num>.from(hourly["weather_code"] as List);

      final outHourly = <_Hourly>[];

      for (var i = 0; i < 24; i++) {
        outHourly.add(
          _Hourly(
            DateTime.parse(hTimes[i]),
            (hTemps[i]).toDouble(),
            (hCodes[i]).toInt(),
          ),
        );
      }

      // Daily weather parsing
      final daily = data["daily"] as Map<String, dynamic>;
      final dTimes = List<String>.from(daily["time"] as List);
      final dMaxTemps = List<num>.from(daily["temperature_2m_max"] as List);
      final dMinTemps = List<num>.from(daily["temperature_2m_min"] as List);
      final dCodes = List<num>.from(daily["weather_code"] as List);

      final outDaily = <_Daily>[];
      for (var i = 0; i < dTimes.length; i++) {
        outDaily.add(
          _Daily(
            DateTime.parse(dTimes[i]),
            (dMinTemps[i]).toDouble(),
            (dMaxTemps[i]).toDouble(),
            (dCodes[i]).toInt(),
          ),
        );
      }

      final todayHi = outDaily.isNotEmpty ? outDaily.first.tMax : null;
      final todayLo = outDaily.isNotEmpty ? outDaily.first.tMin : null;

      setState(() {
        _resolvedCity = getGeoData.city;
        _tempC = tempC;
        _windKph = windKph;
        _wCode = wCode;
        _wText = wText;
        _hi = todayHi;
        _lo = todayLo;
        _hourly = outHourly;
        _daily = outDaily;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _codeToText(int? c) {
    if (c == null) return "--";
    if (c == 0) return "Clear Sky";
    if ([1, 2, 3].contains(c)) return "Mostly Sunny";
    if ([45, 48].contains(c)) return "Fog";
    if ([51, 53, 55, 56, 57].contains(c)) return "Drizzle";
    if ([61, 63, 65, 66, 67].contains(c)) return "Rain";
    if ([71, 73, 75, 77].contains(c)) return "Snow";
    if ([80, 81, 82].contains(c)) return "Rain Showers";
    if ([85, 86].contains(c)) return "Snow Showers";
    if (c == 95) return "Thunderstorm";
    if (c == 96) return "Hail";
    return "Cloudy";
  }

  IconData _codeToIcon(int? c) {
    if (c == null) return Icons.device_unknown;
    if (c == 0) return Icons.wb_sunny;
    if ([1, 2, 3].contains(c)) return Icons.wb_cloudy;
    if ([45, 48].contains(c)) return Icons.foggy;
    if ([51, 53, 55, 56, 57].contains(c)) return Icons.grain;
    if ([61, 63, 65, 66, 67].contains(c)) return Icons.water_drop;
    if ([71, 73, 75, 77].contains(c)) return Icons.ac_unit;
    if ([80, 81, 82].contains(c)) return Icons.shower;
    if ([85, 86].contains(c)) return Icons.snowing;
    if (c == 95) return Icons.thunderstorm;
    if (c == 96) return Icons.thunderstorm;
    return Icons.cloud;
  }

  String _formatTime(DateTime dt) {
    return DateFormat('j').format(dt);
  }

  String _formatDay(DateTime dt, {bool isFirst = false}) {
    if (isFirst) return "Today";

    return DateFormat('E').format(dt);
  }

  @override
  void initState() {
    super.initState();

    _fetchData("Dhaka");
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(
      context,
    ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3C79E6), Color(0xFF639FF2)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _fetchData(_searchController.text),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // -- Search Bar --
                _buildSearchRow(),

                const SizedBox(height: 20),

                _buildWeatherBody(textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search City",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) _fetchData(value);
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: Icon(Icons.send, color: Colors.white),
          onPressed: _isLoading
              ? null
              : () {
                  if (_searchController.text.isNotEmpty) {
                    _fetchData(_searchController.text);
                  }
                },
        ),
      ],
    );
  }

  Widget _buildWeatherBody(TextTheme textTheme) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 50),
              const SizedBox(height: 10),
              Text(
                _error!,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _fetchData(_searchController.text),
                child: Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        //Current Weather
        _buildCurrentWeather(textTheme),

        const SizedBox(height: 20),
        _buildInfoCard(
          "Sunny conditions likely through today. Wind up to ${_windKph} km/h.",
        ),

        const SizedBox(height: 20),

        //Hourly Forecast
        _buildHourlyForecast(textTheme),

        const SizedBox(height: 20),

        //10-Day Forecast
        _buildDailyForecast(textTheme),
      ],
    );
  }

  // Current Weather UI
  Widget _buildCurrentWeather(TextTheme textTheme) {
    return Column(
      children: [
        Text(
          "MY LOCATION",
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(_resolvedCity ?? "Loading...", style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          "${_tempC?.toStringAsFixed(0) ?? '--'}°",
          style: textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w200,
            fontSize: 96,
          ),
        ),
        Text(_wText ?? "--", style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (_hi != null && _lo != null)
          Text(
            "H:${_hi?.toStringAsFixed(0)}°  L:${_lo?.toStringAsFixed(0)}°",
            style: textTheme.titleMedium,
          ),
      ],
    );
  }

  // Info Card UI
  Widget _buildInfoCard(String text) {
    return Card(
      color: Colors.white.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Hourly Forecast UI
  Widget _buildHourlyForecast(TextTheme textTheme) {
    return Card(
      color: Colors.white.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Now • Hourly",
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const Divider(color: Colors.white30),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _hourly.length,
                itemBuilder: (context, i) {
                  final item = _hourly[i];

                  final label = i == 0 ? "Now" : _formatTime(item.t);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Icon(_codeToIcon(item.code), color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          "${item.temp.toStringAsFixed(0)}°",
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, i) => const SizedBox(width: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 10-Day Forecast UI
  Widget _buildDailyForecast(TextTheme textTheme) {
    return Card(
      color: Colors.white.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "10-Day Forecast",
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const Divider(color: Colors.white30),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _daily.length,
              itemBuilder: (context, i) {
                final item = _daily[i];
                final dayLabel = _formatDay(item.date, isFirst: i == 0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Day
                      Expanded(
                        flex: 2,
                        child: Text(dayLabel, style: textTheme.titleMedium),
                      ),
                      // Icon
                      Expanded(
                        flex: 1,
                        child: Icon(
                          _codeToIcon(item.code),
                          color: Colors.white,
                        ),
                      ),
                      // Min Temp
                      Expanded(
                        flex: 1,
                        child: Text(
                          "${item.tMin.toStringAsFixed(0)}°",
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      // Range Bar (Simple Placeholder)
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.yellow],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Max Temp
                      Expanded(
                        flex: 1,
                        child: Text(
                          "${item.tMax.toStringAsFixed(0)}°",
                          style: textTheme.titleMedium,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Hourly {
  final DateTime t;
  final double temp;
  final int code;

  _Hourly(this.t, this.temp, this.code);
}

class _Daily {
  final DateTime date;
  final double tMin, tMax;
  final int code;

  _Daily(this.date, this.tMin, this.tMax, this.code);
}
