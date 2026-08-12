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

  Future<void> _handleTopUp([int? amountOverride]) async {
    final amount = amountOverride ?? _selectedTopUpAmount;
    setState(() => _isProcessing = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "demo_user_01";

    final newBal = await ApiService.topUpWallet(userId, amount.toDouble());

    if (!mounted) return;
    setState(() => _isProcessing = false);
    widget.onBalanceUpdated(newBal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text("Successfully added \$$amount.00 to your wallet!"),
          ],
        ),
        backgroundColor: AppTheme.emeraldDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddFundsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempAmount = 50;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131D1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF23322E)),
              ),
              title: const Text(
                "Add Wallet Funds",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select sub-cent micro-payment top-up amount:",
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [5, 10, 25, 50, 100].map((amt) {
                      final isSel = tempAmount == amt;
                      return ChoiceChip(
                        label: Text("\$$amt"),
                        selected: isSel,
                        onSelected: (_) => setDialogState(() => tempAmount = amt),
                        selectedColor: AppTheme.emeraldGreen,
                        backgroundColor: const Color(0xFF1D2A27),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleTopUp(tempAmount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Confirm Top-Up", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return _buildDesktopWalletView();
    }

    // Mobile View (< 900px)
    final transactions = ApiService.localTransactions;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
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
                      "TOP UP WALLET",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [5, 10, 25, 50].map((amount) {
                        final isSelected = _selectedTopUpAmount == amount;
                        return ChoiceChip(
                          label: Text("\$$amount"),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedTopUpAmount = amount),
                          selectedColor: AppTheme.emeraldGreen,
                          backgroundColor: const Color(0xFF1D2A27),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () => _handleTopUp(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text("Add \$$_selectedTopUpAmount.00 Funds", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Recent Activity", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("x402 Protocol Ledger", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final txn = transactions[index];
                  final isDeduction = txn['is_deduction'] == true;
                  final amount = (txn['amount'] as num).toDouble();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF23322E)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDeduction ? const Color(0xFF2A1919) : const Color(0xFF142C23),
                          child: Icon(
                            isDeduction ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isDeduction ? Colors.redAccent : AppTheme.emeraldGreen,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(txn['agent_id'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(txn['date'].toString(), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          "${isDeduction ? '-' : '+'}\$${amount.toStringAsFixed(3)}",
                          style: TextStyle(
                            color: isDeduction ? Colors.white70 : AppTheme.emeraldGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // DESKTOP WALLET & ACTIVITY VIEW (Image 2)
  // =========================================================================
  Widget _buildDesktopWalletView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Subtitle + Export CSV & Add Funds Buttons (Image 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Wallet & Activity",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Manage your billing and review AI consultation micropayments.",
                      style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),

              // Export CSV Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                label: const Text("Export CSV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF23322E)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 14),

              // Add Funds Button (Image 2)
              ElevatedButton.icon(
                onPressed: () => _showAddFundsDialog(),
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                label: const Text("Add Funds", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // 3 Top Summary Stat Cards (Image 2)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildDesktopAvailableBalanceCard()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDesktopSpendCard()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDesktopQueriesCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildDesktopAvailableBalanceCard(),
                        const SizedBox(height: 16),
                        _buildDesktopSpendCard(),
                        const SizedBox(height: 16),
                        _buildDesktopQueriesCard(),
                      ],
                    );
            },
          ),
          const SizedBox(height: 36),

          // Recent Activity Table (Image 2)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF131D1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF23322E), width: 1),
            ),
            child: Column(
              children: [
                // Table Header Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Text(
                        "Recent Activity",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF9CA3AF), size: 16),
                        label: const Text("Filter", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF23322E)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF23322E)),

                // Columns Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: const Color(0xFF0C1412),
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text("DATE / TIME", style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                      Expanded(flex: 5, child: Text("DESCRIPTION & QUERY TYPE", style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                      Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text("AMOUNT", style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF23322E)),

                // Sample Activity Rows (Image 2)
                _buildDesktopActivityRow("Oct 24, 2026\n14:32 PST", "Contract Review: NDA standard terms", "Deep Analysis Model • 450 tokens", -0.45, Icons.description_outlined),
                _buildDesktopActivityRow("Oct 24, 2026\n10:15 PST", "Quick Citation: California Labor Code § 2802", "Fast Search Model • 120 tokens", -0.08, Icons.find_in_page_outlined),
                _buildDesktopActivityRow("Oct 23, 2026\n09:00 PST", "Auto-Reload (Visa ending in 4242)", "Wallet Top-up", 50.00, Icons.account_balance_wallet_outlined, isPositive: true),
                _buildDesktopActivityRow("Oct 22, 2026\n16:45 PST", "Precedent Search: Tech IP Assignment", "Deep Analysis Model • 890 tokens", -0.92, Icons.gavel_outlined),

                const Divider(height: 1, color: Color(0xFF23322E)),

                // Table Pagination Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chevron_left_rounded, color: Color(0xFF9CA3AF), size: 20),
                      SizedBox(width: 16),
                      Text("Page 1 of 12", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                      SizedBox(width: 16),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAvailableBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF23322E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("AVAILABLE BALANCE", style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              Icon(Icons.account_balance_wallet_outlined, color: AppTheme.emeraldGreen, size: 24),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "\$${widget.currentBalance.toStringAsFixed(2)} USD",
            style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 36, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.sync_rounded, color: AppTheme.emeraldGreen, size: 14),
              SizedBox(width: 6),
              Text("Auto-reload enabled", style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSpendCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF23322E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("THIS MONTH'S SPEND", style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              children: [
                TextSpan(text: "\$57.20"),
                TextSpan(text: " / \$100 limit", style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.57,
              backgroundColor: const Color(0xFF1E2C29),
              color: AppTheme.emeraldGreen,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          const Text("57% of soft limit", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDesktopQueriesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF23322E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TOTAL QUERIES (30D)", style: TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          const Text("342", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF9CA3AF), size: 14),
              SizedBox(width: 6),
              Text("Avg. \$0.16 per query", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActivityRow(
    String dateTime,
    String title,
    String subtitle,
    double amount,
    IconData icon, {
    bool isPositive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2C29), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateTime,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.3),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFF142C23) : const Color(0xFF1C2A26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: isPositive ? AppTheme.emeraldGreen : const Color(0xFF9CA3AF), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${isPositive ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}",
                style: TextStyle(
                  color: isPositive ? AppTheme.emeraldGreen : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
