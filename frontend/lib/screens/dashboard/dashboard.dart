import 'package:campuslink/app_theme.dart';
import 'package:campuslink/screens/dashboard/attendance_report.dart';
import 'package:campuslink/screens/dashboard/approvals_screen.dart';
import 'package:campuslink/screens/dashboard/event/event_detail_screen.dart';
import 'package:campuslink/screens/dashboard/event/event_list_screen.dart';
import 'package:campuslink/screens/dashboard/chatbot_manage.dart';
import 'package:campuslink/screens/dashboard/student_management_screen.dart';
import 'package:campuslink/screens/dashboard/teacher_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/profile.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:campuslink/services/api_client.dart';
import 'package:campuslink/screens/dashboard/student_attendance_report.dart';

class UserDashboard extends StatefulWidget {
  final String userId;
  final String userRole;

  const UserDashboard({
    super.key,
    required this.userId,
    required this.userRole,
  });

  static final StreamController<void> eventUpdateController =
      StreamController<void>.broadcast();

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String eventTitle = 'Loading...';
  String institution = '';
  String displayName = '';
  String? eventDate;
  late StreamSubscription eventUpdateSubscription;
  Map<String, dynamic> upcomingEvent = {};

  int _totalStudents = 0;
  int _totalTeachers = 0;

