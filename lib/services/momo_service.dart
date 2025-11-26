import 'dart:convert';
import 'package:http/http.dart' as http;

class MomoService {
  static const String _endpoint = "http://localhost:3000/momo/create";

  Future<Map<String, dynamic>?> createPayment({
    required String orderId,
    required double amount,
    required String orderInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount.toInt(),
          // Sending other fields just in case the backend evolves, 
          // but user only strictly asked for amount. 
          // However, to be safe and strictly follow "Flutter Web gửi request tới server mình... body: jsonEncode({"amount": 10000})"
          // I will stick to EXACTLY what the user asked for to avoid issues if the backend is strict.
        }),
      );

      print("MoMo RES [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("MoMo Server Error: ${response.statusCode}");
        return {
          "resultCode": -1,
          "message": "Server error: ${response.statusCode}",
          "details": response.body
        };
      }
    } catch (e) {
      print("MoMo ERROR: $e");
      return {
        "resultCode": -1,
        "message": "Connection error: $e"
      };
    }
  }
}
