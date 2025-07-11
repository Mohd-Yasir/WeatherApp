import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../model/weather_model.dart';

class ApiService {
  static const _apiKey = 'API_KEY_HERE';
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> fetchWeather(String city) async {
    final url = '$_baseUrl?q=$city&appid=$_apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        return Weather.fromJson(jsonBody);
      } else if (response.statusCode == 404) {
        throw Exception('City not found');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Error: ${errorBody['message']}');
      }
    } on SocketException {
      throw Exception('Failed to connect to the weather service. Please check your connection.');
    } catch (e) {
      rethrow;
    }
  }
}
