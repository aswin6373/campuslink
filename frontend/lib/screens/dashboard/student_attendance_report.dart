import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';

class StudentAttendanceReport extends StatefulWidget {
  final String studentId;

  const StudentAttendanceReport({
    super.key,
    required this.studentId,
  });

  @override
  _StudentAttendanceReportState createState() => _StudentAttendanceReportState();
}

class _StudentAttendanceReportState extends State<StudentAttendanceReport> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _calendarScrollController = ScrollController();
  Map<String, dynamic> _monthlyStats = {};
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      setState(() => _isLoading = true);
      final data = await ApiClient.get('/api/attendance',
          query: {'date': formattedDate, 'student_id': widget.studentId});

      if (!mounted) return;
      setState(() {
          // Filter records for the current student only
          _attendanceRecords = List<Map<String, dynamic>>.from(data["records"] ?? [])
              .toList();

          // Ensure all required fields have default values
          _attendanceRecords = _attendanceRecords.map((record) {
            return {
              ...record,
              'username': record['username'] ?? 'Unknown',
              'status': record['status'] ?? 'not marked',
              'timestamp': record['timestamp'] ?? '',
              'date': record['date'] ?? formattedDate,
            };
          }).toList();

          // Calculate summary
          int present = 0, late = 0, absent = 0;
          for (var record in _attendanceRecords) {
            switch(record['status']) {
              case 'present': present++; break;
              case 'late': late++; break;
              case 'absent': absent++; break;
            }
          }
          
          final total = present + late + absent;
          
          _attendanceSummary = {
            "total": total,
            "present": {
              "count": present,
              "percentage": total > 0 ? ((present / total) * 100).round() : 0
            },
            "late": {
              "count": late,
              "percentage": total > 0 ? ((late / total) * 100).round() : 0
            },
            "absent": {
              "count": absent,
              "percentage": total > 0 ? ((absent / total) * 100).round() : 0
            }
          };

          // Update monthly stats
          _monthlyStats = {
            "total_days": total,
            "present_days": present,
            "late_days": late,
            "absent_days": absent,
          };

          _isLoading = false;
        });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _attendanceRecords = [];
        _attendanceSummary = {
          "total": 0,
          "present": {"count": 0, "percentage": 0},
          "late": {"count": 0, "percentage": 0},
          "absent": {"count": 0, "percentage": 0}
        };
        _monthlyStats = {
          "total_days": 0,
          "present_days": 0,
          "late_days": 0,
          "absent_days": 0,
        };
      });
    }
  }

  Map<String, dynamic> _attendanceSummary = {
    "total": 0,
    "present": {"count": 0, "percentage": 0},
    "late": {"count": 0, "percentage": 0},
    "absent": {"count": 0, "percentage": 0}
  };

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
          'My Attendance',
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildStudentView(theme),
    );
  }

  Widget _buildStudentView(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: fetchAttendanceData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildDateScroller(theme),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_attendanceRecords.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No attendance records found"),
                ),
              )
            else
              Column(
                children: [
                  _buildCurrentStatusCard(theme),
                  _buildAttendanceStatsCard(theme),
                  _buildMonthlyOverview(theme),
                  _buildRecentAttendanceList(theme),
                ],
              ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Widget _buildCurrentStatusCard(ThemeData theme) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Map<String, dynamic> studentData = {
      "status": "not marked",
      "timestamp": null,
    };
    for (final record in _attendanceRecords) {
      final ts = _parseTimestamp(record['timestamp']?.toString());
      if (ts != null && DateFormat('yyyy-MM-dd').format(ts) == today) {
        studentData = record;
        break;
      }
    }

    final statusColor = {
      'present': Colors.green,
      'late': Colors.orange,
      'absent': Colors.red,
      'not marked': Colors.grey,
    }[studentData['status']] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Today\'s Attendance',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (studentData['status'] ?? 'not marked').toString().toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (studentData['timestamp'] != null &&
                _parseTimestamp(studentData['timestamp'].toString()) != null) ...[
              const SizedBox(height: 8),
              Text(
                'Time: ${DateFormat('hh:mm a').format(_parseTimestamp(studentData['timestamp'].toString())!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatsCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Present', _attendanceSummary["present"]["count"].toString(), Colors.green, Icons.check_circle),
                _buildStatItem('Late', _attendanceSummary["late"]["count"].toString(), Colors.orange, Icons.access_time),
                _buildStatItem('Absent', _attendanceSummary["absent"]["count"].toString(), Colors.red, Icons.cancel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAttendanceList(ThemeData theme) {
    final sortedRecords = List<Map<String, dynamic>>.from(_attendanceRecords)
      ..sort((a, b) {
        final aTs = _parseTimestamp(a['timestamp']?.toString());
        final bTs = _parseTimestamp(b['timestamp']?.toString());
        return (bTs ?? DateTime(1970)).compareTo(aTs ?? DateTime(1970));
      });

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recent Attendance',
              style: theme.textTheme.titleMedium,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedRecords.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final record = sortedRecords[index];
              final statusColor = {
                'present': Colors.green,
                'late': Colors.orange,
                'absent': Colors.red,
              }[record['status']] ?? Colors.grey;

              return ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: statusColor,
                ),
                title: Text(
                  _parseTimestamp(record['timestamp']?.toString()) != null
                      ? DateFormat('EEEE, MMMM d').format(
                          _parseTimestamp(record['timestamp'].toString())!)
                      : 'Date unavailable',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (record['status'] ?? 'not marked').toString().toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateScroller(ThemeData theme) {
    final now = DateTime.now();
    final dates = List.generate(
      180,
      (i) => now.subtract(Duration(days: 90)).add(Duration(days: i)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_calendarScrollController.hasClients && 
          _calendarScrollController.position.pixels == 0) {
        _calendarScrollController.jumpTo(
          _calendarScrollController.position.maxScrollExtent / 2,
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    fetchAttendanceData(); // Re-fetch data for the new date
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
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

  Widget _buildMonthlyOverview(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Overview',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewItem('Total Days', _monthlyStats['total_days']?.toString() ?? '0', theme.colorScheme.primary),
                _buildOverviewItem('Present', _monthlyStats['present_days']?.toString() ?? '0', Colors.green),
                _buildOverviewItem('Late', _monthlyStats['late_days']?.toString() ?? '0', Colors.orange),
                _buildOverviewItem('Absent', _monthlyStats['absent_days']?.toString() ?? '0', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}