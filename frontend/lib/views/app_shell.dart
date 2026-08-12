import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';
import 'package:expert_ai/views/account_view.dart';
import 'package:expert_ai/views/chat_view.dart';
import 'package:expert_ai/views/history_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentTabIndex = 0;
  double _walletBalance = 4.82;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "demo_user_01";
    final bal = await ApiService.getWalletBalance(userId);
    if (mounted) {
      setState(() => _walletBalance = bal);
    }
  }

  void _onBalanceUpdated(double newBal) {
    setState(() => _walletBalance = newBal);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ChatView(onBalanceUpdated: _onBalanceUpdated),
      HistoryView(onNewChatPressed: () => setState(() => _currentTabIndex = 0)),
      AccountView(
        currentBalance: _walletBalance,
        onBalanceUpdated: _onBalanceUpdated,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Expert AI",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Top-Right Wallet Balance Pill Button with Scale Animation
          GestureDetector(
            onTap: () => setState(() => _currentTabIndex = 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF131D1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF23322E), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.emeraldGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "\$${_walletBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppTheme.emeraldGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: _buildAppDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentTabIndex),
          child: pages[_currentTabIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.darkBackground,
          border: Border(top: BorderSide(color: Color(0xFF1A2724), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "Chat"),
              _buildNavItem(1, Icons.history_rounded, Icons.history_toggle_off_rounded, "History"),
              _buildNavItem(2, Icons.account_circle_outlined, Icons.account_circle_rounded, "Account"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF192A25) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? AppTheme.emeraldGreen : const Color(0xFF9CA3AF),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.emeraldGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: AppTheme.darkBackground,
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF131D1A)),
            accountName: const Text(
              "Expert AI User",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.email ?? user?.phoneNumber ?? "demo_user_01",
              style: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppTheme.emeraldGreen,
              child: Icon(Icons.person, color: Colors.black, size: 30),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            title: const Text("New Chat", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTabIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Colors.white),
            title: const Text("History", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTabIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            title: const Text("Wallet & Account", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentTabIndex = 2);
            },
          ),
          const Divider(color: Color(0xFF23322E)),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}