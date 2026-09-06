import 'package:campuslink/app_theme.dart';
import 'package:campuslink/screens/dashboard/dashboard.dart';
import 'package:campuslink/screens/chatbot/chatbot.dart';
import 'package:campuslink/screens/chatroom/chatroom.dart';
import 'package:campuslink/screens/community_post/community_post.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  final String userType;
  final String userId;

  const MainPage({super.key, required this.userType, required this.userId});

  /// Normalizes any incoming role value ("admin", "ADMIN", "Admin") to
  /// "Admin" so role matching can never break due to case differences.
  static String normalizeRole(String role) {
    final r = role.trim().toLowerCase();
    if (r.isEmpty) return 'Guest';
    return r[0].toUpperCase() + r.substring(1);
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  late List<_NavTab> _tabs;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  void _initializeNavigation() {
    switch (widget.userType.toLowerCase()) {
      case 'guest':
        _pages = [
          UserDashboard(
              userRole: MainPage.normalizeRole(widget.userType),
              userId: widget.userId),
          CommunityPost(username: widget.userId),
          Chatbot(),
        ];
        _tabs = const [
          _NavTab(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          _NavTab(icon: Icons.diversity_3_rounded, label: 'Community'),
          _NavTab(icon: Icons.smart_toy_rounded, label: 'Assistant'),
        ];
        break;
      case 'admin':
      case 'student':
      case 'teacher':
        _pages = [
          UserDashboard(
              userRole: MainPage.normalizeRole(widget.userType),
              userId: widget.userId),
          CommunityPost(username: widget.userId),
          Chatroom(),
          Chatbot(),
        ];
        _tabs = const [
          _NavTab(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          _NavTab(icon: Icons.diversity_3_rounded, label: 'Community'),
          _NavTab(icon: Icons.forum_rounded, label: 'Chatroom'),
          _NavTab(icon: Icons.smart_toy_rounded, label: 'Assistant'),
        ];
        break;
      default:
        // Unknown role: fall back to the guest layout so the app never crashes.
        _pages = [
          UserDashboard(userRole: 'Guest', userId: widget.userId),
          CommunityPost(username: widget.userId),
          Chatbot(),
        ];
        _tabs = const [
          _NavTab(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          _NavTab(icon: Icons.diversity_3_rounded, label: 'Community'),
          _NavTab(icon: Icons.smart_toy_rounded, label: 'Assistant'),
        ];
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _currentIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selected ? AppTheme.brandGradient : null,
                        color: selected
                            ? null
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 22,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white38
                                    : Colors.black38),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white38
                                      : Colors.black38),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab({required this.icon, required this.label});
}
