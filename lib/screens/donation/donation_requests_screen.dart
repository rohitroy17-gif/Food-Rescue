import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/donation_model.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/status_badge.dart';

class DonationRequestsScreen extends StatefulWidget {
  final DonationModel donation;
  const DonationRequestsScreen({super.key, required this.donation});

  @override
  State<DonationRequestsScreen> createState() => _DonationRequestsScreenState();
}

class _DonationRequestsScreenState extends State<DonationRequestsScreen> {
  final _requestService = RequestService();
  String? _busyId;

  Future<void> _run(
    RequestModel request,
    Future<String?> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyId = request.requestId);
    final error = await action();
    if (!mounted) return;
    setState(() => _busyId = null);
    if (error != null) {
      showMessage(context, error, isError: true);
    } else {
      showMessage(context, successMessage);
    }
  }

  Widget _requestCard(RequestModel r) {
    final busy = _busyId == r.requestId;
    final pending = r.requestStatus == AppConstants.requestPending;
    final accepted = r.requestStatus == AppConstants.requestAccepted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.receiverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: r.requestStatus),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 18, color: AppColors.textGrey),
              const SizedBox(width: 6),
              Text('Requested quantity: ${r.requestedQuantity}'),
            ],
          ),
          if (r.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                r.message,
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 14),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _run(
                        r,
                        () => _requestService.rejectRequest(r.requestId),
                        'Request rejected',
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () => _run(
                        r,
                        () => _requestService.acceptRequest(r),
                        'Request accepted',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
              ),
          ],
          if (accepted) ...[
            const SizedBox(height: 14),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 46),
                ),
                onPressed: () => _run(
                  r,
                  () => _requestService.completeRequest(r.requestId),
                  'Marked as completed',
                ),
                icon: const Icon(Icons.done_all),
                label: const Text('Mark as Completed'),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.donation.foodName)),
      body: StreamBuilder<List<RequestModel>>(
        stream: _requestService.getRequestsForDonation(
          widget.donation.donationId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load requests.'));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 70, color: AppColors.textGrey),
                  SizedBox(height: 12),
                  Text(
                    'No requests yet',
                    style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _requestCard(requests[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}