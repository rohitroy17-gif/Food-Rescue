import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/donation_model.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../services/donation_service.dart';
import '../../services/request_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/food_image.dart';

class FoodDetailsScreen extends StatelessWidget {
  final String donationId;
  final UserModel user;

  const FoodDetailsScreen({
    super.key,
    required this.donationId,
    required this.user,
  });

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRequestDialog(
    BuildContext context,
    DonationModel donation,
  ) async {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController(text: '1');
    final messageController = TextEditingController();
    final requestService = RequestService();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Request Food'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity (max ${donation.quantity})',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) {
                            return 'Enter a number greater than 0';
                          }
                          if (n > donation.quantity) {
                            return 'Only ${donation.quantity} available';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message (optional)',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.message_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(110, 44),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isLoading = true);

                          final request = RequestModel(
                            requestId: requestService.newId(),
                            donationId: donation.donationId,
                            foodName: donation.foodName,
                            donorId: donation.donorId,
                            receiverId: user.userId,
                            receiverName: user.fullName,
                            requestedQuantity:
                                int.parse(quantityController.text.trim()),
                            message: messageController.text.trim(),
                            createdAt: DateTime.now(),
                          );

                          final error =
                              await requestService.createRequest(request);

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!context.mounted) return;
                          if (error != null) {
                            showMessage(context, error, isError: true);
                          } else {
                            showMessage(context, 'Request sent successfully');
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = DonationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Food Details')),
      body: StreamBuilder<List<DonationModel>>(
        stream: service.getAllDonations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches =
              (snapshot.data ?? []).where((d) => d.donationId == donationId);
          if (matches.isEmpty) {
            return const Center(
              child: Text('This donation is no longer available.'),
            );
          }
          final d = matches.first;
          final isReceiver = user.role == AppConstants.roleReceiver;
          final canRequest = isReceiver && d.isAvailable;

          String? blockedReason;
          if (d.isExpired) {
            blockedReason = 'This food has expired';
          } else if (!d.isAvailable) {
            blockedReason = 'This food is no longer available';
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FoodImage(
                            base64Image: d.foodImage,
                            height: 240,
                            width: double.infinity,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.foodName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    d.category,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  d.description,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                const Divider(height: 32),
                                _infoRow(Icons.inventory_2_outlined,
                                    'Available Quantity', '${d.quantity}'),
                                _infoRow(
                                  Icons.timer_outlined,
                                  'Expiry',
                                  d.isExpired
                                      ? 'Expired'
                                      : DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(d.expiryDate),
                                  color: d.isExpired
                                      ? AppColors.error
                                      : AppColors.accent,
                                ),
                                _infoRow(Icons.location_on_outlined,
                                    'Collection Location', d.collectionAddress),
                                const Divider(height: 32),
                                _infoRow(
                                    Icons.person_outline, 'Donor', d.donorName),
                                _infoRow(Icons.phone_outlined, 'Contact',
                                    d.donorPhone),
                                _infoRow(
                                  Icons.event_outlined,
                                  'Posted On',
                                  DateFormat('dd MMM yyyy')
                                      .format(d.createdAt),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isReceiver)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (blockedReason != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              blockedReason,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                          ),
                          onPressed: canRequest
                              ? () => _openRequestDialog(context, d)
                              : null,
                          icon: const Icon(Icons.shopping_basket_outlined),
                          label: const Text('Request Food'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}