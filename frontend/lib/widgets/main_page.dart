import 'package:campuslink/screens/dashboard/dashboard.dart';
import 'package:campuslink/screens/chatbot/chatbot.dart';
import 'package:campuslink/screens/chatroom/chatroom.dart';
import 'package:campuslink/screens/community_post/community_post.dart';
import 'package:flutter/material.dart';

class NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  const NavItem({
    required this.icon,
    required this.label,
    this.activeColor = const Color(0xFFBB86FC),
  });
}

class MainPage extends StatefulWidget {
  final String userType;
  final String userId;

  const MainPage({super.key, required this.userType, required this.userId});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  late List<NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  void _initializeNavigation() {
    final baseNavItems = <NavItem>[
      const NavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        activeColor: Color(0xFFBB86FC),
      ),
      const NavItem(
        icon: Icons.group_rounded,
        label: 'Community',
        activeColor: Color(0xFF03DAC6),
      ),
    ];

    switch (widget.userType) {
      case 'Guest':
        _pages = [
          UserDashboard(userRole: widget.userType, userId: widget.userId),
          CommunityPost(username: widget.userId),
          Chatbot(),
        ];
        _navItems = [
          ...baseNavItems,
          const NavItem(
            icon: Icons.smart_toy,
            label: 'Chatbot',
            activeColor: Color(0xFFCF6679),
          ),
        ];
        break;
      case 'Admin':
      case 'Student':
      case 'Teacher':
        _pages = [
          UserDashboard(userRole: widget.userType, userId: widget.userId),
          CommunityPost(username: widget.userId),
          Chatroom(),
          Chatbot(),
        ];
        _navItems = [
          ...baseNavItems,
          const NavItem(
            icon: Icons.chat_rounded,
            label: 'Chatroom',
            activeColor: Color(0xFF03DAC6),
          ),
          const NavItem(
            icon: Icons.smart_toy,
            label: 'Chatbot',
            activeColor: Color(0xFFCF6679),
          ),
        ];
        break;
      default:
        // Unknown role: fall back to the guest layout so the app never crashes.
        _pages = [
          UserDashboard(userRole: 'Guest', userId: widget.userId),
          CommunityPost(username: widget.userId),
          Chatbot(),
        ];
        _navItems = [
          ...baseNavItems,
          const NavItem(
            icon: Icons.smart_toy,
            label: 'Chatbot',
            activeColor: Color(0xFFCF6679),
          ),
        ];
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1F1F1F),
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: _navItems.map((item) {
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _currentIndex == _navItems.indexOf(item)
                        ? item.activeColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: _currentIndex == _navItems.indexOf(item)
                        ? item.activeColor
                        : Colors.grey[400],
                  ),
                ),
                label: item.label,
                backgroundColor: Colors.transparent,
              );
            }).toList(),
            selectedItemColor: _navItems[_currentIndex].activeColor,
            unselectedItemColor: Colors.grey[400],
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}