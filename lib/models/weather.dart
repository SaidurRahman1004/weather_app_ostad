class WeatherResponse {
  final String locationName;
  final CurrentWeather? current;
  final HourlyWeather hourly;
  final DailyWeather daily;

  WeatherResponse({
    required this.locationName,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json, double lat, double lon) {
    final currentJson = json['current_weather'] as Map<String, dynamic>?;
    final hourlyJson = json['hourly'] as Map<String, dynamic>? ?? {};
    final dailyJson = json['daily'] as Map<String, dynamic>? ?? {};
    final locationName = "$lat, $lon";
    return WeatherResponse(
      locationName: locationName,
      current: currentJson != null ? CurrentWeather.fromJson(currentJson) : null,
      hourly: HourlyWeather.fromJson(hourlyJson),
      daily: DailyWeather.fromJson(dailyJson),
    );
  }
}

class CurrentWeather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  CurrentWeather({required this.temperature, required this.weatherCode, required this.windSpeed});
  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature'] as num).toDouble(),
      weatherCode: (json['weathercode'] as num).toInt(),
      windSpeed: (json['windspeed'] as num).toDouble(),
    );
  }
}

class HourlyWeather {
  final List<String> time;
  final List<double> temperature;
  final List<int> weatherCode;
  final List<double> windSpeed;
  HourlyWeather({required this.time, required this.temperature, required this.weatherCode, required this.windSpeed});
  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final t = (json['time'] as List?)?.map((e) => e as String).toList() ?? [];
    final temp = (json['temperature_2m'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final wc = (json['weathercode'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];
    final ws = (json['wind_speed_10m'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    return HourlyWeather(time: t, temperature: temp, weatherCode: wc, windSpeed: ws);
  }
}

class DailyWeather {
  final List<String> time;
  final List<double> temperatureMax;
  final List<double> temperatureMin;
  final List<String> sunrise;
  final List<String> sunset;
  DailyWeather({required this.time, required this.temperatureMax, required this.temperatureMin, required this.sunrise, required this.sunset});
  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    final t = (json['time'] as List?)?.map((e) => e as String).toList() ?? [];
    final tmax = (json['temperature_2m_max'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final tmin = (json['temperature_2m_min'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final sunrise = (json['sunrise'] as List?)?.map((e) => e as String).toList() ?? [];
    final sunset = (json['sunset'] as List?)?.map((e) => e as String).toList() ?? [];
    return DailyWeather(time: t, temperatureMax: tmax, temperatureMin: tmin, sunrise: sunrise, sunset: sunset);
  }
}