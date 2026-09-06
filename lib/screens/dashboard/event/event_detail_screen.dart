import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuslink/data/config.dart';


class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final VoidCallback? onEventUpdated;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.onEventUpdated,
  });

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic> eventDetails = {};
  List<dynamic> schedules = [];
  List<dynamic> coordinators = [];
  bool isLoading = true;
  String? institution;
  String errorMessage = '';
  bool noEventFound = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadInstitution();
    if (mounted) {
      fetchEventDetails();
    }
  }

  Future<void> loadInstitution() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        institution = prefs.getString('institution');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error loading institution data';
      });
    }
  }

  Future<void> fetchEventDetails() async {
    if (institution == null || institution!.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Institution not found. Please log in again.';
      });
      _showErrorSnackBar('Institution not found. Please log in again.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/clink/api/get_event_details.php?id=${widget.eventId}&institution=$institution')
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (!responseData['success']) {
          if (responseData['message'].toString().toLowerCase().contains('not found')) {
            setState(() {
              isLoading = false;
              noEventFound = true;
            });
            return;
          }
          throw Exception(responseData['message']);
        }

        final data = responseData['data'] ?? {};
        setState(() {
          eventDetails = data['event'] ?? {};
          schedules = data['schedules'] ?? [];
          coordinators = data['coordinators'] ?? [];
          isLoading = false;
          errorMessage = '';
          noEventFound = false;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading event details';
      });
      _showErrorSnackBar('Error loading event details: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
        ),
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (noEventFound) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Event Found',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The event you\'re looking for doesn\'t exist or has been removed.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                eventDetails['title'] ?? 'Event Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.primary.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Date & Time',
                    content: eventDetails['event_date'] != null
                        ? DateFormat('MMMM dd, yyyy - HH:mm')
                            .format(DateTime.parse(eventDetails['event_date']))
                        : 'Date not available',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on,
                    title: 'Location',
                    content: eventDetails['location'] ?? 'TBA',
                    subtitle: eventDetails['location_detail'],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    icon: Icons.description,
                    title: 'Description',
                    content: eventDetails['description'] ?? 'No description available',
                  ),
                  const SizedBox(height: 24),
                  _buildScheduleSection(context),
                  const SizedBox(height: 24),
                  _buildCoordinatorsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        if (schedules.isEmpty)
          Card(
            elevation: theme.cardTheme.elevation,
            shape: theme.cardTheme.shape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No schedule available',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return Card(
                elevation: theme.cardTheme.elevation,
                shape: theme.cardTheme.shape,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
                  title: Text(schedule['activity'], style: theme.textTheme.titleLarge),
                  subtitle: Text(schedule['time'], style: theme.textTheme.bodyMedium),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCoordinatorsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Coordinators',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        if (coordinators.isEmpty)
          Card(
            elevation: theme.cardTheme.elevation,
            shape: theme.cardTheme.shape,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No coordinators assigned',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: coordinators.length,
            itemBuilder: (context, index) {
              final coordinator = coordinators[index];
              return Card(
                elevation: theme.cardTheme.elevation,
                shape: theme.cardTheme.shape,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      (coordinator['name']?.toString() ?? '?').isNotEmpty
                          ? coordinator['name'][0].toUpperCase()
                          : '?',
                      style: TextStyle(color: theme.colorScheme.onPrimary),
                    ),
                  ),
                  title: Text(
                    coordinator['name'],
                    style: theme.textTheme.titleLarge,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coordinator['role'],
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        coordinator['email'],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
      ],
    );
  }
}

  