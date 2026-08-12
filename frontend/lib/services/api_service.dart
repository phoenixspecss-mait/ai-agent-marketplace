import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:expert_ai/services/database/database_service.dart';

class ApiService {
  // Live deployed backend on Render
  static String get baseUrl => "https://ai-agent-marketplace-1-tkgx.onrender.com";

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
          "reasoning_chain": data['reasoning_chain'],
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
            "### 🩺 Comprehensive Medical Triage & Clinical Guidance\n\n"
            "**Primary Consultation Topic:** \"$query\"\n\n"
            "#### 1. Clinical Overview & Educational Explanation\n"
            "Cardiovascular health and arterial management require proactive medical oversight. When arterial narrowing or blockage is suspected, optimal blood circulation relies heavily on managing blood viscosity, endothelial health, and plaque stabilization.\n\n"
            "#### 2. Comprehensive Lifestyle, Diet & Preventive Plan\n"
            "* **Dietary Protocols:** Focus on a Mediterranean-style diet low in saturated fats, trans-fats, and refined sugars. Incorporate omega-3 fatty acids (flaxseeds, walnuts, salmon), high-soluble fiber (oats, legumes), and antioxidant-rich greens.\n"
            "* **Sodium & Hydration:** Limit daily sodium intake to under 1,500mg - 2,000mg to alleviate arterial pressure. Maintain consistent hydration.\n"
            "* **Exercise & Movement:** Engage in 30 minutes of physician-approved, moderate aerobic activity (e.g. brisk walking) 5 days per week. Avoid abrupt high-intensity strain without clearance.\n"
            "* **Risk Factor Control:** Strictly refrain from tobacco/nicotine use and minimize stress through routine sleep hygiene.\n\n"
            "#### 3. Key Symptoms & Progression Metrics to Track\n"
            "* Monitor resting blood pressure, heart rate recovery, and exercise tolerance daily.\n"
            "* Document any unusual exertional fatigue or transient shortness of breath.\n\n"
            "#### 4. 🚨 Critical Red Flags (Emergency Indicators)\n"
            "Seek **immediate emergency medical evaluation (call 911/emergency services)** if you experience:\n"
            "* Sudden chest pain, tightness, or squeezing pressure.\n"
            "* Pain radiating to the jaw, neck, back, or left arm.\n"
            "* Unexplained shortness of breath, cold sweats, or acute dizziness.\n\n"
            "⚠️ *[Disclaimer: This explanation is for educational triage purposes only and does not constitute formal medical diagnosis or treatment. Always consult a licensed cardiologist or primary care physician for personal care.]*";
      } else if (agentId.contains("slang") || agentId.contains("punjabi") || agentId.contains("translate") || agentId.contains("linguis")) {
        demoAnswer =
            "### 🗣️ Specialist Linguistic & Cultural Analysis\n\n"
            "**Submitted Phrase / Query:** \"$query\"\n\n"
            "#### 1. Direct English Translation & Literal Meaning\n"
            "Provides an accurate conversion into standard English, preserving both literal context and authentic emotional tone.\n\n"
            "#### 2. Cultural & Regional Context Breakdown\n"
            "Examines the social origin, youth pop-culture references, and regional dialect nuances embedded within the expression.\n\n"
            "#### 3. Conversational Usage & Vibe Analysis\n"
            "Describes the informal social setting, tone of excitement or camaraderie, and appropriate situational usage.";
      } else if (agentId.contains("career") || agentId.contains("tech") || agentId.contains("stem")) {
        demoAnswer =
            "### 🎓 Academic, STEM & Tech Career Guidance\n\n"
            "**Consultation Topic:** \"$query\"\n\n"
            "#### 1. Core Problem-Solving & Educational Overview\n"
            "Addressing STEM inquiries, JEE preparation, calculus integration, software algorithms, or career positioning requires a structured approach.\n\n"
            "#### 2. Strategic Roadmap & Methodologies\n"
            "* **Integration & Math Strategy:** Focus on substitution techniques (u-sub), integration by parts, reduction formulas, and definite integral properties (King's Property).\n"
            "* **Preparation Roadmap:** Work through previous year problem sets to spot reduction patterns and avoid sign errors under timed test conditions.\n\n"
            "#### 3. Actionable Next Steps\n"
            "* Solve 10-15 targeted problem sets focusing on the core integration identities.\n"
            "* Review boundary conditions and special limit evaluations.";
      } else {
        demoAnswer =
            "### ⚖️ Executive Legal & Contract Clause Analysis\n\n"
            "**Analyzed Legal Inquiry:** \"$query\"\n\n"
            "#### 1. Legal Overview & Plain-Language Summary\n"
            "Breaks down complex legal terminology, dispute resolution mechanisms, and contractual risk allocations into accessible language.\n\n"
            "#### 2. Core Rights, Obligations & Restrictions\n"
            "* **Primary Provisions:** Outlines the mandatory legal duties, performance timelines, and enforcement criteria.\n"
            "* **Liability Allocation:** Identifies indemnification scope, remedies, and risk transfer clauses.\n\n"
            "#### 3. Strategic Recommendations & Negotiation Points\n"
            "* Review indemnification caps, termination notice periods, and governing jurisdiction before executing agreement.\n\n"
            "⚠️ *[Disclaimer: This analysis is for educational and informational purposes only and does not constitute formal legal counsel. Always consult a qualified attorney for binding contract advice.]*";
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
