import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smart_planning_provider.dart';
import '../providers/permission_provider.dart';
import '../../data/services/notification_service.dart';

/// Widget to display smart suggestions for todos
class SmartSuggestionsCard extends ConsumerWidget {
  const SmartSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smartPlanningState = ref.watch(smartPlanningProvider);
    final permissionState = ref.watch(permissionProvider);

    // Show permission request if location is not granted (ignore notification for now due to iOS limitations)
    if (!permissionState.hasLocation) {
      return _PermissionRequestCard(
        missingPermissions: permissionState.missingPermissions,
        onRequestPermissions: () async {
          await ref.read(permissionProvider.notifier).requestAllPermissions();
        },
      );
    }

    // Show loading state
    if (smartPlanningState.isAnalyzing) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Analyzing smart suggestions...'),
            ],
          ),
        ),
      );
    }

    // Show error if any
    if (smartPlanningState.error != null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  smartPlanningState.error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(smartPlanningProvider.notifier).clearError();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Show suggestions if any
    if (smartPlanningState.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                'Smart Suggestions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...smartPlanningState.suggestions.map((suggestion) {
          return _SuggestionItem(suggestion: suggestion);
        }).toList(),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Individual suggestion item
class _SuggestionItem extends ConsumerWidget {
  final SmartSuggestion suggestion;

  const _SuggestionItem({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = suggestion.isUrgent ? Colors.orange : Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTypeLabel(suggestion.type),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                ),
                if (suggestion.isUrgent) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.warning_amber, size: 16, color: color.shade700),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.message,
              style: TextStyle(
                fontSize: 14,
                color: color.shade900,
              ),
            ),
            if (suggestion.actionText != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _handleAction(context, ref, suggestion);
                },
                style: TextButton.styleFrom(
                  foregroundColor: color.shade700,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      suggestion.actionText!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'weather':
        return 'WEATHER';
      case 'location':
        return 'LOCATION';
      case 'traffic':
        return 'TRAFFIC';
      case 'preparation':
        return 'REMINDER';
      default:
        return type.toUpperCase();
    }
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, SmartSuggestion suggestion) async {
    try {
      switch (suggestion.type) {
        case 'weather':
          // Show weather details
          _showWeatherDetails(context, suggestion);
          break;

        case 'location':
          // Set location-based reminder
          await _setLocationReminder(context, suggestion);
          break;

        case 'preparation':
        case 'traffic':
          // Schedule time-based notification
          await _scheduleReminder(context, suggestion);
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action: ${suggestion.actionText}'),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWeatherDetails(BuildContext context, SmartSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wb_sunny, color: Colors.orange),
            SizedBox(width: 8),
            Text('Weather Details'),
          ],
        ),
        content: Text(suggestion.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _setLocationReminder(BuildContext context, SmartSuggestion suggestion) async {
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Schedule reminder
    if (suggestion.suggestedTime != null) {
      await notificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Time to Leave!',
        body: suggestion.message,
        scheduledTime: suggestion.suggestedTime!,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${_formatTime(suggestion.suggestedTime!)}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      // No specific time, show dialog to set custom time
      if (!context.mounted) return;
      _showSetReminderDialog(context, suggestion);
    }
  }

  Future<void> _scheduleReminder(BuildContext context, SmartSuggestion suggestion) async {
    if (suggestion.suggestedTime != null) {
      final notificationService = NotificationService();
      await notificationService.initialize();

      await notificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: suggestion.type == 'preparation' ? 'Time to Prepare' : 'Traffic Alert',
        body: suggestion.message,
        scheduledTime: suggestion.suggestedTime!,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${_formatTime(suggestion.suggestedTime!)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!context.mounted) return;
      _showSetReminderDialog(context, suggestion);
    }
  }

  void _showSetReminderDialog(BuildContext context, SmartSuggestion suggestion) {
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Reminder Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(suggestion.message),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Reminder Time'),
                subtitle: Text(_formatDateTime(selectedDateTime)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final notificationService = NotificationService();
                await notificationService.initialize();

                await notificationService.scheduleNotification(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: 'Task Reminder',
                  body: suggestion.message,
                  scheduledTime: selectedDateTime,
                );

                Navigator.pop(context);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reminder set for ${_formatDateTime(selectedDateTime)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime time) {
    final date = '${time.month}/${time.day}/${time.year}';
    final timeStr = _formatTime(time);
    return '$date at $timeStr';
  }
}

/// Permission request card
class _PermissionRequestCard extends StatelessWidget {
  final List<String> missingPermissions;
  final VoidCallback onRequestPermissions;

  const _PermissionRequestCard({
    required this.missingPermissions,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = !missingPermissions.contains('Location');
    final bool hasNotifications = !missingPermissions.contains('Notifications');

    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Smart Planning Features',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Show what features are available (only location-based for now)
            _buildFeatureRow(
              context,
              Icons.traffic,
              'Traffic Updates',
              'Get departure time suggestions based on traffic',
              hasLocation,
            ),
            const SizedBox(height: 8),
            _buildFeatureRow(
              context,
              Icons.map,
              'Location Context',
              'See location details for your tasks',
              hasLocation,
            ),
            const SizedBox(height: 8),
            _buildFeatureRow(
              context,
              Icons.directions,
              'Travel Time',
              'Automatic travel time calculations',
              hasLocation,
            ),

            const SizedBox(height: 16),

            // Show permission status
            if (missingPermissions.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enable in Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To enable smart features, allow ${missingPermissions.join(' and ')} in your iPhone Settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRequestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.settings, size: 20),
                  label: const Text('Open iPhone Settings'),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All smart features are enabled!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String title, String description, bool enabled) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: enabled ? Colors.green.shade700 : Colors.grey.shade400,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.blue.shade900 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    enabled ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: enabled ? Colors.green.shade700 : Colors.grey.shade400,
                  ),
                ],
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? Colors.blue.shade700 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
