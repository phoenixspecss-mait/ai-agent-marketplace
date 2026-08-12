import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expert_ai/views/register_login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeSlider extends StatefulWidget {
  const WelcomeSlider({super.key});

  @override
  State<WelcomeSlider> createState() => _WelcomeSliderState();
}

class _WelcomeSliderState extends State<WelcomeSlider>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Dark Theme Design Tokens matching reference screenshots
  static const Color bgDark = Color(0xFF0B120F);
  static const Color mintGreen = Color(0xFF50F89A);
  static const Color cardDark = Color(0xFF131E1A);
  static const Color cardBorder = Color(0xFF1F312A);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color darkButtonText = Color(0xFF081410);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animController.reset();
    _animController.forward();
    HapticFeedback.selectionClick();
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  Future<void> _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegisterLoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header with Skip Button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _goToLogin,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main PageView Content ──────────────────────────────────
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPage(
                    visual: _buildSlide1Visual(),
                    title: "The world's experts, in one assistant.",
                    subtitle:
                        "Ask anything and let our network of specialist AI agents find the answer for you.",
                  ),
                  _buildPage(
                    visual: _buildSlide2Visual(),
                    title: "Invisible Coordination.",
                    subtitle:
                        "We find the best specialist for your query and handle the micro-payment instantly behind the scenes.",
                  ),
                  _buildPage(
                    visual: _buildSlide3Visual(),
                    title: "Verified, Precise, Fast.",
                    subtitle:
                        "Get started with a small wallet balance and only pay for what you use.",
                  ),
                ],
              ),
            ),

            // ── Bottom Navigation Controls ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Animated Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? mintGreen : const Color(0xFF273B33),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Button (Full Width Mint Green)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mintGreen,
                        foregroundColor: darkButtonText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkButtonText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: darkButtonText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required Widget visual,
    required String title,
    required String subtitle,
  }) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top Visual Illustration Container
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: visual,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Main Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textWhite,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textGrey,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Slide 1 Visual: Central Mint Agent Box with Satellite Cards (Dark) ───
  Widget _buildSlide1Visual() {
    return SizedBox(
      width: 280,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Connecting Dashed Lines Simulation
          CustomPaint(
            size: const Size(280, 250),
            painter: _DashedConnectorPainter(),
          ),

          // Central Mint Green Box with Robot Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: mintGreen,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: mintGreen.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.smart_toy_rounded,
                color: darkButtonText,
                size: 52,
              ),
            ),
          ),

          // Satellite Card 1 (Top-Left: Edit/Writing)
          Positioned(
            top: 20,
            left: 20,
            child: _buildSatelliteCard(Icons.edit_note_rounded, textGrey),
          ),

          // Satellite Card 2 (Top-Right: Medical)
          Positioned(
            top: 20,
            right: 20,
            child: _buildSatelliteCard(Icons.medical_services_rounded, const Color(0xFFFCA5A5)),
          ),

          // Satellite Card 3 (Bottom-Left: Code)
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildSatelliteCard(Icons.code_rounded, mintGreen),
          ),

          // Satellite Card 4 (Bottom-Right: Analytics)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildSatelliteCard(Icons.bar_chart_rounded, textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteCard(IconData icon, Color iconColor) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  // ── Slide 2 Visual: Vertical Pipeline Flow (Dark Mode) ──────────────────
  Widget _buildSlide2Visual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step 1: Searching
          _buildPipelineStep(
            icon: Icons.search_rounded,
            iconBg: const Color(0xFF192823),
            iconColor: textGrey,
            title: "Searching",
            subtitle: "Scanning specialized networks",
          ),

          // Connecting Line
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 24,
                color: const Color(0xFF253A32),
              ),
            ),
          ),

          // Step 2: Comparing
          _buildPipelineStep(
            icon: Icons.compare_arrows_rounded,
            iconBg: const Color(0xFF192823),
            iconColor: textGrey,
            title: "Comparing",
            subtitle: "Evaluating expertise & cost",
          ),

          // Connecting Line
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 24,
                color: const Color(0xFF253A32),
              ),
            ),
          ),

          // Step 3: Paying
          _buildPipelineStep(
            icon: Icons.check_circle_rounded,
            iconBg: mintGreen,
            iconColor: darkButtonText,
            title: "Paying",
            subtitle: "Frictionless micro-transaction",
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Slide 3 Visual: Balance Card (Dark Mode) ───────────────────────────
  Widget _buildSlide3Visual() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row with SECURE Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF142E25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1F4A3B), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: mintGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "SECURE",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mintGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Label: AVAILABLE BALANCE
          Text(
            "AVAILABLE BALANCE",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textGrey,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // Big Display Amount: $ 4.82
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "\$",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textWhite,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "4.82",
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: textWhite,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Center Mint Circle Checkmark
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: mintGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: mintGreen.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: darkButtonText,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter for Dashed Connector Lines in Slide 1 ─────────────────
class _DashedConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF273B33)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final offsets = [
      const Offset(46, 46),
      Offset(size.width - 46, 46),
      Offset(46, size.height - 46),
      Offset(size.width - 46, size.height - 46),
    ];

    for (final target in offsets) {
      _drawDashedLine(canvas, center, target, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4;
    const double dashSpace = 4;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = (dx * dx + dy * dy);
    final double count = distance / (dashWidth + dashSpace);

    double x = p1.dx;
    double y = p1.dy;

    for (int i = 0; i < count; i++) {
      final double endX = x + (dx / count) * (dashWidth / (dashWidth + dashSpace));
      final double endY = y + (dy / count) * (dashWidth / (dashWidth + dashSpace));
      canvas.drawLine(Offset(x, y), Offset(endX, endY), paint);
      x += (dx / count);
      y += (dy / count);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}