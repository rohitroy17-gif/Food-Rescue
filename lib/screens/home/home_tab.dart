import 'package:flutter/material.dart';

import '../../models/donation_model.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../services/donation_service.dart';
import '../../services/request_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/food_card.dart';
import '../donation/food_details_screen.dart';

class HomeTab extends StatefulWidget {
  final UserModel user;

  const HomeTab({
    super.key,
    required this.user,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _donationService = DonationService();
  final _requestService = RequestService();
  final _searchController = TextEditingController();

  String _query = '';
  String _category = 'All';

  bool get _isDonor =>
      widget.user.role == AppConstants.roleDonor;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Apply search and category filters
  List<DonationModel> _applyFilters(
    List<DonationModel> all,
  ) {
    return all.where((d) {
      if (!d.isAvailable || d.isExpired) return false;

      final matchCategory =
          _category == 'All' || d.category == _category;

      final q = _query.trim().toLowerCase();

      final matchSearch = q.isEmpty ||
          d.foodName.toLowerCase().contains(q) ||
          d.collectionAddress.toLowerCase().contains(q);

      return matchCategory && matchSearch;
    }).toList();
  }

  // Open food details
  void _openDetails(DonationModel donation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailsScreen(
          donationId: donation.donationId,
          user: widget.user,
        ),
      ),
    );
  }

