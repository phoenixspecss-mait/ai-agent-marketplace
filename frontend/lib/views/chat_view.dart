import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';

class ChatView extends StatefulWidget {
  final Function(double) onBalanceUpdated;
  const ChatView({super.key, required this.onBalanceUpdated});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class MessageItem {
  final String sender; // 'user' or 'ai'
  final String text;
  final String? agentId;
  final String? badgeText;
  final String? settlement;
  final bool isError;

  MessageItem({
    required this.sender,
    required this.text,
    this.agentId,
    this.badgeText,
    this.settlement,
    this.isError = false,
  });
}

class _ChatViewState extends State<ChatView> with TickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageItem> _messages = [];
  bool _isLoading = false;
  String _selectedAgentId = "legal-clause-explainer";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Hero icon breathing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetQuery, String? agentIdOverride]) async {
    final text = presetQuery ?? _queryController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _queryController.clear();

    setState(() {
      _messages.add(MessageItem(
        sender: 'user',
        text: text,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    // Dynamically assign agent according to user query topic
    String agentId = agentIdOverride ?? "";
    if (agentId.isEmpty) {
      try {
        final searchResults = await ApiService.searchAgents(text);
        if (searchResults.isNotEmpty) {
          final topAgent = searchResults.first['agent'];
          if (topAgent != null && topAgent is Map) {
            agentId = (topAgent['endpoint_or_identifier'] ?? topAgent['category'] ?? "").toString();
          }
        }
      } catch (_) {}

      // Fallback topic classifier if search is offline or unindexed
      if (agentId.isEmpty) {
        final lower = text.toLowerCase();
        if (lower.contains("slang") || lower.contains("bhojpuri") || lower.contains("punjabi") || lower.contains("translate") || lower.contains("hindi") || lower.contains("meaning") || lower.contains("vibe") || lower.contains("idiom")) {
          agentId = "punjabi-slang-translator";
        } else if (lower.contains("symptom") || lower.contains("pain") || lower.contains("fever") || lower.contains("hurt") || lower.contains("headache") || lower.contains("medical") || lower.contains("sprain") || lower.contains("doctor") || lower.contains("health") || lower.contains("triage")) {
          agentId = "symptom-triage-explainer";
        } else {
          agentId = "legal-clause-explainer";
        }
      }
    }

    final userId = FirebaseAuth.instance.currentUser?.uid ?? "demo_user_01";
    final response = await ApiService.callAgent(
      userId: userId,
      agentId: agentId,
      query: text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response['success'] == true) {
        String badge = "VERIFIED LEGAL";
        if (agentId.contains("slang")) badge = "VERIFIED LINGUISTICS";
        if (agentId.contains("symptom")) badge = "VERIFIED MEDICAL";

        _messages.add(MessageItem(
          sender: 'ai',
          text: response['result'],
          agentId: agentId,
          badgeText: badge,
          settlement: response['settlement'],
        ));
        if (response['remaining_balance'] != null) {
          widget.onBalanceUpdated((response['remaining_balance'] as num).toDouble());
        }
      } else {
        _messages.add(MessageItem(
          sender: 'ai',
          text: response['message'] ?? "Error processing request.",
          isError: true,
        ));
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isNewChat = _messages.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: isNewChat ? _buildHomeHeroView() : _buildActiveChatList(),
              ),
            ),
            _buildBottomInputArea(),
          ],
        ),
      ),
    );
  }

  // --- Home / New Chat View (Screenshot 4) with Entrance & Breathing Animations ---
  Widget _buildHomeHeroView() {
    return SingleChildScrollView(
      key: const ValueKey("home_hero"),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 30),

          // Animated Pulsing Hero AI Sparkle Container
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2925),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.emeraldGreen,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Title with Fade-In
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, val, child) {
              return Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - val)),
                  child: child,
                ),
              );
            },
            child: const Text(
              "How can I help\nyou today?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Connect with verified experts across domains.\nAsk your question below to get started.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // 3 Interactive Prompt Pills with Staggered Slide-Up
          _buildAnimatedPromptPill(
            index: 0,
            icon: Icons.description_outlined,
            label: "Explain this rental clause",
            onTap: () {
              setState(() => _selectedAgentId = "legal-clause-explainer");
              _sendMessage(
                "Can you explain clause 4.2 in my lease agreement regarding 'Fair Wear and Tear'? Does this cover minor scuffs on the hardwood floor from moving furniture?",
                "legal-clause-explainer",
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAnimatedPromptPill(
            index: 1,
            icon: Icons.translate_outlined,
            label: "Translate this Bhojpuri slang",
            onTap: () {
              setState(() => _selectedAgentId = "punjabi-slang-translator");
              _sendMessage(
                "Translate this Bhojpuri folk song phrase or regional slang and explain the vibe breakdown.",
                "punjabi-slang-translator",
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAnimatedPromptPill(
            index: 2,
            icon: Icons.medical_services_outlined,
            label: "What does this symptom mean?",
            onTap: () {
              setState(() => _selectedAgentId = "symptom-triage-explainer");
              _sendMessage(
                "What are the non-emergency care steps for an acute sprain using RICE protocol?",
                "symptom-triage-explainer",
              );
            },
          ),

          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFF6B7280), size: 16),
              SizedBox(width: 6),
              Text(
                "Responses are verified by domain professionals.",
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPromptPill({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 150)),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          splashColor: AppTheme.emeraldGreen.withValues(alpha: 0.15),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131D1A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF23322E), width: 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.emeraldGreen, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Active Chat Message List (Screenshot 2) with Smooth Entrance Animations ---
  Widget _buildActiveChatList() {
    return ListView.builder(
      key: const ValueKey("active_chat"),
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildThinkingIndicator();
        }

        final msg = _messages[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return Opacity(
              opacity: val,
              child: Transform.scale(
                scale: 0.95 + (0.05 * val),
                child: child,
              ),
            );
          },
          child: msg.sender == 'user' ? _buildUserBubble(msg.text) : _buildAiBubble(msg),
        );
      },
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.emeraldGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131D1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF23322E)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.emeraldGreen,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Expert AI is processing...",
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2724),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "Today, 2:14 PM",
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                "You",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF263330),
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2A27),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3C38)),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(MessageItem msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.emeraldGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                "Expert AI",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (msg.badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3A2E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.emeraldGreen, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        msg.badgeText!,
                        style: const TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: msg.isError ? const Color(0xFF331616) : const Color(0xFF131D1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: msg.isError ? Colors.redAccent.withValues(alpha: 0.4) : const Color(0xFF23322E),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    color: msg.isError ? Colors.redAccent.shade100 : Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                if (msg.settlement != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "⚡ ${msg.settlement}",
                      style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Input Bar ---
  Widget _buildBottomInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF131D1A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF23322E), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: Color(0xFF9CA3AF), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: "Ask an expert...",
                      hintStyle: TextStyle(color: Color(0xFF6B7280)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppTheme.emeraldGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "AI can make mistakes. Consider verifying important information.",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
