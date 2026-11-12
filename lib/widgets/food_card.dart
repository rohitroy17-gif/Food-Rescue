import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donation_model.dart';
import '../utils/app_colors.dart';
import 'food_image.dart';

class FoodCard extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onTap;

  const FoodCard({super.key, required this.donation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final expired = donation.isExpired;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            FoodImage(
              base64Image: donation.foodImage,
              height: 110,
              width: 110,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.foodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        donation.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text('${donation.quantity} available',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textGrey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 14,
                            color:
                                expired ? AppColors.error : AppColors.accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            expired
                                ? 'Expired'
                                : DateFormat('dd MMM, hh:mm a')
                                    .format(donation.expiryDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  expired ? AppColors.error : AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation.collectionAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textGrey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}