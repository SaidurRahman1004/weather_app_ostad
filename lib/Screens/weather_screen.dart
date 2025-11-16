import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _searchController = TextEditingController();
  bool _isloading = false;
  String? _error;
  String? _resolvecity = "";

  //current
  double? _tempC;
  double? _windKph;
  double? _wCode;
  String? _wText;
  double? _hi, _lo;

  List<_Hourly> _hourly = [];
  List<_Daily> _daily = [];

  Future<({String? city, double? lat, double? lon})> geolocation(
    String city,
  ) async {
    try {
      final url = Uri.parse(
        "https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&format=json",
      );
      final response = await http.get(url);
      print(response.body);
      if (response.statusCode != 200)
        throw Exception("Geocoding failed ${response.statusCode}");
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data["results"] as List?) ?? [];
      if (results.isEmpty) throw Exception("No City found");

      final m = results.first as Map<String, dynamic>;
      final lat = (m["latitude"] as num).toDouble();
      final lon = (m["longitude"] as num).toDouble();
      final name = "${m["name"]}, ${m["country"]}";

      print("Lat: $lat, Lon: $lon, Name: $name");
      return (city: name, lat: lat, lon: lon);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _fetchData(String city) async {
    setState(() {
      _isloading = true;
      _error = null;
    });
    try {
      final getGeoData = await geolocation(city);
      final url = Uri.parse(
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=${getGeoData.lat}"
        "&longitude=${getGeoData.lon}"
        "&daily=temperature_2m_max,temperature_2m_min,sunset,sunrise"
        "&hourly=temperature_2m,weather_code,wind_speed_10m"
        "&current_weather=true"
        "&timezone=auto",
      );
      final response = await http.get(url);
      print(response.body);
      if (response.statusCode != 200)
        throw Exception("Weather forecast failed ${response.statusCode}");
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data["current"] as Map<String, dynamic>;
      //curent
      final tempC = (current["temperature_2m"] as num).toDouble();
      final windKph = (current["wind_speed_10m"] as num).toDouble();
      final wCode = (current["weather_code"] as num).toInt();
      final wText = current["weather_code"].toString();

      //hourly
      final hourly = data["hourly"] as Map<String, dynamic>;
      final hTimes = List<String>.from(hourly["time"] as List);
      final hTemps = List<num>.from(hourly["temperature_2m"] as List);
      final hCodes = List<num>.from(hourly["weather_code"] as List);

      final outHourly = <_Hourly>[];
      for (var i = 0; i < hTimes.length; i++) {
        outHourly.add(
          _Hourly(
            DateTime.parse(hTimes[i]),
            (hTemps[i]).toDouble(),
            (hCodes[i]).toInt(),
          ),
        );
      }

      setState(() {
        _resolvecity = getGeoData.city;
        _tempC = tempC;
        _windKph = windKph;
        _wCode = wCode as double?;
        _wText = _codeToText(wCode);
        _hourly = outHourly;
      });
    } catch (e) {
    } finally {
      setState(() {
        _isloading = false;
      });
    }
  }

  String _codeToText(int? c) {
    if (c == null) return "--";

    if (c == 0) return "Clear Sky";

    if ([1, 2, 3].contains(c)) return "Mainly Clear";

    if ([45, 48].contains(c)) return "Fag";

    if ([51, 53, 55, 56, 57].contains(c)) return "Orizzle";

    if ([61, 63, 65, 66, 67].contains(c)) return "Rain";

    if ([71, 73, 75, 77].contains(c)) return "Snow";

    if ([80, 81, 82].contains(c)) return "Rain Showers";

    if ([85, 86].contains(c)) return "Snow Showers";

    if (c == 95) return "Thunderstorm";

    if (c == 96) return "Hail";

    return "Cloudy";
  }

  IconData_codeToIcon(int? c) {
    if (c == 0) return Icons.sunny;

    if ([1, 2, 3].contains(c)) return Icons.cloud_outlined;

    if ([45, 48].contains(c)) return Icons.foggy;

    if ([51, 53, 55, 56, 57].contains(c)) return Icons.grain_sharp;

    if ([61, 63, 65, 66, 67].contains(c)) return Icons.water_drop;

    if ([71, 73, 75, 77].contains(c)) return Icons.ac_unit;

    if ([80, 81, 82].contains(c)) return Icons.deblur_rounded;

    if ([85, 86].contains(c)) return Icons.snowing;

    if (c == 95) return Icons.thunderstorm;

    if (c == 96) return Icons.thunderstorm;

    return Icons.cloud;
  }

  void initState() {
    geolocation("Dhaka");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(_searchController.text),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,

                colors: [Colors.blue.shade900, Colors.blueAccent, Colors.white70],
              ),
            ),
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        controller: _searchController,
                        onSubmitted: (value) => _fetchData(value),
                        decoration: InputDecoration(
                          hintText: "Search City",
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isloading
                          ? null
                          : () => _fetchData(_searchController.text),
                      child: Text("Go"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isloading) const Center(child: CircularProgressIndicator()),
                if (_error != null)
                  Center(
                    child: Text(_error!, style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Text(
                      "MY Location",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _resolvecity ?? "Dhaka,Bangladesh",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_tempC != null) ...[
                      Center(
                        child: Text(
                          "${_tempC!.toStringAsFixed(1)}°C",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (_windKph != null) ...[
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            " Sunny Condition Likely trough today. wind up tp ${_windKph} km/h",
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (_hourly.isNotEmpty) ...[
                      Card(
                        color: Colors.white,
                        child: SizedBox(
                          height: 112,
                          child: ListView.separated(
                            itemBuilder: (_, __) => const SizedBox(width: 12),
                            separatorBuilder: (_,i) {
                              final _h = _hourly[i];
                              final label = i == 0 ? "Now" : _h.t.hour.toString();
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(label),
                                  Icon(IconData_codeToIcon(_h.code)),
                                  Text("${_h.temp.toStringAsFixed(0)} C"),
                                ],
                              );

                            },
                            itemCount: _hourly.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
  final double tMain, tMax;

  _Daily(this.date, this.tMain, this.tMax);
}
