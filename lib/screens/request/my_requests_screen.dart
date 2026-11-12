import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/helpers.dart';

class MyRequestsScreen extends StatefulWidget {
  final UserModel user;

  const MyRequestsScreen({
    super.key,
    required this.user,
  });

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final RequestService _requestService = RequestService();

  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.requestPending:
        return AppColors.warning;
      case AppConstants.requestAccepted:
        return AppColors.success;
      case AppConstants.requestRejected:
        return AppColors.error;
      case AppConstants.requestCompleted:
        return AppColors.primary;
      case AppConstants.requestCancelled:
        return AppColors.textGrey;
      default:
        return AppColors.textGrey;
    }
  }

  Future<void> _updateRequest(
    RequestModel request, {
    required bool isComplete,
  }) async {
    final action = isComplete ? 'complete' : 'cancel';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isComplete ? 'Complete Request?' : 'Cancel Request?',
        ),
        content: Text(
          isComplete
              ? 'Have you collected this food?'
              : 'Are you sure you want to cancel this request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              isComplete ? 'Complete' : 'Cancel',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = isComplete
        ? await _requestService.completeRequest(request.requestId)
        : await _requestService.cancelRequest(request.requestId);

    if (!mounted) return;

    showMessage(
      context,
      error ?? 'Request $action successfully!',
      isError: error != null,
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(RequestModel request) {
    if (request.requestStatus == AppConstants.requestPending) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => _updateRequest(
            request,
            isComplete: false,
          ),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Request'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
        ),
      );
    }

    if (request.requestStatus == AppConstants.requestAccepted) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () => _updateRequest(
            request,
            isComplete: true,
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark Completed'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: _requestService.getReceiverRequests(widget.user.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Something went wrong. Please try again.',
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 65,
                  color: AppColors.textGrey,
                ),
                SizedBox(height: 12),
                Text(
                  'No requests yet!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your food requests will appear here.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(
                            Icons.fastfood,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            request.foodName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        _buildStatusBadge(request.requestStatus),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Requested Quantity: ${request.requestedQuantity}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildActions(request),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}