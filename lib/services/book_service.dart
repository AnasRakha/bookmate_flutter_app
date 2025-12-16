import 'dart:convert';
import 'package:http/http.dart' as http;

class BookService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // ---------------------------
  // Search books by query
  // ---------------------------
  static Future<List<dynamic>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl?q=${Uri.encodeQueryComponent(query)}&maxResults=20',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] != null ? List.from(data['items']) : [];
      } else {
        print('Request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error occurred: $e');
      return [];
    }
  }

  // ---------------------------
  // Get books by category
  // ---------------------------
  static Future<List<dynamic>> getBooksByCategory(String category) async {
    final url = Uri.parse(
      '$_baseUrl?q=subject:${Uri.encodeQueryComponent(category)}&maxResults=20',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['items'] != null ? List.from(data['items']) : [];
      } else {
        print('Request failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching category books: $e');
      return [];
    }
  }
}
