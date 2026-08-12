import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/services/database/database_history_item.dart';
import 'package:expert_ai/services/database/database_provider.dart';

class AppDatabaseProvider implements DatabaseProvider {
  static const String _prefKeyHistory = "user_activity_history_v1";

  // Default seed activity items for initial view
  static final List<Map<String, dynamic>> _defaultSeedHistory = [
    {
      "id": "1",
      "agent": "Linguistics AI",
      "time": "2h ago",
      "query": "\"Translate this Bhojpuri folk song...\"",
      "amount": 0.002,
      "is_deduction": true,
    },
    {
      "id": "2",
      "agent": "Legal Concierge",
      "time": "Yesterday",
      "query": "\"Review this freelance contract clause...\"",
      "amount": 0.005,
      "is_deduction": true,
    },
    {
      "id": "3",
      "agent": "Medical Triage AI",
      "time": "Oct 12",
      "query": "\"What are the typical side effects of NSAIDs?...\"",
      "amount": 0.003,
      "is_deduction": true,
    },
    {
      "id": "4",
      "agent": "Code Architect",
      "time": "Oct 10",
      "query": "\"Help me refactor this React custom hook...\"",
      "amount": 0.004,
      "is_deduction": true,
    },
    {
      "id": "5",
      "agent": "Tax Advisor",
      "time": "Sep 28",
      "query": "\"Deductible expenses for home office equipment...\"",
      "amount": 0.005,
      "is_deduction": true,
    },
  ];

  @override
  Future<List<DatabaseHistoryItem>> fetchHistory(String userId) async {
    List<DatabaseHistoryItem> items = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString("${_prefKeyHistory}_$userId");

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        items = decoded.map((m) => DatabaseHistoryItem.fromMap(Map<String, dynamic>.from(m))).toList();
      } else {
        // Initialize with default seeds
        items = _defaultSeedHistory.map((m) => DatabaseHistoryItem.fromMap(m)).toList();
        await _saveHistoryToPrefs(userId, items);
      }

      // Also merge with recent local transactions from ApiService
      for (final tx in ApiService.localTransactions) {
        final txAgent = tx['agent_id'] ?? 'Specialist Agent';
        final txDate = tx['date'] ?? 'Today';
        final txAmt = (tx['amount'] as num?)?.toDouble() ?? 0.004;
        final isDed = tx['is_deduction'] ?? true;

        final exists = items.any((item) => item.agentName == txAgent && item.timeAgo == txDate);
        if (!exists) {
          items.insert(
            0,
            DatabaseHistoryItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              agentName: txAgent,
              query: isDed ? "\"Specialist query execution...\"" : "\"Wallet Top Up\"",
              amount: txAmt,
              timeAgo: txDate,
              isDeduction: isDed,
              icon: isDed ? Icons.auto_awesome_rounded : Icons.account_balance_wallet_rounded,
              color: isDed ? const Color(0xFF00B894) : const Color(0xFF00CEC9),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      items = _defaultSeedHistory.map((m) => DatabaseHistoryItem.fromMap(m)).toList();
    }
    return items;
  }

  @override
  Future<void> recordActivity({
    required String userId,
    required String agentName,
    required String query,
    required double amount,
    bool isDeduction = true,
  }) async {
    try {
      final currentList = await fetchHistory(userId);
      final newItem = DatabaseHistoryItem.fromMap({
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "agent": agentName,
        "query": "\"$query\"",
        "amount": amount,
        "time": "Just now",
        "is_deduction": isDeduction,
      });

      currentList.insert(0, newItem);
      await _saveHistoryToPrefs(userId, currentList);
    } catch (e) {
      debugPrint("Error recording activity: $e");
    }
  }

  @override
  Future<void> clearHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("${_prefKeyHistory}_$userId");
    } catch (e) {
      debugPrint("Error clearing history: $e");
    }
  }

  Future<void> _saveHistoryToPrefs(String userId, List<DatabaseHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((i) => i.toMap()).toList();
      await prefs.setString("${_prefKeyHistory}_$userId", jsonEncode(jsonList));
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }
}
