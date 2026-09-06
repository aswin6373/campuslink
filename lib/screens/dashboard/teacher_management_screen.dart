import 'package:campuslink/data/data_provider.dart';
import 'package:campuslink/models/teacher_and_student_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageTeachersScreen extends StatefulWidget {
  final String userType;
  final String userId;

  const ManageTeachersScreen({super.key, required this.userType, required this.userId});

  @override
  _ManageTeachersScreenState createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  @override
  void initState() {
    super.initState();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    dataProvider.loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().fetchTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Teachers',
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
                    onPressed: () => dataProvider.fetchTeachers(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dataProvider.teachers.length,
            itemBuilder: (context, index) {
              final teacher = dataProvider.teachers[index];
              return TeacherCard(
                teacher: teacher,
                userType: widget.userType,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTeacherDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTeacherDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final subjectController = TextEditingController();
    final qualificationController = TextEditingController();
    final experienceController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Teacher', style: theme.textTheme.headlineSmall),
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
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qualificationController,
                decoration: const InputDecoration(labelText: 'Qualification'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(labelText: 'Experience (Years)'),
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
            onPressed: () {
              final teacher = Teacher(
                id: 'TCH${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                username: usernameController.text,
                password: passwordController.text,
                subject: subjectController.text,
                qualification: qualificationController.text,
                experience: experienceController.text,
                contact: contactController.text,
                email: emailController.text,
              );
              context.read<DataProvider>().addTeacher(teacher);
              Navigator.pop(context);
              // Show success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('teacher added successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
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

class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final String userType;

  const TeacherCard({super.key, required this.teacher, required this.userType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          teacher.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          'Subject: ${teacher.subject} | Username: ${teacher.username}',
          style: theme.textTheme.bodyMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Username', teacher.username),
                _buildInfoRow(context, 'Subject', teacher.subject),
                _buildInfoRow(context, 'Qualification', teacher.qualification),
                _buildInfoRow(context, 'Experience', teacher.experience),
                _buildInfoRow(context, 'Contact', teacher.contact),
                _buildInfoRow(context, 'Email', teacher.email),
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
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: teacher.name);
    final usernameController = TextEditingController(text: teacher.username);
    final passwordController = TextEditingController(text: teacher.password);
    final subjectController = TextEditingController(text: teacher.subject);
    final qualificationController = TextEditingController(text: teacher.qualification);
    final experienceController = TextEditingController(text: teacher.experience);
    final contactController = TextEditingController(text: teacher.contact);
    final emailController = TextEditingController(text: teacher.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Teacher', style: theme.textTheme.headlineSmall),
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
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qualificationController,
                decoration: const InputDecoration(labelText: 'Qualification'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(labelText: 'Experience (Years)'),
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
            onPressed: () {
              final updatedTeacher = teacher.copyWith(
                name: nameController.text,
                username: usernameController.text,
                password: passwordController.text,
                subject: subjectController.text,
                qualification: qualificationController.text,
                experience: experienceController.text,
                contact: contactController.text,
                email: emailController.text,
              );
              context.read<DataProvider>().updateTeacher(updatedTeacher);
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
          'Delete Teacher',
          style: theme.textTheme.headlineSmall,
        ),
        content: Text(
          'Are you sure you want to delete ${teacher.name}?',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DataProvider>().deleteTeacher(teacher.id);
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
}