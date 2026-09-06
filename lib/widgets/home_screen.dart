import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 32,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'CampusLink',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                'Choose your role',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.grey : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildRoleCard(
                      context: context,
                      title: 'Admin',
                      icon: Icons.admin_panel_settings_rounded,
                      color: Colors.purple,
                    ),
                    _buildRoleCard(
                      context: context,
                      title: 'Teacher',
                      icon: Icons.person_rounded,
                      color: Colors.green,
                    ),
                    _buildRoleCard(
                      context: context,
                      title: 'Student',
                      icon: Icons.school_rounded,
                      color: Colors.orange,
                    ),
                    _buildRoleCard(
                      context: context,
                      title: 'Guest',
                      icon: Icons.person_outline_rounded,
                      color: Colors.blue,
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

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? color.withOpacity(0.1) : color.withOpacity(0.05);
    final borderColor = isDark ? color.withOpacity(0.2) : color.withOpacity(0.1);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/${title.toLowerCase()}Login'),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}