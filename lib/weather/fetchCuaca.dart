import 'dart:convert';
import 'package:http/http.dart' as http;

class CuacaService {
  static const String apiKey = '8594ce6a201450a42a8f6ac8da65435a';

  // Ambil data cuaca saat ini
  static Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );
    final response = await http.get(url);
    return json.decode(response.body);
  }

  // Ambil prakiraan cuaca (5 hari, interval 3 jam)
  static Future<List<dynamic>> getForecast(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    return data['list'];
  }

  // Ambil nama kota berdasarkan koordinat
  static Future<String> getCityName(double lat, double lon) async {
    final url = Uri.parse(
      'http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    return data[0]['name'];
  }

  // Ambil koordinat dari nama kota
  static Future<Map<String, double>> getLatLonFromCity(String cityName) async {
    final url = Uri.parse(
      'http://api.openweathermap.org/geo/1.0/direct?q=$cityName&limit=1&appid=$apiKey',
    );
    final response = await http.get(url);
    final data = json.decode(response.body);
    return {
      'lat': data[0]['lat'],
      'lon': data[0]['lon'],
    };
  }
}




