import 'package:campuslink/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:campuslink/data/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventForm extends StatefulWidget {
  final String? eventId; // Optional - if provided, we're editing an existing event

  const EventForm({super.key, this.eventId});

  @override
  _EventFormState createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Basic Details
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Location
  final _locationController = TextEditingController();
  final _locationDetailController = TextEditingController();

  // Schedule and Coordinators
  List<Map<String, String>> schedule = [];
  List<Map<String, String>> coordinators = [];

  // API URL - Change this to match your XAMPP setup
  final String apiUrl = '${Config.baseUrl}/clink/api/saveEvents.php';

  String institution = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
    if (widget.eventId != null) {
      _loadEventData();
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      institution = prefs.getString('institution') ?? '';
    });
  }

Future<void> _loadEventData() async {
  if (!mounted) return;
  
  // Wait for institution to be loaded if it's empty
  if (institution.isEmpty) {
    await loadUserData();
  }
  
  try {
    final url = Uri.parse('$apiUrl?id=${widget.eventId}&institution=$institution');
    final response = await http.get(url);
    
    if (!mounted) return;
    
    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      final data = responseJson['data'];
      
      setState(() {
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _locationController.text = data['location'] ?? '';
        _locationDetailController.text = data['location_detail'] ?? '';
        
        if (data['event_date'] != null) {
          _selectedDate = DateTime.parse(data['event_date']);
          _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
        }
        
        // Parse schedule list
        final scheduleList = data['schedule'] as List<dynamic>?;
        schedule = scheduleList?.map((s) => {
          'time': s['time']?.toString() ?? '',
          'activity': s['activity']?.toString() ?? ''
        }).toList() ?? [];
        
        // Parse coordinators list
        final coordinatorsList = data['coordinators'] as List<dynamic>?;
        coordinators = coordinatorsList?.map((c) => {
          'name': c['name']?.toString() ?? '',
          'role': c['role']?.toString() ?? '',
          'email': c['email']?.toString() ?? ''
        }).toList() ?? [];
      });
    } else {
      throw Exception('Failed to load event');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading event: $e')),
      );
    }
  }
}


   Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (institution.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Institution not found')),
      );
      return;
    }

    final eventData = {
      'title': _titleController.text,
      'event_date': DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(_combineDateTime(_selectedDate, _selectedTime)),
      'description': _descriptionController.text,
      'location': _locationController.text,
      'location_detail': _locationDetailController.text,
      'schedule': schedule,
      'coordinators': coordinators,
      'institution': institution, // Add institution to the payload
    };

    try {
      final Uri uri = Uri.parse(apiUrl);
      final response = widget.eventId == null
    ? await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eventData),
      )
    : await http.put(
        Uri.parse('$apiUrl?id=${widget.eventId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(eventData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        UserDashboard.eventUpdateController.add(null);
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to save event');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event: $e')),
      );
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

 Widget _buildBasicDetailsForm() {
  return Column(
    children: [
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Event Title',
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter event title' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter event description' : null,
      ),
      const SizedBox(height: 16),
      ListTile(
        title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime(2100, 12, 31),
          );
          if (picked != null) {
            setState(() => _selectedDate = picked);
          }
        },
      ),
      ListTile(
        title: Text('Time: ${_selectedTime.format(context)}'),
        trailing: const Icon(Icons.access_time),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _selectedTime,
          );
          if (picked != null) {
            setState(() => _selectedTime = picked);
          }
        },
      ),
    ],
  );
}

  Widget _buildLocationForm() {
    return Column(
      children: [
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter location' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationDetailController,
          decoration: const InputDecoration(
            labelText: 'Location Details',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter location details' : null,
        ),
      ],
    );
  }

  Widget _buildScheduleForm() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(schedule[index]['activity'] ?? ''),
                subtitle: Text(schedule[index]['time'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      schedule.removeAt(index);
                    });
                  },
                ),
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => _showAddScheduleDialog(),
          child: const Text('Add Schedule Item'),
        ),
      ],
    );
  }

  Widget _buildCoordinatorsForm() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coordinators.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(coordinators[index]['name'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coordinators[index]['role'] ?? ''),
                    Text(coordinators[index]['email'] ?? ''),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      coordinators.removeAt(index);
                    });
                  },
                ),
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => _showAddCoordinatorDialog(),
          child: const Text('Add Coordinator'),
        ),
      ],
    );
  }

  Future<void> _showAddScheduleDialog() async {
    final timeController = TextEditingController();
    final activityController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Schedule Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'Time'),
            ),
            TextFormField(
              controller: activityController,
              decoration: const InputDecoration(labelText: 'Activity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                schedule.add({
                  'time': timeController.text,
                  'activity': activityController.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCoordinatorDialog() async {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Coordinator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                coordinators.add({
                  'name': nameController.text,
                  'role': roleController.text,
                  'email': emailController.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _saveEvent();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              title: const Text('Basic Details'),
              content: _buildBasicDetailsForm(),
              isActive: _currentStep == 0,
            ),
            Step(
              title: const Text('Location'),
              content: _buildLocationForm(),
              isActive: _currentStep == 1,
            ),
            Step(
              title: const Text('Schedule'),
              content: _buildScheduleForm(),
              isActive: _currentStep == 2,
            ),
            Step(
              title: const Text('Coordinators'),
              content: _buildCoordinatorsForm(),
              isActive: _currentStep == 3,
            ),
          ],
        ),
      ),
    );
  }
}