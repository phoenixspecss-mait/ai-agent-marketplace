import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';

class AccountView extends StatefulWidget {
  final double currentBalance;
  final Function(double) onBalanceUpdated;

  const AccountView({
    super.key,
    required this.currentBalance,
    required this.onBalanceUpdated,
  });

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  int _selectedTopUpAmount = 10;
  bool _isProcessing = false;

  Future<void> _handleTopUp() async {
    setState(() => _isProcessing = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "demo_user_01";

    final newBal = await ApiService.topUpWallet(userId, _selectedTopUpAmount.toDouble());

    if (!mounted) return;
    setState(() => _isProcessing = false);
    widget.onBalanceUpdated(newBal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text("Successfully added \$$_selectedTopUpAmount.00 to your wallet!"),
          ],
        ),
        backgroundColor: AppTheme.emeraldDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ApiService.localTransactions;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Current Balance Header Display
              const Text(
                "CURRENT BALANCE",
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Animated Balance Counter
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: widget.currentBalance),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, balVal, child) {
                  return Text(
                    "\$${balVal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppTheme.emeraldGreen,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Top Up Wallet Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF23322E), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Top Up Wallet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3 Animated Option Pills ($5, $10 POPULAR, $20)
                    Row(
                      children: [
                        Expanded(child: _buildAnimatedAmountOption(5)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildAnimatedAmountOption(10, isPopular: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildAnimatedAmountOption(20)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Proceed to Payment Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isProcessing ? null : _handleTopUp,
                        child: _isProcessing
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.payment, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Proceed to Payment",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subtext
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 14),
                          SizedBox(width: 6),
                          Text(
                            "Secure Payment processing via Stripe / x402",
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Recent Activity Card Section with Animated Entry
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF23322E), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "RECENT ACTIVITY",
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF23322E), height: 1),
                    const SizedBox(height: 14),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = transactions[index];
                        final isDeduction = item['is_deduction'] ?? true;
                        final amount = (item['amount'] as num).toDouble();

                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['agent_id'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['date'],
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              isDeduction
                                  ? "-\$${amount.toStringAsFixed(3)}"
                                  : "+\$${amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isDeduction ? const Color(0xFFFF7675) : AppTheme.emeraldGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAmountOption(int amount, {bool isPopular = false}) {
    final isSelected = _selectedTopUpAmount == amount;

    return GestureDetector(
      onTap: () => setState(() => _selectedTopUpAmount = amount),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1B2A26) : const Color(0xFF0F1715),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.emeraldGreen : const Color(0xFF23322E),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Text(
              "\$$amount",
              style: TextStyle(
                color: isSelected ? AppTheme.emeraldGreen : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (isPopular)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "POPULAR",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
