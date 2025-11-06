import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/smart_schedule.dart';

class ConflictAlertCard extends StatelessWidget {
  final ScheduleConflict conflict;

  const ConflictAlertCard({
    super.key,
    required this.conflict,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor(conflict.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getConflictIcon(conflict.type),
              color: color.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getConflictTitle(context, conflict.type),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conflict.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: conflict.tasks.map((task) {
                      return Chip(
                        label: Text(
                          task.title,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: color.shade100,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            _buildSeverityBadge(context, conflict.severity, color),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(BuildContext context, ConflictSeverity severity, MaterialColor color) {
    final l10n = AppLocalizations.of(context)!;
    String text;
    switch (severity) {
      case ConflictSeverity.high:
        text = l10n.high;
        break;
      case ConflictSeverity.medium:
        text = l10n.med;
        break;
      case ConflictSeverity.low:
        text = l10n.low;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  MaterialColor _getSeverityColor(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.high:
        return Colors.red;
      case ConflictSeverity.medium:
        return Colors.orange;
      case ConflictSeverity.low:
        return Colors.yellow;
    }
  }

  IconData _getConflictIcon(ConflictType type) {
    switch (type) {
      case ConflictType.timeOverlap:
        return Icons.schedule_outlined;
      case ConflictType.tightSchedule:
        return Icons.timer_outlined;
      case ConflictType.locationConflict:
        return Icons.location_off;
      case ConflictType.impossibleTravel:
        return Icons.directions_off;
    }
  }

  String _getConflictTitle(BuildContext context, ConflictType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case ConflictType.timeOverlap:
        return l10n.timeOverlap;
      case ConflictType.tightSchedule:
        return l10n.tightSchedule;
      case ConflictType.locationConflict:
        return l10n.locationConflict;
      case ConflictType.impossibleTravel:
        return l10n.impossibleTravelTime;
    }
  }
}
