import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/weather.dart';


class OpenMeteoService {
  static const String _base = "https://api.open-meteo.com/v1/forecast";
  static Future<WeatherResponse> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse("$_base?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,weathercode,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset&forecast_days=10&timezone=Asia%2FDhaka");
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception("Failed to load weather: ${res.statusCode}");
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return WeatherResponse.fromJson(json, lat, lon);
  }

  static String weatherCodeToString(int? code) {
    if (code == null) return "";
    const map = {
      0: "Clear sky",
      1: "Mainly clear",
      2: "Partly cloudy",
      3: "Overcast",
      45: "Fog",
      48: "Depositing rime fog",
      51: "Light drizzle",
      53: "Moderate drizzle",
      55: "Dense drizzle",
      61: "Slight rain",
      63: "Moderate rain",
      65: "Heavy rain",
      71: "Slight snow",
      73: "Moderate snow",
      75: "Heavy snow",
      80: "Rain showers",
      81: "Heavy rain showers",
      95: "Thunderstorm",
    };
    return map[code] ?? "Weather";
  }
}