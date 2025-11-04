import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smart_planning_provider.dart';
import '../providers/permission_provider.dart';

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

  void _handleAction(BuildContext context, WidgetRef ref, SmartSuggestion suggestion) {
    // TODO: Implement action handlers
    // - For weather: Show detailed weather view
    // - For location: Set location-based reminder
    // - For preparation: Schedule notification

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action: ${suggestion.actionText}'),
        duration: const Duration(seconds: 2),
      ),
    );
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
