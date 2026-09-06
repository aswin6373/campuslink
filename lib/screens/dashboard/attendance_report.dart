import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../widgets/profile.dart';
import '../../data/config.dart';

class AttendanceReport extends StatefulWidget {
  const AttendanceReport({super.key});

  @override
  _AttendanceReportState createState() => _AttendanceReportState();
}

class _AttendanceReportState extends State<AttendanceReport> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _calendarScrollController = ScrollController();
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  bool _hasScrolledToToday = false;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  int totalStudents = 0;
int present = 0;
int lateCount = 0;
int absent = 0;

Future<void> fetchAttendanceData() async {
  final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
  final url = Uri.parse("${Config.baseUrl}/clink/api/get_attendance.php?date=$formattedDate");

  try {
    if (mounted) setState(() => _isLoading = true);
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (!mounted) return;
      setState(() {
        _attendanceRecords = List<Map<String, dynamic>>.from(data["records"] ?? []);

        // Extracting values from API response summary
        totalStudents = int.tryParse(data['summary']['total']?.toString() ?? '0') ?? 0;
        present = data['summary']['present']['count'] ?? 0;
        lateCount = data['summary']['late']['count'] ?? 0;
        absent = data['summary']['absent']['count'] ?? 0;

        _isLoading = false;
      });
    } else {
      throw Exception("Failed to load attendance");
    }
  } catch (error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _attendanceRecords = [];
      totalStudents = 0;
      present = 0;
      lateCount = 0;
      absent = 0;
    });
  }
}


  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Student Attendance',
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
          ),
        ],
      ),
      body: _buildTeacherView(theme),
    );
  }

  Widget _buildTeacherView(ThemeData theme) {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateScroller(theme),
        _buildClassAttendanceSummary(theme),
        _buildStudentsList(theme), // ✅ Corrected typo
      ],
    ),
  );
}

    Widget _buildDateScroller(ThemeData theme) {
  final now = DateTime.now();
  final dates = List.generate(365, (i) => now.subtract(Duration(days: 182)).add(Duration(days: i)));

  // Find the index of today's date in the list
  int todayIndex = dates.indexWhere((date) => DateFormat('yyyy-MM-dd').format(date) ==
      DateFormat('yyyy-MM-dd').format(now));

  // Scroll to the current date when the screen opens (once)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_hasScrolledToToday && _calendarScrollController.hasClients && todayIndex > 0) {
      _hasScrolledToToday = true;
      _calendarScrollController.animateTo(
        todayIndex * 67.2, // Assuming each date tile is ~64px wide
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });

  return Container(
    height: 120,
    margin: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _calendarScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                  DateFormat('yyyy-MM-dd').format(_selectedDate);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _isLoading = true;
                  });
                  fetchAttendanceData();
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}



  Widget _buildClassAttendanceSummary(ThemeData theme) {
  int total = totalStudents > 0 ? totalStudents : (present + lateCount + absent);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAttendanceStatistic('Present', present, total, Colors.green, Icons.check_circle_outline),
        _buildAttendanceStatistic('Late', lateCount, total, Colors.orange, Icons.access_time),
        _buildAttendanceStatistic('Absent', absent, total, Colors.red, Icons.cancel_outlined),
      ],
    ),
  );
}



  Widget _buildAttendanceStatistic(String title, int count, int total, Color color, IconData icon) {
    double percentage = total > 0 ? (count / total) * 100 : 0;

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "${percentage.toStringAsFixed(1)}%",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Records for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _attendanceRecords.isEmpty
                  ? Center(child: Text("No attendance records for this date"))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = _attendanceRecords[index];
                        return ListTile(
                          title: Text("Student: ${record['username'] ?? 'Unknown'}"),
                          subtitle: Text("Timestamp: ${record['timestamp'] ?? 'N/A'}"),
                          trailing: Text(
                            (record['status'] ?? 'unknown').toString().toUpperCase(),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
