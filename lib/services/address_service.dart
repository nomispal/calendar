import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressService {
  final String _baseUrl = "https://nominatim.openstreetmap.org/search";

  Future<List<String>> getAddressSuggestions(String query) async {
    final response = await http.get(
      Uri.parse("$_baseUrl?q=$query&format=json&addressdetails=1&limit=5"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<String> suggestions = [];
      for (var item in data) {
        suggestions.add(item['display_name']);
      }
      return suggestions;
    } else {
      throw Exception('Failed to load address suggestions');
    }
  }
}
