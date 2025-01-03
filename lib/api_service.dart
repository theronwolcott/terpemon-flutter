import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_state.dart';

class ApiService {
  // Fetch a list of objects from the API
  Future<List<T>> fetchList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse("${dotenv.env['API_ROOT']!}$endpoint");
    String userId = UserState().id;
    try {
      Map<String, dynamic> finalBody = body != null
          ? {
              ...body,
              'userId': userId
            } // Merge userId with the body if it's provided
          : {'userId': userId}; // Use the default myMap if body is null
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(finalBody),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response body as JSON
        List<dynamic> responseData = jsonDecode(response.body);

        // Map each JSON object to a list of objects (T)
        return responseData.map((data) => fromJson(data)).toList();
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow; // Re-throw the exception to handle it upstream
    }
  }

  // Fetch a single object from the API
  Future<T> fetchSingle<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse("${dotenv.env['API_ROOT']!}$endpoint");
    String userId = UserState().id;

    try {
      Map<String, dynamic> finalBody = body != null
          ? {
              ...body,
              'userId': userId
            } // Merge userId with the body if it's provided
          : {'userId': userId}; // Use the default myMap if body is null
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(finalBody),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response body as JSON
        Map<String, dynamic> responseData = jsonDecode(response.body);

        // Deserialize the response into a single object (T)
        return fromJson(responseData);
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow; // Re-throw the exception to handle it upstream
    }
  }

  // Simple method for APIs that don't return data to parse
  Future<bool> postRequest(
    String endpoint, {
    Map<String, dynamic>? body, // body is a named parameter
  }) async {
    final url = Uri.parse("${dotenv.env['API_ROOT']!}$endpoint");
    String userId = UserState().id;

    try {
      Map<String, dynamic> finalBody =
          body != null ? {...body, 'userId': userId} : {'userId': userId};
      // Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(finalBody),
      );

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Failed to post data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      return false; // Return false in case of an error
    }
  }
}
