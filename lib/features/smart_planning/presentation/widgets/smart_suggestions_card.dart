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

    // Show permission request if not granted
    if (!permissionState.allGranted) {
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
                Icon(Icons.security, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enable Smart Features',
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
            Text(
              'Grant permissions to enable smart planning features:',
              style: TextStyle(color: Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            ...missingPermissions.map((permission) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      permission,
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRequestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Grant Permissions'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart features include weather alerts, location reminders, and preparation notifications.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
