import 'package:campuslink/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_form.dart';
import '../../../app_theme.dart';
import 'package:campuslink/services/api_client.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<dynamic> events = [];
  bool isLoading = true;

  @override
void initState() {
  super.initState();
  _loadEvents();
}

Future<void> _loadEvents() async {
  setState(() => isLoading = true);
  try {
    final responseData = await ApiClient.get('/api/events');

    if (!mounted) return;

    final List<dynamic> decodedData =
        (responseData['data'] as List<dynamic>?) ?? [];

    decodedData.sort((a, b) => (DateTime.tryParse(a['event_date'] ?? '') ??
            DateTime(1970))
        .compareTo(
            DateTime.tryParse(b['event_date'] ?? '') ?? DateTime(1970)));

    setState(() {
      events = decodedData;
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      events = [];
      isLoading = false;
    });
    _showErrorSnackBar('Error loading events: $e');
  }
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.successColor,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

Future<void> _deleteEvent(String id) async {
  try {
    await ApiClient.delete('/api/events/$id');
    if (!mounted) return;
    setState(() {
      events.removeWhere((event) => event['id'].toString() == id);
    });
    _showSuccessSnackBar('Event deleted successfully');
  } catch (e) {
    _showErrorSnackBar('Error deleting event: $e');
  }
}

  String _getEventTimeStatus(String eventDate) {
    final eventDateTime = DateTime.parse(eventDate);
    final now = DateTime.now();
    final difference = eventDateTime.difference(now);

    if (difference.isNegative) {
      return 'Past Event';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return 'This Week';
    } else if (difference.inDays < 30) {
      return 'This Month';
    } else {
      return 'Upcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text('Events', style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.appBarTheme.iconTheme?.color),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadEvents,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  color: theme.colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
  final event = events[index];
  final eventDate = DateTime.parse(event['event_date']);
  final timeStatus = _getEventTimeStatus(event['event_date']);
  final bool isPastEvent = eventDate.isBefore(DateTime.now());

  // Prevent negative index access
  if (index == 0 ||
      _getEventTimeStatus(events[index - 1]['event_date']) != timeStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index != 0) const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            timeStatus,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        _buildEventCard(event, isPastEvent, theme),
      ],
    );
  }
  return _buildEventCard(event, isPastEvent, theme);
},
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventForm()),
          );
          if (result == true) {
            _loadEvents();
            UserDashboard.eventUpdateController.add(null);
          }
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),

    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isPastEvent, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: theme.cardTheme.elevation ?? 2,
      shape: theme.cardTheme.shape,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventForm(
                eventId: event['id'].toString(),
              ),
            ),
          );
          if (result == true) {
            _loadEvents();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event['title'] ?? 'No Title',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isPastEvent 
                          ? theme.colorScheme.onSurface.withOpacity(0.6)
                          : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, 
                              size: 20,
                              color: theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text('Edit', 
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, 
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text('Delete',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventForm(eventId: event['id'].toString()),
                          ),
                        );
                        if (result == true) {
                          _loadEvents();
                          UserDashboard.eventUpdateController.add(null);
                        }
                      } else if (value == 'delete') {
                        _deleteEvent(event['id'].toString());
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm')
                        .format(DateTime.parse(event['event_date'])),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              if (event['location'] != null && event['location'].isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event['location'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}