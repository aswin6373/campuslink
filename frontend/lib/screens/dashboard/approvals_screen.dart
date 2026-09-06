import 'package:campuslink/services/api_client.dart';
import 'package:flutter/material.dart';

/// Admin screen: approve or reject pending account registrations
/// (teachers / students / admins) for the admin's institution.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List<dynamic> _pending = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.get('/api/approvals');
      if (!mounted) return;
      setState(() {
        _pending = (result['data'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load pending registrations';
        _isLoading = false;
      });
    }
  }

  Future<void> _act(Map<String, dynamic> account, bool approve) async {
    final rawId = account['raw_id']?.toString() ?? '';
    final table = account['table']?.toString() ?? '';
    try {
      await ApiClient.post(
          '/api/approvals/$table/${Uri.encodeComponent(rawId)}/${approve ? 'approve' : 'reject'}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve
              ? '${account['name']} approved'
              : '${account['name']} rejected'),
        ),
      );
      _loadPending();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Action failed. Check your connection.'),
            backgroundColor: Colors.red),
      );
    }
  }

  Color _roleColor(String role, ThemeData theme) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'teacher':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.person;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Approvals', style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPending,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadPending,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pending.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt,
                              size: 64,
                              color:
                                  theme.colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No pending registrations',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'New teacher/student sign-ups will appear here for your approval.',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPending,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pending.length,
                        itemBuilder: (context, index) {
                          final account =
                              Map<String, dynamic>.from(_pending[index]);
                          final role = account['role']?.toString() ?? 'student';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _roleColor(role, theme).withOpacity(0.15),
                                child: Icon(_roleIcon(role),
                                    color: _roleColor(role, theme), size: 22),
                              ),
                              title: Text(
                                account['name']?.toString() ?? 'Unknown',
                                style: theme.textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(account['email']?.toString() ?? ''),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _roleColor(role, theme)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color: _roleColor(role, theme),
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Approve',
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () => _act(account, true),
                                  ),
                                  IconButton(
                                    tooltip: 'Reject',
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Reject account?'),
                                          content: Text(
                                              'Reject the registration of ${account['name']}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Reject'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        _act(account, false);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
