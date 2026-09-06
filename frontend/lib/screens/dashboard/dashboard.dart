import 'package:campuslink/screens/dashboard/attendance_report.dart';
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

  static final StreamController<void> eventUpdateController = StreamController<void>.broadcast();
  
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String eventTitle = 'Loading...';
  String institution = '';
  String displayName = '';
  String? eventDate;
  late StreamSubscription eventUpdateSubscription;
  Map<String, dynamic> upcomingEvent = {};

  // Add state variables for total students and teachers
  int _totalStudents = 0;
  int _totalTeachers = 0;

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
      // Prefer the friendly username; fall back to the raw id.
      displayName =
          prefs.getString('username') ?? prefs.getString('userId') ?? '';
    });
  }

  Future<void> fetchUpcomingEvent() async {
    try {
      // Get institution from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final institution = prefs.getString('institution');

      if (institution == null || institution.isEmpty) {
        throw Exception('Institution not found. Please log in again.');
      }

      final responseData =
          await ApiClient.get('/api/events/upcoming');

      if (!mounted) return;

      final data = responseData['data'] ?? {};
      setState(() {
        upcomingEvent = data;
        eventTitle = data['title'] ?? 'No upcoming events';
        eventDate = data['event_date'];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildModernDrawer(context),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          '${widget.userRole} Dashboard',
          style: theme.appBarTheme.titleTextStyle,
        ).animate().fadeIn().slideX(),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => ProfilePage())
            ),
          ).animate().fadeIn().scale(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section (without background)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back,',
                    style: theme.textTheme.bodyMedium,
                  ).animate().fadeIn().slideX(),
                  const SizedBox(height: 8),
                  Text(
                    displayName.isNotEmpty ? displayName : widget.userId,
                    style: theme.textTheme.headlineLarge,
                  ).animate().fadeIn().slideX(delay: 200.ms),
                ],
              ),
            ),

            // Stats Section
            if (widget.userRole.toLowerCase() == 'admin' || 
                widget.userRole.toLowerCase() == 'teacher')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedStatCard(
                        'Total Students',
                        _totalStudents.toString(),
                        Icons.school,
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (widget.userRole.toLowerCase() == 'admin')
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'Total Teachers',
                          _totalTeachers.toString(),
                          Icons.person,
                          theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),

            // Events Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGlassEventCard(context),
            ),

            // Quick Actions Section
            if (widget.userRole.toLowerCase() != 'guest')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.headlineMedium,
                    ).animate().fadeIn().slideX(),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: _getQuickActionsByRole(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
              // Use the AppBar's background color from the theme
              color: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
            ),
              child: Center(
                child: Text(
                  "${widget.userRole} Menu",
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', () => Navigator.pop(context)),
            _buildDrawerItem(Icons.info, 'About', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title, style: theme.textTheme.bodyLarge),
      onTap: onTap,
    ).animate().fadeIn().slideX();
  }

  // Update the _buildAnimatedStatCard method
Widget _buildAnimatedStatCard(String title, String value, IconData icon, Color color) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;
  
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDarkMode ? theme.cardColor : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: isDarkMode 
          ? null 
          : Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: isDarkMode 
              ? color.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          blurRadius: isDarkMode ? 15 : 10,
          offset: const Offset(0, 4),
          spreadRadius: isDarkMode ? 0 : 0,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 30),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 15),
        Text(
          value,
          style: theme.textTheme.headlineMedium,
        ).animate().slideX().fadeIn(),
        const SizedBox(height: 5),
        Text(
          title,
          style: theme.textTheme.bodyMedium,
        ).animate().slideX(delay: 200.ms).fadeIn(),
      ],
    ),
  ).animate().fadeIn().scale();
}

