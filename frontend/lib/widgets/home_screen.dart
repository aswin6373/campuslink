import 'package:flutter/material.dart';
import 'package:campuslink/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 700;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 480 : double.infinity),
              child: Column(
                children: [
                  // ---- Gradient hero header ----
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                        24, MediaQuery.of(context).padding.top + 40, 24, 48),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(AppTheme.radiusXL)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'CampusLink',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Connecting campus communities',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 14),
                            child: Text(
                              'Choose your role',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          _RoleCard(
                            context: context,
                            title: 'Admin',
                            subtitle: 'Manage your institution',
                            icon: Icons.admin_panel_settings_rounded,
                            color: AppTheme.adminColor,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _RoleCard(
                            context: context,
                            title: 'Teacher',
                            subtitle: 'Students, attendance & events',
                            icon: Icons.person_rounded,
                            color: AppTheme.teacherColor,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _RoleCard(
                            context: context,
                            title: 'Student',
                            subtitle: 'Attendance, events & more',
                            icon: Icons.school_rounded,
                            color: AppTheme.studentColor,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _RoleCard(
                            context: context,
                            title: 'Guest',
                            subtitle: 'Explore without an account',
                            icon: Icons.person_outline_rounded,
                            color: AppTheme.guestColor,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  const _RoleCard({
    required this.context,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        onTap: () => Navigator.pushNamed(context, '/${title.toLowerCase()}Login'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            boxShadow: AppTheme.softShadow(color, dark: isDark),
          ),
          child: Row(
            children: [
              // Icon bubble with the role gradient
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: AppTheme.softShadow(color, dark: isDark),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
