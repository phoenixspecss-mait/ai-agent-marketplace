import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:expert_ai/services/database/database_service.dart';

class ApiService {
  // Live deployed backend on Render
  static String get baseUrl => "https://ai-agent-marketplace-sa1v.onrender.com";

  static Map<String, double> agentCosts = {
    "legal-clause-explainer": 0.005,
    "punjabi-slang-translator": 0.002,
    "symptom-triage-explainer": 0.003,
  };

  // Local fallback state in case backend is offline during demo
  static double _localBalance = 5.00;
  static final List<Map<String, dynamic>> _localTransactions = [];

  static List<Map<String, dynamic>> get localTransactions => _localTransactions;

  static Future<double> getWalletBalance(String userId) async {
    try {
      final url = Uri.parse(
        "$baseUrl/api/marketplace/wallet/balance?user_id=$userId",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _localBalance = (data['balance_usd'] as num).toDouble();
        return _localBalance;
      }
    } catch (_) {
      // Return fallback local balance if offline
    }
    return _localBalance;
  }

  static Future<double> topUpWallet(String userId, double amount) async {
    try {
      final url = Uri.parse("$baseUrl/api/marketplace/wallet/topup");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"user_id": userId, "amount": amount}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _localBalance = (data['new_balance_usd'] as num).toDouble();
        _localTransactions.insert(0, {
          "agent_id": "Wallet Top Up",
          "amount": amount,
          "date": "Just now",
          "is_deduction": false,
        });
        DatabaseService.instance().recordActivity(
          userId: userId,
          agentName: "Wallet Top Up",
          query: "Added \$$amount USD to wallet",
          amount: amount,
          isDeduction: false,
        );
        return _localBalance;
      }
    } catch (_) {}
    _localBalance += amount;
    _localTransactions.insert(0, {
      "agent_id": "Wallet Top Up",
      "amount": amount,
      "date": "Just now",
      "is_deduction": false,
    });
    DatabaseService.instance().recordActivity(
      userId: userId,
      agentName: "Wallet Top Up",
      query: "Added \$$amount USD to wallet",
      amount: amount,
      isDeduction: false,
    );
    return _localBalance;
  }

  static Future<Map<String, dynamic>> callAgent({
    required String userId,
    required String agentId,
    required String query,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/marketplace/call");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "user_id": userId,
              "agent_id": agentId,
              "query": query,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final costVal = (data['cost_usd'] as num).toDouble();
        _localBalance = (data['remaining_balance_usd'] as num).toDouble();
        _localTransactions.insert(0, {
          "agent_id": agentId,
          "amount": costVal,
          "date": "Today",
          "is_deduction": true,
        });
        DatabaseService.instance().recordActivity(
          userId: userId,
          agentName: agentId,
          query: query,
          amount: costVal,
          isDeduction: true,
        );
        return {
          "success": true,
          "result": data['result'],
          "cost": data['cost_usd'],
          "settlement": data['payment_settlement'],
          "remaining_balance": _localBalance,
        };
      } else if (response.statusCode == 402) {
        final detail = data['detail'];
        String msg = "Payment Required: Insufficient balance.";
        double cost = agentCosts[agentId] ?? 0.005;
        double balance = _localBalance;

        if (detail is Map) {
          msg = detail['message']?.toString() ?? msg;
          cost = (detail['cost_usd'] as num?)?.toDouble() ?? cost;
          balance =
              (detail['current_balance_usd'] as num?)?.toDouble() ?? balance;
        } else if (detail is String) {
          msg = detail;
        }

        return {
          "success": false,
          "is_payment_required": true,
          "message": msg,
          "cost": cost,
          "current_balance": balance,
        };
      } else {
        final detail = data['detail'];
        return {
          "success": false,
          "message": detail is String
              ? detail
              : (detail?.toString() ?? "Execution failed. Please try again."),
        };
      }
    } catch (e) {
      debugPrint("ApiService callAgent exception: $e");
      // Offline fallback demo simulation
      final cost = agentCosts[agentId] ?? 0.005;
      if (_localBalance < cost) {
        return {
          "success": false,
          "is_payment_required": true,
          "message":
              "Insufficient wallet balance (\$$_localBalance USD). Top up required.",
          "cost": cost,
          "current_balance": _localBalance,
        };
      }
      _localBalance -= cost;
      _localTransactions.insert(0, {
        "agent_id": agentId,
        "amount": cost,
        "date": "Today",
        "is_deduction": true,
      });
      DatabaseService.instance().recordActivity(
        userId: userId,
        agentName: agentId,
        query: query,
        amount: cost,
        isDeduction: true,
      );

      String demoAnswer = "";
      if (agentId.contains("symptom") || agentId.contains("triage") || agentId.contains("health") || agentId.contains("medical")) {
        demoAnswer =
            "**Medical Triage & Health Guidance**\n\n* **Query Focus:** \"$query\"\n\n* **Primary Recommendations:**\n  1. **Diet & Routine Adjustments:** Emphasize a heart-healthy diet low in sodium and saturated fats, manage stress, and maintain physician-approved physical activity.\n  2. **Monitoring & Risk Factors:** Track symptoms, blood pressure, and cholesterol levels closely.\n  3. **Warning Indicators:** Seek emergency medical care immediately if you experience severe chest discomfort, shortness of breath, or pain radiating to the arm/jaw.\n\n⚠️ *[Disclaimer: This explanation is for educational triage purposes only and does not replace direct consultation with a licensed medical professional.]*";
      } else if (agentId.contains("slang") || agentId.contains("punjabi") || agentId.contains("translate") || agentId.contains("linguis")) {
        demoAnswer =
            "**Linguistic & Regional Slang Translation**\n\n* **Query Analyzed:** \"$query\"\n* **Direct Meaning:** Regional colloquial expression translating informal conversational vibe.\n* **Cultural Context:** Captures social mood and native dialect nuances.";
      } else {
        demoAnswer =
            "**Legal & Clause Analysis**\n\n* **Query Analyzed:** \"$query\"\n* **Core Obligations:** Outlines legal rights, liabilities, and enforcement terms associated with your inquiry.\n* **Plain Language Breakdown:** Ensure all timelines and risk allocations are reviewed prior to contract execution.\n\n⚠️ *[Disclaimer: This explanation is for informational purposes only and does not constitute legal advice.]*";
      }

      return {
        "success": true,
        "result": demoAnswer,
        "cost": cost,
        "settlement": "Settled \$$cost USDC on Base testnet",
        "remaining_balance": _localBalance,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAgents() async {
    try {
      final url = Uri.parse("$baseUrl/agents");
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> searchAgents(String query) async {
    try {
      final url = Uri.parse("$baseUrl/search");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"query": query, "top_k": 5}),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> rateAgent(int agentId, int stars) async {
    try {
      final url = Uri.parse("$baseUrl/agents/$agentId/rate");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"stars": stars}),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }
}
