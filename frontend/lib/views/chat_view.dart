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

  Future<void> _sendMessage([
    String? presetQuery,
    String? agentIdOverride,
  ]) async {
    final text = presetQuery ?? _queryController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _queryController.clear();

    setState(() {
      _messages.add(MessageItem(sender: 'user', text: text));
      _isLoading = true;
    });
    _scrollToBottom();

    // Dynamically assign agent according to user query topic
    String agentId = agentIdOverride ?? "";
    if (agentId.isEmpty) {
      final lower = text.toLowerCase();
      // Inspect high-priority domain keywords first
      if (lower.contains("cardiac") ||
          lower.contains("heart") ||
          lower.contains("artery") ||
          lower.contains("arteries") ||
          lower.contains("diet") ||
          lower.contains("routine") ||
          lower.contains("blood") ||
          lower.contains("symptom") ||
          lower.contains("pain") ||
          lower.contains("fever") ||
          lower.contains("hurt") ||
          lower.contains("headache") ||
          lower.contains("medical") ||
          lower.contains("sprain") ||
          lower.contains("doctor") ||
          lower.contains("health") ||
          lower.contains("triage") ||
          lower.contains("disease") ||
          lower.contains("illness") ||
          lower.contains("condition") ||
          lower.contains("chest") ||
          lower.contains("advice") ||
          lower.contains("treatment") ||
          lower.contains("block")) {
        agentId = "symptom-triage-explainer";
      } else if (lower.contains("slang") ||
          lower.contains("bhojpuri") ||
          lower.contains("punjabi") ||
          lower.contains("translate") ||
          lower.contains("hindi") ||
          lower.contains("meaning") ||
          lower.contains("vibe") ||
          lower.contains("idiom") ||
          lower.contains("colloquial")) {
        agentId = "punjabi-slang-translator";
      } else if (lower.contains("contract") ||
          lower.contains("clause") ||
          lower.contains("legal") ||
          lower.contains("agreement") ||
          lower.contains("law") ||
          lower.contains("court") ||
          lower.contains("arbitration") ||
          lower.contains("liability") ||
          lower.contains("nda") ||
          lower.contains("tenant") ||
          lower.contains("lease") ||
          lower.contains("waiver")) {
        agentId = "legal-clause-explainer";
      } else if (lower.contains("jee") ||
          lower.contains("math") ||
          lower.contains("calculus") ||
          lower.contains("integration") ||
          lower.contains("physics") ||
          lower.contains("chemistry") ||
          lower.contains("exam") ||
          lower.contains("study") ||
          lower.contains("code") ||
          lower.contains("tech") ||
          lower.contains("resume") ||
          lower.contains("career") ||
          lower.contains("job") ||
          lower.contains("interview") ||
          lower.contains("prep") ||
          lower.contains("algorithm")) {
        agentId = "career-agent";
      } else {
        try {
          final searchResults = await ApiService.searchAgents(text);
          if (searchResults.isNotEmpty) {
            final topMatch = searchResults.first;
            final score = (topMatch['match_score'] as num?)?.toDouble() ?? 0.0;
            if (score > 0.1) {
              final topAgent = topMatch['agent'];
              if (topAgent != null && topAgent is Map) {
                agentId =
                    (topAgent['endpoint_or_identifier'] ??
                            topAgent['category'] ??
                            "")
                        .toString();
              }
            }
          }
        } catch (_) {}

        if (agentId.isEmpty) {
          agentId = "career-agent";
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
        if (agentId.contains("slang") ||
            agentId.contains("translator") ||
            agentId.contains("linguis")) {
          badge = "VERIFIED LINGUISTICS";
        } else if (agentId.contains("symptom") ||
            agentId.contains("medical") ||
            agentId.contains("triage") ||
            agentId.contains("health")) {
          badge = "VERIFIED MEDICAL";
        } else if (agentId.contains("career") ||
            agentId.contains("tech") ||
            agentId.contains("stem")) {
          badge = "VERIFIED STEM & CAREER";
        }

        _messages.add(
          MessageItem(
            sender: 'ai',
            text: response['result'],
            agentId: agentId,
            badgeText: badge,
            settlement: response['settlement'],
          ),
        );
        if (response['remaining_balance'] != null) {
          widget.onBalanceUpdated(
            (response['remaining_balance'] as num).toDouble(),
          );
        }
      } else {
        _messages.add(
          MessageItem(
            sender: 'ai',
            text: response['message'] ?? "Error processing request.",
            isError: true,
          ),
        );
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return _buildDesktopChatView();
    }

    // Mobile View (< 900px)
    final isNewChat = _messages.isEmpty;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: isNewChat
                    ? _buildHomeHeroView()
                    : _buildActiveChatList(),
              ),
            ),
            _buildBottomInputArea(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // DESKTOP LAYOUT (Image 4 Landing & Image 1 Active Chat with Right Insights)
  // =========================================================================
  Widget _buildDesktopChatView() {
    final isNewChat = _messages.isEmpty;

    return Row(
      children: [
        // Main Chat Canvas Area
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: isNewChat
                    ? _buildDesktopNewChatLanding()
                    : _buildDesktopActiveChatList(),
              ),
              _buildDesktopBottomInputArea(isNewChat),
            ],
          ),
        ),

        // Right Sidebar (Expert Insights Panel - Image 1) - Only visible when in active chat or wide screen
        if (!isNewChat)
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Color(0xFF0C1412),
              border: Border(
                left: BorderSide(color: Color(0xFF1E2C29), width: 1),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Expert Insights",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Verified Source Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3A2E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.emeraldGreen,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "VERIFIED SOURCE",
                        style: TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Reference Insight Card 1 (CA Senate Bill 699)
                _buildInsightCard(
                  title: "CA Senate Bill 699",
                  subtitle:
                      "An act to add Section 16600.5 to the Business and Professions Code relating to contracts. Voids non-competes.",
                ),
                const SizedBox(height: 14),

                // Reference Insight Card 2 (Edwards v. Arthur Andersen LLP)
                _buildInsightCard(
                  title: "Edwards v. Arthur Andersen LLP",
                  subtitle:
                      "Key California Supreme Court ruling affirming the state's strong public policy against non-compete clauses.",
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInsightCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF23322E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- Desktop Landing Page View (Image 4) ---
  Widget _buildDesktopNewChatLanding() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A110F),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pill Badge: • Network Online (Image 4)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF13241F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: AppTheme.emeraldGreen,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Network Online",
                      style: TextStyle(
                        color: AppTheme.emeraldGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title (Image 4)
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1.0,
                  ),
                  children: [
                    TextSpan(text: "Expert Legal Analysis,\n"),
                    TextSpan(
                      text: "Instantly Accessible.",
                      style: TextStyle(color: AppTheme.emeraldGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  "Connect with specialized AI agents trained on jurisdictional precedent, compliance frameworks, and contract law.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Large Prompt Box Container (Image 4)
              Container(
                constraints: const BoxConstraints(maxWidth: 780),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF23322E),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _queryController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText:
                            "Describe your legal query, paste a contract snippet, or ask about regulatory compliance...",
                        hintStyle: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                            color: Color(0xFF9CA3AF),
                            size: 22,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 22,
                          ),
                          onPressed: () {},
                        ),
                        const Spacer(),

                        // Analyze Button
                        ElevatedButton(
                          onPressed: () => _sendMessage(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emeraldGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            children: const [
                              Text(
                                "Analyze",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.send_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Common Inquiries Pills (Image 4)
              const Text(
                "COMMON INQUIRIES",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),

              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildDesktopInquiryPill(
                    icon: Icons.description_outlined,
                    label: "Review NDA Terms",
                    onTap: () {
                      _sendMessage(
                        "Review standard non-disclosure agreement (NDA) obligations, exclusions, and remedies.",
                        "legal-clause-explainer",
                      );
                    },
                  ),
                  _buildDesktopInquiryPill(
                    icon: Icons.menu_book_outlined,
                    label: "Entity Formation Guide",
                    onTap: () {
                      _sendMessage(
                        "Explain corporate entity formation steps and liability protections for Delaware C-Corp vs LLC.",
                        "legal-clause-explainer",
                      );
                    },
                  ),
                  _buildDesktopInquiryPill(
                    icon: Icons.security_outlined,
                    label: "Data Privacy Compliance",
                    onTap: () {
                      _sendMessage(
                        "What are key data privacy compliance requirements under GDPR and CCPA for tech SaaS platforms?",
                        "legal-clause-explainer",
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopInquiryPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF131D1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF23322E)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.emeraldGreen, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Desktop Active Chat Stream (Image 1) ---
  Widget _buildDesktopActiveChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildDesktopThinkingIndicator();
        }

        final msg = _messages[index];
        return msg.sender == 'user'
            ? _buildDesktopUserBubble(msg.text)
            : _buildDesktopAiBubble(msg);
      },
    );
  }

  Widget _buildDesktopThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.search, color: Color(0xFF9CA3AF), size: 16),
              SizedBox(width: 8),
              Text(
                "Searching precedent database...",
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.sync, color: AppTheme.emeraldGreen, size: 16),
              SizedBox(width: 8),
              Text(
                "Synthesizing legal risk assessment...",
                style: TextStyle(
                  color: AppTheme.emeraldGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopUserBubble(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2A27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A3C38)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  IconData _getDomainIcon(String? badgeText, String? agentId) {
    final b = (badgeText ?? "").toUpperCase();
    final a = (agentId ?? "").toLowerCase();
    if (b.contains("MEDICAL") || a.contains("symptom") || a.contains("health")) {
      return Icons.medical_services_outlined;
    }
    if (b.contains("LINGUISTICS") || a.contains("slang") || a.contains("translate")) {
      return Icons.translate_rounded;
    }
    if (b.contains("STEM") || b.contains("CAREER") || a.contains("career") || a.contains("tech")) {
      return Icons.school_outlined;
    }
    return Icons.gavel_rounded;
  }

  String _getDomainTitle(String? badgeText, String? agentId, bool isError) {
    if (isError) return "Execution Error";
    final b = (badgeText ?? "").toUpperCase();
    final a = (agentId ?? "").toLowerCase();
    if (b.contains("MEDICAL") || a.contains("symptom") || a.contains("health")) {
      return "Medical Triage Complete";
    }
    if (b.contains("LINGUISTICS") || a.contains("slang") || a.contains("translate")) {
      return "Translation Complete";
    }
    if (b.contains("STEM") || b.contains("CAREER") || a.contains("career") || a.contains("tech")) {
      return "STEM & Career Analysis Complete";
    }
    return "Legal Analysis Complete";
  }

  String _cleanMarkdownText(String raw) {
    if (raw.isEmpty) return raw;
    final lines = raw.split('\n');
    final cleaned = lines.map((l) {
      final trimmed = l.trimLeft();
      if (trimmed.startsWith('### ')) return trimmed.substring(4);
      if (trimmed.startsWith('## ')) return trimmed.substring(3);
      if (trimmed.startsWith('# ')) return trimmed.substring(2);
      return l;
    }).join('\n');
    return cleaned.trim();
  }

  Widget _buildDesktopAiBubble(MessageItem msg) {
    final icon = _getDomainIcon(msg.badgeText, msg.agentId);
    final title = _getDomainTitle(msg.badgeText, msg.agentId, msg.isError);
    final cleanedText = _cleanMarkdownText(msg.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: msg.isError
              ? Colors.redAccent.withValues(alpha: 0.4)
              : AppTheme.emeraldGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Label with Domain Icon & Dynamic Title
          Row(
            children: [
              Icon(icon, color: AppTheme.emeraldGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.emeraldGreen,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (msg.badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3A2E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.emeraldGreen.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    msg.badgeText!,
                    style: const TextStyle(
                      color: AppTheme.emeraldGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            cleanedText,
            style: TextStyle(
              color: msg.isError ? Colors.redAccent.shade100 : Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (msg.settlement != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.emeraldGreen, size: 14),
                const SizedBox(width: 6),
                Text(
                  msg.settlement!,
                  style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Desktop Bottom Input Area ---
  Widget _buildDesktopBottomInputArea(bool isNewChat) {
    if (isNewChat) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        border: Border(top: BorderSide(color: Color(0xFF1E2C29), width: 1)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131D1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF23322E)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFF9CA3AF)),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _queryController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText:
                      "Ask a follow-up question or upload another document...",
                  hintStyle: TextStyle(color: Color(0xFF6B7280)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.emeraldGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ),
              onPressed: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MOBILE LAYOUT (< 900px)
  // =========================================================================
  Widget _buildHomeHeroView() {
    return SingleChildScrollView(
      key: const ValueKey("home_hero"),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 30),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2925),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
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
          const Text(
            "How can I help\nyou today?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
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
    return Material(
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
    );
  }

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
        return msg.sender == 'user'
            ? _buildUserBubble(msg.text)
            : _buildAiBubble(msg);
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
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.emeraldGreen,
                  ),
                ),
                SizedBox(width: 10),
                Text(
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
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2A27),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3C38)),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(MessageItem msg) {
    final cleanedText = _cleanMarkdownText(msg.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: msg.isError
                  ? const Color(0xFF331616)
                  : const Color(0xFF131D1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: msg.isError
                    ? Colors.redAccent.withValues(alpha: 0.4)
                    : const Color(0xFF23322E),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.badgeText != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3A2E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        msg.badgeText!,
                        style: const TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  cleanedText,
                  style: TextStyle(
                    color: msg.isError ? Colors.redAccent.shade100 : Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: AppTheme.darkBackground,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF131D1A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF23322E), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _queryController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: "Ask an expert...",
                  hintStyle: TextStyle(color: Color(0xFF6B7280)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
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
    );
  }
}
