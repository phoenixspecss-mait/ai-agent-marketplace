import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expert_ai/services/database/database_history_item.dart';
import 'package:expert_ai/services/database/database_service.dart';
import 'package:expert_ai/theme/app_theme.dart';

class HistoryView extends StatefulWidget {
  final VoidCallback onNewChatPressed;
  const HistoryView({super.key, required this.onNewChatPressed});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> with SingleTickerProviderStateMixin {
  late AnimationController _fabPulseController;
  late Animation<double> _fabPulseAnimation;

  late Future<List<DatabaseHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fabPulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _fabPulseController, curve: Curves.easeInOut),
    );

    _refreshHistory();
  }

  void _refreshHistory() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "demo_user_01";
    setState(() {
      _historyFuture = DatabaseService.instance().fetchHistory(userId);
    });
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppTheme.emeraldGreen),
                        onPressed: _refreshHistory,
                        tooltip: "Refresh History",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: FutureBuilder<List<DatabaseHistoryItem>>(
                      future: _historyFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  "Failed to load activity history.",
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                ),
                                TextButton(
                                  onPressed: _refreshHistory,
                                  child: const Text("Retry", style: TextStyle(color: AppTheme.emeraldGreen)),
                                ),
                              ],
                            ),
                          );
                        }

                        final historyItems = snapshot.data ?? [];

                        if (historyItems.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, color: Colors.white.withValues(alpha: 0.3), size: 54),
                                const SizedBox(height: 12),
                                Text(
                                  "No past agent executions found.",
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: AppTheme.emeraldGreen,
                          backgroundColor: const Color(0xFF131D1A),
                          onRefresh: () async {
                            _refreshHistory();
                            await _historyFuture;
                          },
                          child: ListView.separated(
                            itemCount: historyItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = historyItems[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 60)),
                                curve: Curves.easeOutCubic,
                                builder: (context, val, child) {
                                  return Opacity(
                                    opacity: val,
                                    child: Transform.translate(
                                      offset: Offset(0, 15 * (1 - val)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131D1A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF23322E), width: 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: item.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: item.color,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.verified,
                                                  color: AppTheme.emeraldGreen,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  item.agentName,
                                                  style: const TextStyle(
                                                    color: AppTheme.emeraldGreen,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  item.timeAgo,
                                                  style: const TextStyle(
                                                    color: Color(0xFF9CA3AF),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.query,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (item.amount > 0) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                item.isDeduction
                                                    ? "-\$${item.amount.toStringAsFixed(4)} USD"
                                                    : "+\$${item.amount.toStringAsFixed(2)} USD",
                                                style: TextStyle(
                                                  color: item.isDeduction
                                                      ? Colors.white38
                                                      : AppTheme.emeraldGreen,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Pulsing Floating "+ New Chat" Button
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: ScaleTransition(
                  scale: _fabPulseAnimation,
                  child: GestureDetector(
                    onTap: widget.onNewChatPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldDark,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.emeraldGreen.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "New Chat",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
