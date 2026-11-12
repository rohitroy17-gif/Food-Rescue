import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case AppConstants.requestAccepted:
        return AppColors.success;
      case AppConstants.requestRejected:
        return AppColors.error;
      case AppConstants.requestCompleted:
        return Colors.blue;
      case AppConstants.requestCancelled:
        return AppColors.textGrey;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty
        ? ''
        : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}