  Color get _roleColor {
    switch (widget.userRole.toLowerCase()) {
      case 'admin':
        return AppTheme.adminColor;
      case 'teacher':
        return AppTheme.teacherColor;
      case 'student':
        return AppTheme.studentColor;
      default:
        return AppTheme.guestColor;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    eventUpdateSubscription = UserDashboard.eventUpdateController.stream.listen((_) {
      fetchUpcomingEvent();
    });
  }

  @override
  void dispose() {
    eventUpdateSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await loadUserData();
    fetchUpcomingEvent();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      final counts = await ApiClient.get('/api/counts');
      if (!mounted) return;
      setState(() {
        _totalStudents = counts['total_students'] ?? 0;
        _totalTeachers = counts['total_teachers'] ?? 0;
      });
    } catch (e) {
      // Counts are non-critical; ignore fetch failures.
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      institution = prefs.getString('institution') ?? '';
      displayName =
          prefs.getString('username') ?? prefs.getString('userId') ?? '';
    });
  }

  Future<void> fetchUpcomingEvent() async {
    try {
      final responseData = await ApiClient.get('/api/events/upcoming');

      if (!mounted) return;

      final data = responseData['data'];
      setState(() {
        upcomingEvent = data is Map ? Map<String, dynamic>.from(data) : {};
        eventTitle = data is Map && data['title'] != null
            ? data['title'].toString()
            : 'No upcoming events';
        eventDate = data is Map ? data['event_date']?.toString() : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        eventTitle = 'No upcoming events';
        eventDate = null;
        upcomingEvent = {};
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppTheme.brandIndigo,
        onRefresh: _initializeData,
        child: CustomScrollView(
          slivers: [
            // ---------- Gradient header ----------
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 16, 20, 26),
                decoration: const BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppTheme.radiusXL)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting() + ',',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName.isNotEmpty
                                    ? displayName
                                    : widget.userId,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Role chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _roleColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.userRole,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _HeaderButton(
                          icon: Icons.account_circle_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfilePage()),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Stats row
                  if (widget.userRole.toLowerCase() == 'admin' ||
                      widget.userRole.toLowerCase() == 'teacher')
                    Row(
                      children: [
                        _StatChip(
                            label: 'Students',
                            value: _totalStudents.toString(),
                            icon: Icons.school_rounded),
                        const SizedBox(width: 12),
                        if (widget.userRole.toLowerCase() == 'admin') ...[
                          _StatChip(
                              label: 'Teachers',
                              value: _totalTeachers.toString(),
                              icon: Icons.person_rounded),
                          const SizedBox(width: 12),
                        ],
                        _StatChip(
                            label: 'Institution',
                            value: institution.isNotEmpty ? institution : '—',
                            icon: Icons.business_rounded,
                            isText: true),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ---------- Body ----------
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Upcoming event card
                _EventCard(
                  title: eventTitle,
                  date: eventDate,
                  hasEvent: eventTitle != 'No upcoming events' &&
                      upcomingEvent.isNotEmpty,
                  onViewDetails: widget.userRole.toLowerCase() != 'guest'
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(
                                eventId:
                                    upcomingEvent['id']?.toString() ?? '1',
                                onEventUpdated: fetchUpcomingEvent,
                              ),
                            ),
                          )
                      : null,
                ),
                const SizedBox(height: 24),

                // Quick actions
                if (widget.userRole.toLowerCase() != 'guest') ...[
                  Text('Quick Actions', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: wide ? 4 : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: wide ? 2.4 : 1.35,
                    children: _getQuickActionsByRole(),
                  ),
                 ],
                 const SizedBox(height: 24),
               ]),
             ),
           ),
         ],
       ),
     ),
   );
  }

  List<Widget> _getQuickActionsByRole() {
    final actions = <Widget>[];
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final roleActions = {
      'admin': [
        ['Approvals', Icons.how_to_reg_rounded, AppTheme.infoColor,
          const ApprovalsScreen()],
        ['Manage Students', Icons.people_outline_rounded, AppTheme.adminColor,
          ManageStudentsScreen(userType: widget.userRole, userId: widget.userId)],
        ['Manage Teachers', Icons.person_rounded, AppTheme.teacherColor,
          ManageTeachersScreen(userType: widget.userRole, userId: widget.userId)],
        ['Attendance', Icons.fact_check_rounded, AppTheme.errorColor,
          AttendanceReport()],
        ['Manage Chatbot', Icons.smart_toy_rounded, AppTheme.warningColor,
          ChatbotManagementScreen(adminId: widget.userId)],
        ['Manage Events', Icons.event_note_rounded, AppTheme.successColor,
          EventListScreen()],
      ],
      'teacher': [
        ['Manage Students', Icons.people_outline_rounded, AppTheme.adminColor,
          ManageStudentsScreen(userType: widget.userRole, userId: widget.userId)],
        ['Attendance', Icons.fact_check_rounded, AppTheme.errorColor,
          AttendanceReport()],
        ['Manage Events', Icons.event_note_rounded, AppTheme.successColor,
          EventListScreen()],
      ],
      'student': [
        ['My Attendance', Icons.fact_check_rounded, AppTheme.errorColor,
          StudentAttendanceReport(studentId: widget.userId)],
      ],
    };

    final currentRoleActions =
        roleActions[widget.userRole.toLowerCase()] ?? [];

    for (var i = 0; i < currentRoleActions.length; i++) {
      final title = currentRoleActions[i][0] as String;
      final icon = currentRoleActions[i][1] as IconData;
      final color = currentRoleActions[i][2] as Color;
      final screen = currentRoleActions[i][3] as Widget;

      actions.add(
        _ActionCard(
          title: title,
          icon: icon,
          color: color,
          isDark: isDarkMode,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (60 * i).ms),
      );
    }

    return actions;
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 26),
        onPressed: onTap,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isText;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String? date;
  final bool hasEvent;
  final VoidCallback? onViewDetails;

  const _EventCard({
    required this.title,
    required this.date,
    required this.hasEvent,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardBox(theme, radius: AppTheme.radiusL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: const Icon(Icons.event_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Upcoming Event', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
          if (date != null && hasEvent) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 15,
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  _formatDate(date!),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (onViewDetails != null && hasEvent) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('View Details'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return DateFormat('EEE, MMM d · HH:mm').format(d);
    } catch (_) {
      return raw;
    }
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardBox(theme, radius: AppTheme.radiusL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
