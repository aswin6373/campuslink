import 'package:campuslink/data/data_provider.dart';
import 'package:campuslink/models/teacher_and_student_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:campuslink/services/api_client.dart';

class ManageStudentsScreen extends StatefulWidget {
  final String userType;
  final String userId;

  const ManageStudentsScreen({super.key, required this.userType, required this.userId});

  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  @override
  void initState() {
    super.initState();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Students',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${dataProvider.error}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => dataProvider.fetchStudents(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dataProvider.students.length,
            itemBuilder: (context, index) {
              final student = dataProvider.students[index];
              return StudentCard(
                student: student,
                userType: widget.userType,
              );
            },
          );
        },
      ),
      floatingActionButton: widget.userType == 'Admin'
          ? FloatingActionButton(
              onPressed: () => _showAddStudentDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final gradeController = TextEditingController();
    final sectionController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Student', style: theme.textTheme.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: 'Grade/Year'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(labelText: 'Section'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final student = Student(
                id: 'STD${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                username: usernameController.text,
                password: passwordController.text,
                grade: gradeController.text,
                section: sectionController.text,
                contact: contactController.text,
                email: emailController.text,
                fingerprintEnrolled: 'NO', // Default value for new students
              );
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await context.read<DataProvider>().addStudent(student);
              if (!mounted) return;

              // Show success snackbar
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Student added successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );

              // Navigate back to the ManageStudentsScreen
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ManageStudentsScreen(
                    userType: widget.userType,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student student;
  final String userType;

  const StudentCard({super.key, required this.student, required this.userType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          student.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          'Grade: ${student.grade} | Username: ${student.username}',
          style: theme.textTheme.bodyMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Username', student.username),
                _buildInfoRow(context, 'Grade/Year', student.grade),
                _buildInfoRow(context, 'Password', student.password),
                _buildInfoRow(context, 'Section', student.section),
                _buildInfoRow(context, 'Contact', student.contact),
                _buildInfoRow(context, 'Email', student.email),
                _buildInfoRow(context, 'Fingerprint Enrolled', student.fingerprintEnrolled == 'YES' ? 'Yes' : 'No'), // Add this line
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditDialog(context),
                      icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                      label: Text('Edit', style: TextStyle(color: theme.colorScheme.primary)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showDeleteDialog(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Space between buttons
                ElevatedButton.icon(
                  onPressed: () => _showEnrollBiometryDialog(context),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Enroll for Biometry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: student.name);
    final usernameController = TextEditingController(text: student.username);
    final passwordController = TextEditingController(text: student.password);
    final gradeController = TextEditingController(text: student.grade);
    final sectionController = TextEditingController(text: student.section);
    final contactController = TextEditingController(text: student.contact);
    final emailController = TextEditingController(text: student.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: gradeController,
                decoration: InputDecoration(labelText: 'Grade/Year'),
              ),
              TextField(
                controller: sectionController,
                decoration: InputDecoration(labelText: 'Section'),
              ),
              TextField(
                controller: contactController,
                decoration: InputDecoration(labelText: 'Contact'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedStudent = student.copyWith(
                name: nameController.text,
                username: usernameController.text,
                password: passwordController.text,
                grade: gradeController.text,
                section: sectionController.text,
                contact: contactController.text,
                email: emailController.text,
              );
              context.read<DataProvider>().updateStudent(updatedStudent);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Student',
          style: theme.textTheme.headlineSmall,
        ),
        content: Text(
          'Are you sure you want to delete ${student.name}?',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DataProvider>().deleteStudent(student.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEnrollBiometryDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing during enrollment
      builder: (context) => FingerprintEnrollmentScreen(studentId: student.id),
    );
  }
}

class FingerprintEnrollmentScreen extends StatefulWidget {
  final String studentId;
  const FingerprintEnrollmentScreen({super.key, required this.studentId});

  @override
  _FingerprintEnrollmentScreenState createState() => _FingerprintEnrollmentScreenState();
}

class _FingerprintEnrollmentScreenState
    extends State<FingerprintEnrollmentScreen> {
  String enrollmentStatus = "Checking fingerprint device...";
  bool isEnrolling = false;
  bool deviceOnline = false;
  String? _commandId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 1) Check device online  2) queue enrollment  3) poll status
  Future<void> _startFlow() async {
    // Step 1: is the fingerprint device connected?
    try {
      final status = await ApiClient.get('/api/device/status');
      deviceOnline = status['connected'] == true;
    } catch (e) {
      deviceOnline = false;
    }

    if (!mounted) return;

    if (!deviceOnline) {
      setState(() {
        enrollmentStatus =
            "Fingerprint device not connected.\n\nPower on the scanner and make sure it is connected to the internet, then try again.";
      });
      return;
    }

    // Step 2: request enrollment via the backend
    try {
      final result = await ApiClient.post('/api/device/enroll',
          body: {'student_id': widget.studentId});
      _commandId = result['command_id']?.toString();
      setState(() {
        isEnrolling = true;
        enrollmentStatus = "Waiting for device... Place your finger on the scanner.";
      });
      _pollStatus();
    } on ApiException catch (e) {
      setState(() {
        enrollmentStatus = e.statusCode == 409
            ? "Fingerprint device not connected. Power it on and try again."
            : e.message;
      });
    } catch (e) {
      setState(() {
        enrollmentStatus = "Could not start enrollment. Check your connection.";
      });
    }
  }

  /// Step 3: poll the backend for device-reported progress
  void _pollStatus() {
    int attempts = 0;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (attempts >= 60) {
        // ~2 minutes timeout
        timer.cancel();
        if (!mounted) return;
        setState(() {
          enrollmentStatus = "Enrollment timed out. Please try again.";
          isEnrolling = false;
        });
        return;
      }
      attempts++;

      try {
        final result = await ApiClient.get('/api/device/enrollment-status',
            query: {'command_id': _commandId ?? ''});
        if (!mounted) return;
        setState(() {
          enrollmentStatus = _getStatusMessage(
              result['status']?.toString() ?? 'unknown');
          if (result['done'] == true) {
            isEnrolling = false;
            timer.cancel();
          }
        });
      } catch (e) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          enrollmentStatus = "Lost connection to the server.";
          isEnrolling = false;
        });
      }
    });
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'waiting_device':
        return "Waiting for the device to pick up the command...";
      case 'place_finger':
        return "Place your finger on the scanner...";
      case 'remove_finger':
        return "Remove your finger.";
      case 'place_finger_again':
        return "Place your finger on the scanner again...";
      case 'success':
        return "Enrollment successful!";
      case 'failed':
        return "Enrollment failed. Please try again.";
      default:
        return "Enrollment in progress...";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Fingerprint Enrollment")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 100,
              color: deviceOnline
                  ? (isEnrolling ? Colors.orange : theme.colorScheme.primary)
                  : theme.colorScheme.error,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                enrollmentStatus,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.pop(context);
              },
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