// Update the _buildGlassEventCard method
Widget _buildGlassEventCard(BuildContext context) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;
  
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDarkMode ? theme.cardColor : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: isDarkMode 
          ? null 
          : Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: isDarkMode 
              ? Colors.black.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          blurRadius: isDarkMode ? 15 : 10,
          offset: const Offset(0, 4),
          spreadRadius: isDarkMode ? 0 : 0,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event,
              color: theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Text(
              'Upcoming Event',
              style: theme.textTheme.titleLarge,
            ).animate().fadeIn().slideX(),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          eventTitle,
          style: theme.textTheme.headlineMedium,
        ).animate().fadeIn().slideX(delay: 200.ms),
        const SizedBox(height: 12),
        if (eventDate != null)
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(eventDate!)),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ).animate().fadeIn().slideX(delay: 400.ms),
        if (widget.userRole.toLowerCase() != 'guest')
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(
                    eventId: upcomingEvent['id']?.toString() ?? '1',
                    onEventUpdated: fetchUpcomingEvent,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('View Details'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ).animate().fadeIn().scale(delay: 600.ms),
          ),
      ],
    ),
  ).animate().fadeIn().scale();
}

Widget _buildAnimatedActionCard(String title, IconData icon, Color color, Widget screen) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.cardColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.transparent : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? color.withOpacity(0.2)
                : Colors.grey[300]!,
              blurRadius: isDarkMode ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? color.withOpacity(0.1)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: color,
                size: 30,
              ),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ).animate().fadeIn().slideX(delay: 200.ms),
          ],
        ),
      ),
    ).animate().fadeIn().scale(delay: 400.ms);
  }

  List<Widget> _getQuickActionsByRole() {
  final actions = <Widget>[];
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;

  final roleActions = {
    'admin': [
      ['Manage Students', Icons.people_outline, 
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF6C63FF), 
        ManageStudentsScreen(userType: widget.userRole, userId: widget.userId)],
      ['Manage Teachers', Icons.person, 
        isDarkMode ? theme.colorScheme.secondary : const Color(0xFF03DAC6), 
        ManageTeachersScreen(userType: widget.userRole, userId: widget.userId)],
      ['Attendance', Icons.check_circle_outline, 
        isDarkMode ? theme.colorScheme.error : const Color(0xFFFF6B6B), 
        AttendanceReport()], // ✅ No studentId here
      ['Manage Chatbot', Icons.smart_toy, 
        isDarkMode ? theme.colorScheme.tertiary : const Color(0xFFFFA62B), 
        ChatbotManagementScreen(adminId: widget.userId)],
      ['Manage Events', Icons.event_note, 
        isDarkMode ? theme.colorScheme.secondary : const Color(0xFF4CAF50), 
        EventListScreen()],
    ],
    'teacher': [
      ['Manage Students', Icons.people_outline, 
        isDarkMode ? theme.colorScheme.primary : const Color(0xFF6C63FF), 
        ManageStudentsScreen(userType: widget.userRole, userId: widget.userId)],
      ['Attendance', Icons.check_circle_outline, 
        isDarkMode ? theme.colorScheme.error : const Color(0xFFFF6B6B), 
        AttendanceReport()], // ✅ No studentId here
      ['Manage Events', Icons.event_note, 
        isDarkMode ? theme.colorScheme.secondary : const Color(0xFF4CAF50), 
        EventListScreen()],
    ],
    'student': [
      ['Attendance', Icons.check_circle_outline, 
        isDarkMode ? theme.colorScheme.error : const Color(0xFFFF6B6B), 
        StudentAttendanceReport(studentId: widget.userId)], // ✅ Students go to student view
    ],
  };

  final currentRoleActions = roleActions[widget.userRole.toLowerCase()] ?? [];

  for (var i = 0; i < currentRoleActions.length; i++) {
    final title = currentRoleActions[i][0] as String;
    final icon = currentRoleActions[i][1] as IconData;
    final color = currentRoleActions[i][2] as Color;
    final screen = currentRoleActions[i][3] as Widget;

    actions.add(_buildAnimatedActionCard(title, icon, color, screen));
  }

  return actions;
}

}