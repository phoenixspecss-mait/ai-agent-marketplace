import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _fabPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> historyItems = [
      {
        "agent": "Linguistics AI",
        "time": "2h ago",
        "query": "\"Translate this Bhojpuri folk so...\"",
        "icon": Icons.translate_rounded,
        "color": const Color(0xFF00B894),
      },
      {
        "agent": "Legal Concierge",
        "time": "Yesterday",
        "query": "\"Review this freelance contrac...\"",
        "icon": Icons.gavel_rounded,
        "color": const Color(0xFF3A26B5),
      },
      {
        "agent": "Medical Triage AI",
        "time": "Oct 12",
        "query": "\"What are the typical side effe...\"",
        "icon": Icons.medical_services_rounded,
        "color": const Color(0xFFE17055),
      },
      {
        "agent": "Code Architect",
        "time": "Oct 10",
        "query": "\"Help me refactor this React c...\"",
        "icon": Icons.code_rounded,
        "color": const Color(0xFF0984E3),
      },
      {
        "agent": "Tax Advisor",
        "time": "Sep 28",
        "query": "\"Deductible expenses for a ho...\"",
        "icon": Icons.account_balance_rounded,
        "color": const Color(0xFFFDCB6E),
      },
    ];

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
                  const Text(
                    "History",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.separated(
                      itemCount: historyItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = historyItems[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, child) {
                            return Opacity(
                              opacity: val,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - val)),
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
                                    color: (item['color'] as Color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: item['color'] as Color,
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
                                            item['agent'],
                                            style: const TextStyle(
                                              color: AppTheme.emeraldGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            item['time'],
                                            style: const TextStyle(
                                              color: Color(0xFF9CA3AF),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['query'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
