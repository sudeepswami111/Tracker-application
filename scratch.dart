import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  double lat = 22.3072;
  double lon = 73.1812;

  // 2. AQI
  final aqiUrl = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon'
      '&current=pm10,pm2_5'
  );
  final res2 = await http.get(aqiUrl);
  print('AQI code: ${res2.statusCode}');
  print('AQI body: ${res2.body}');
}
