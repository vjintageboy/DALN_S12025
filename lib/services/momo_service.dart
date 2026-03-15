import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MomoService {
  String get _baseUrl {
    if (kIsWeb) return "http://localhost:3000";
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:3000";
    }
    return "http://localhost:3000";
  }

  Future<Map<String, dynamic>?> createPayment({
    required String orderId,
    required double amount,
    required String orderInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/momo/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount.toInt(),
          // Sending other fields just in case the backend evolves,
          // but user only strictly asked for amount.
          // However, to be safe and strictly follow "Flutter Web gửi request tới server mình... body: jsonEncode({"amount": 10000})"
          // I will stick to EXACTLY what the user asked for to avoid issues if the backend is strict.
        }),
      );

      debugPrint("MoMo RES [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("MoMo Server Error: ${response.statusCode}");
        return {
          "resultCode": -1,
          "message": "Server error: ${response.statusCode}",
          "details": response.body,
        };
      }
    } catch (e) {
      debugPrint("MoMo ERROR: $e");
      return {"resultCode": -1, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>?> checkStatus(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/momo/query"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"orderId": orderId}),
      );

      debugPrint("MoMo Query RES: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("MoMo Query ERROR: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> refundPayment({
    required String orderId,
    required double amount,
    required String transId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/momo/refund"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "orderId": orderId,
          "amount": amount.toInt(),
          "transId": transId,
        }),
      );

      debugPrint("MoMo Refund RES: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("MoMo Refund Server Error: ${response.statusCode}");
        return {
          "resultCode": -1,
          "message": "Server error: ${response.statusCode}",
          "details": response.body,
        };
      }
    } catch (e) {
      debugPrint("MoMo Refund ERROR: $e");
      return {"resultCode": -1, "message": "Connection error: $e"};
    }
  }
}
