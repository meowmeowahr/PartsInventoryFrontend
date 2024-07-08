import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> fetchAllParts() async {
  final url = Uri.parse('http://localhost:8000/parts/');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception('Failed to load part information');
  }
}
