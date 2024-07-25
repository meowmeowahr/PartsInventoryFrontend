import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'dart:convert';

Future<List<dynamic>> fetchAllParts(String apiBaseAddress) async {
  final url = Uri.parse(p.join(apiBaseAddress, 'parts/'));
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception('Failed to load part information');
  }
}

Future<Map> fetchBackendInfo(String apiBaseAddress,
    {bool fetchGithub = true}) async {
  final url = Uri.parse(
      p.join(apiBaseAddress, 'info/?fetch_github=${fetchGithub.toString()}'));
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception('Failed to load version information');
  }
}
