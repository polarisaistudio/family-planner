import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/smart_schedule.dart';
import '../../../../l10n/app_localizations.dart';

class TimeBlockCard extends StatelessWidget {
  final TimeBlock block;

  const TimeBlockCard({
    super.key,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final startTimeStr = DateFormat('h:mm a').format(block.startTime);
    final endTimeStr = DateFormat('h:mm a').format(block.endTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: block.isSuggested ? 1 : 2,
      color: block.isSuggested ? Colors.blue.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time column
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      startTimeStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      endTimeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (block.isSuggested)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.suggested,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _getPriorityColor(block.task.priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      block.task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Duration breakdown
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChip(
                          Icons.timer,
                          AppLocalizations.of(context)!.durationMinutes(block.durationMinutes),
                          Colors.blue,
                        ),
                        if (block.includedTravelTime > 0)
                          _buildChip(
                            Icons.directions_car,
                            AppLocalizations.of(context)!.travelTime(block.includedTravelTime),
                            Colors.orange,
                          ),
                        if (block.task.location != null)
                          _buildChip(
                            Icons.location_on,
                            _truncateLocation(block.task.location!),
                            Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Priority indicator
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildPriorityBadge(block.task.priority),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(int priority) {
    String text;
    MaterialColor color;

    switch (priority) {
      case 1:
        text = 'P1';
        color = Colors.red;
        break;
      case 2:
        text = 'P2';
        color = Colors.orange;
        break;
      case 3:
        text = 'P3';
        color = Colors.blue;
        break;
      case 4:
        text = 'P4';
        color = Colors.green;
        break;
      default:
        text = 'P5';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color.shade700,
        ),
      ),
    );
  }

  MaterialColor _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _truncateLocation(String location) {
    if (location.length <= 20) return location;
    return '${location.substring(0, 20)}...';
  }
}