  // Statistics card
  Widget _statCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Responsive statistics grid
  Widget _statsGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1100
            ? 4
            : width >= 700
                ? 3
                : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: cards,
        );
      },
    );
  }

  // Calculate completed requests
  List<RequestModel> _completedRequests(
    List<RequestModel> requests,
  ) {
    return requests
        .where(
          (r) =>
              r.requestStatus ==
              AppConstants.requestCompleted,
        )
        .toList();
  }

  // Donor Dashboard
  Widget _donorDashboard() {
    return StreamBuilder<List<DonationModel>>(
      stream: _donationService.getMyDonations(
        widget.user.userId,
      ),
      builder: (context, donationSnapshot) {
        return StreamBuilder<List<RequestModel>>(
          stream: _requestService.getDonorRequests(
            widget.user.userId,
          ),
          builder: (context, requestSnapshot) {
            if (donationSnapshot.hasError ||
                requestSnapshot.hasError) {
              return const Text(
                'Could not load dashboard statistics.',
              );
            }

            if (donationSnapshot.connectionState ==
                    ConnectionState.waiting ||
                requestSnapshot.connectionState ==
                    ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final donations = donationSnapshot.data ?? [];
            final requests = requestSnapshot.data ?? [];

            final available = donations
                .where(
                  (d) => d.isAvailable && !d.isExpired,
                )
                .length;

            final accepted = requests
                .where(
                  (r) =>
                      r.requestStatus ==
                      AppConstants.requestAccepted,
                )
                .length;

            final completedRequests =
                _completedRequests(requests);

            final completed = completedRequests.length;

            final completedDonationIds = completedRequests
                .map((r) => r.donationId)
                .toSet();

            final foodSaved = completedRequests.fold<int>(
              0,
              (total, request) =>
                  total + request.requestedQuantity,
            );

            final peopleHelped = completedRequests
                .map((r) => r.receiverId)
                .where((id) => id.isNotEmpty)
                .toSet()
                .length;

            return _statsGrid([
              _statCard(
                'Total Donations',
                donations.length,
                Icons.volunteer_activism,
              ),
              _statCard(
                'Available Food',
                available,
                Icons.fastfood,
              ),
              _statCard(
                'Total Requests',
                requests.length,
                Icons.receipt_long,
              ),
              _statCard(
                'Accepted Requests',
                accepted,
                Icons.check_circle,
              ),
              _statCard(
                'Completed Requests',
                completed,
                Icons.task_alt,
              ),
              _statCard(
                'Completed Donations',
                completedDonationIds.length,
                Icons.card_giftcard,
              ),
              _statCard(
                'Food Saved (Units)',
                foodSaved,
                Icons.restaurant,
              ),
              _statCard(
                'People Helped',
                peopleHelped,
                Icons.people,
              ),
            ]);
          },
        );
      },
    );
  }

  // Receiver Dashboard
  Widget _receiverDashboard() {
    return StreamBuilder<List<DonationModel>>(
      stream: _donationService.getAllDonations(),
      builder: (context, donationSnapshot) {
        return StreamBuilder<List<RequestModel>>(
          stream: _requestService.getReceiverRequests(
            widget.user.userId,
          ),
          builder: (context, requestSnapshot) {
            if (donationSnapshot.hasError ||
                requestSnapshot.hasError) {
              return const Text(
                'Could not load dashboard statistics.',
              );
            }

            if (donationSnapshot.connectionState ==
                    ConnectionState.waiting ||
                requestSnapshot.connectionState ==
                    ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final donations = donationSnapshot.data ?? [];
            final requests = requestSnapshot.data ?? [];

            final available = donations
                .where(
                  (d) => d.isAvailable && !d.isExpired,
                )
                .length;

            final accepted = requests
                .where(
                  (r) =>
                      r.requestStatus ==
                      AppConstants.requestAccepted,
                )
                .length;

            final completedRequests =
                _completedRequests(requests);

            final completed = completedRequests.length;

            final foodReceived = completedRequests.fold<int>(
              0,
              (total, request) =>
                  total + request.requestedQuantity,
            );

            final donorsConnected = completedRequests
                .map((r) => r.donorId)
                .where((id) => id.isNotEmpty)
                .toSet()
                .length;

            return _statsGrid([
              _statCard(
                'Available Food',
                available,
                Icons.fastfood,
              ),
              _statCard(
                'Total Requests',
                requests.length,
                Icons.receipt_long,
              ),
              _statCard(
                'Accepted Requests',
                accepted,
                Icons.check_circle,
              ),
              _statCard(
                'Completed Requests',
                completed,
                Icons.task_alt,
              ),
              _statCard(
                'Food Received (Units)',
                foodReceived,
                Icons.restaurant,
              ),
              _statCard(
                'Donors Connected',
                donorsConnected,
                Icons.people,
              ),
            ]);
          },
        );
      },
    );
  }

  // Dashboard section
  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Dashboard & Impact Overview',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: _isDonor
              ? _donorDashboard()
              : _receiverDashboard(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...AppConstants.categories,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Header and Search
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            16,
          ),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${widget.user.fullName.split(' ').first} 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _isDonor
                    ? 'Thank you for sharing food with others'
                    : 'Find food available near you',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _query = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search food or location',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ],
          ),
        ),

        // Dashboard and Donation List
        Expanded(
          child: StreamBuilder<List<DonationModel>>(
            stream: _donationService.getAllDonations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Could not load donations. Please try again.',
                  ),
                );
              }

              final donations = _applyFilters(
                snapshot.data ?? [],
              );

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDashboard(),

                  // Category Filter
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final selected = cat == _category;

                        return ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => _category = cat);
                          },
                        );
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      8,
                    ),
                    child: Text(
                      'Available Donations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),

                  if (donations.isEmpty)
                    _buildEmptyState(),

                  if (donations.isNotEmpty)
                    ...donations.map(
                      (donation) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          12,
                        ),
                        child: FoodCard(
                          donation: donation,
                          onTap: () => _openDetails(donation),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    final hasSearch = _query.trim().isNotEmpty;
    final hasCategory = _category != 'All';

    String message;

    if (hasSearch) {
      message = 'No food found for "$_query"';
    } else if (hasCategory) {
      message = 'No food available in $_category category';
    } else {
      message = 'No food available right now';
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off
                : Icons.no_food_outlined,
            size: 70,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (hasSearch || hasCategory)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _query = '';
                  _category = 'All';
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }
}