import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expert_ai/services/api_service.dart';
import 'package:expert_ai/theme/app_theme.dart';
import 'package:expert_ai/views/account_view.dart';
import 'package:expert_ai/views/chat_view.dart';
import 'package:expert_ai/views/history_view.dart';
import 'package:expert_ai/views/library_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentTabIndex = 0; // 0: Chat, 1: History, 2: Library, 3: Account/Settings
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
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    // Mobile Layout (< 900px)
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
        child: KeyedSubtree(
          key: ValueKey<int>(_currentTabIndex),
          child: pages[_currentTabIndex > 2 ? 2 : _currentTabIndex],
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

  // =========================================================================
  // DESKTOP LAYOUT (Image 1, 2, 3, 4 Sidebar & Header)
  // =========================================================================
  Widget _buildDesktopLayout() {
    final desktopPages = [
      ChatView(onBalanceUpdated: _onBalanceUpdated),
      HistoryView(onNewChatPressed: () => setState(() => _currentTabIndex = 0)),
      LibraryView(
        onConsultAgent: (agentId, prompt) {
          setState(() => _currentTabIndex = 0);
        },
      ),
      AccountView(
        currentBalance: _walletBalance,
        onBalanceUpdated: _onBalanceUpdated,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Row(
        children: [
          // Left Sidebar Navigation (Image 1, 2, 3, 4)
          Container(
            width: 250,
            color: const Color(0xFF0C1412),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Brand Logo (Image 1: AskExpert)
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppTheme.emeraldGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "AskExpert",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "AI Specialist Consultant",
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // New Chat Action Button (Image 1, 2, 3, 4)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _currentTabIndex = 0),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text("New Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF384955),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sidebar Navigation Links
                _buildDesktopSidebarItem(0, Icons.chat_bubble_outline_rounded, "New Chat"),
                _buildDesktopSidebarItem(1, Icons.history_rounded, "History"),
                _buildDesktopSidebarItem(2, Icons.menu_book_rounded, "Library"),
                _buildDesktopSidebarItem(3, Icons.settings_outlined, "Settings"),
                _buildDesktopSidebarItem(4, Icons.help_outline_rounded, "Help"),

                const Spacer(),

                // Upgrade to Pro Button (Image 1, 2, 3, 4)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.verified_rounded, color: Colors.black, size: 16),
                    label: const Text("Upgrade to Pro", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign Out Button
                InkWell(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.logout_rounded, color: Color(0xFF9CA3AF), size: 18),
                        SizedBox(width: 12),
                        Text("Sign Out", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Center Content Canvas
          Expanded(
            child: Column(
              children: [
                // Top Desktop Header (Image 1, 2, 3, 4)
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppTheme.darkBackground,
                    border: Border(bottom: BorderSide(color: Color(0xFF1E2C29), width: 1)),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),

                      // Search Input Field
                      Container(
                        width: 320,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF23322E)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "Search case law, documents...",
                                  hintStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Wallet Balance Pill (Image 1, 2, 3, 4: Wallet: $142.50)
                      GestureDetector(
                        onTap: () => setState(() => _currentTabIndex = 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131D1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF23322E)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.emeraldGreen, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Wallet: \$${_walletBalance.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Notification Icon
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF9CA3AF), size: 20),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),

                      // User Avatar
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF263330),
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),

                // Main Page View Body
                Expanded(
                  child: IndexedStack(
                    index: _currentTabIndex > 3 ? 3 : _currentTabIndex,
                    children: desktopPages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebarItem(int index, IconData icon, String title) {
    final isSelected = _currentTabIndex == index;

    return InkWell(
      onTap: () {
        if (index <= 3) {
          setState(() => _currentTabIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2B3A46) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
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