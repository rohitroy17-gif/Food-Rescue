import 'package:flutter/material.dart';
import '../../models/donation_model.dart';
import '../../models/user_model.dart';
import '../../services/donation_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/food_card.dart';
import 'create_donation_screen.dart';
import 'donation_requests_screen.dart';

class MyDonationsScreen extends StatelessWidget {
  final UserModel user;
  const MyDonationsScreen({super.key, required this.user});

  Future<void> _confirmDelete(
    BuildContext context,
    DonationModel donation,
  ) async {
    final service = DonationService();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete donation?'),
        content: Text('"${donation.foodName}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final error = await service.deleteDonation(donation.donationId);
    if (!context.mounted) return;
    if (error != null) {
      showMessage(context, error, isError: true);
    } else {
      showMessage(context, 'Donation deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = DonationService();

    return StreamBuilder<List<DonationModel>>(
      stream: service.getMyDonations(user.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not load your donations.'),
          );
        }
        final donations = snapshot.data ?? [];
        if (donations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.volunteer_activism_outlined,
                    size: 70, color: AppColors.textGrey),
                SizedBox(height: 12),
                Text(
                  'You have not posted any food yet',
                  style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap "Post Food" to share your first donation',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: donations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final d = donations[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  FoodCard(
                    donation: d,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DonationRequestsScreen(donation: d),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DonationRequestsScreen(donation: d),
                                ),
                              );
                            },
                            icon: const Icon(Icons.inbox_outlined, size: 18),
                            label: const Text('Requests'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateDonationScreen(
                                    user: user,
                                    existing: d,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _confirmDelete(context, d),
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}