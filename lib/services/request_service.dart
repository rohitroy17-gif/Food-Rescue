
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/donation_model.dart';
import '../models/request_model.dart';
import '../models/notification_model.dart';
import '../utils/app_constants.dart';
import 'notification_service.dart';

class RequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('requests');

  CollectionReference<Map<String, dynamic>> get _donations =>
      _db.collection('donations');

  String newId() => _ref.doc().id;

  // Send notification to donor
  Future<void> _notifyDonor({
    required String donorId,
    required RequestModel request,
  }) async {
    final notificationService = NotificationService();

    final notification = NotificationModel(
      notificationId: notificationService.newId(),
      userId: donorId,
      title: 'New Food Request',
      message:
          '${request.receiverName} requested '
          '${request.requestedQuantity} quantity of '
          '${request.foodName}.',
      type: 'new_request',
      relatedId: request.requestId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await notificationService.createNotification(notification);
  }

  // Send notification to receiver
  Future<void> _notifyReceiver({
    required String receiverId,
    required String title,
    required String message,
    required String type,
    required String requestId,
  }) async {
    final notificationService = NotificationService();

    final notification = NotificationModel(
      notificationId: notificationService.newId(),
      userId: receiverId,
      title: title,
      message: message,
      type: type,
      relatedId: requestId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await notificationService.createNotification(notification);
  }

  // Create a new food request
  Future<String?> createRequest(RequestModel request) async {
    try {
      final donSnap = await _donations.doc(request.donationId).get();

      if (!donSnap.exists || donSnap.data() == null) {
        return 'This donation no longer exists.';
      }

      final donation = DonationModel.fromMap(donSnap.data()!);

      if (donation.isExpired) {
        return 'This food has expired.';
      }

      if (!donation.isAvailable) {
        return 'This food is no longer available.';
      }

      if (request.requestedQuantity <= 0) {
        return 'Quantity must be greater than 0.';
      }

      if (request.requestedQuantity > donation.quantity) {
        return 'Only ${donation.quantity} available.';
      }

      if (donation.donorId == request.receiverId) {
        return 'You cannot request your own donation.';
      }

      final existing = await _ref
          .where('donationId', isEqualTo: request.donationId)
          .where('receiverId', isEqualTo: request.receiverId)
          .get();

      final hasPending = existing.docs.any(
        (d) =>
            d.data()['requestStatus'] ==
            AppConstants.requestPending,
      );

      if (hasPending) {
        return 'You already have a pending request for this food.';
      }

      await _ref.doc(request.requestId).set(request.toMap());

      // Notify donor
      try {
        await _notifyDonor(
          donorId: donation.donorId,
          request: request,
        );
      } catch (e) {
        // Request remains successful if notification fails.
      }

      return null;
    } catch (e) {
      return 'Could not send request. Please try again.';
    }
  }

  // Convert Firestore documents into RequestModel list
  List<RequestModel> _toList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = snapshot.docs
        .map((d) => RequestModel.fromMap(d.data()))
        .toList();

    list.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return list;
  }

  // Get requests for a specific donation
  // Security Rules require donorId verification.
  Stream<List<RequestModel>> getRequestsForDonation(
    String donationId,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Stream.value([]);
    }

    return _ref
        .where('donationId', isEqualTo: donationId)
        .where('donorId', isEqualTo: currentUser.uid)
        .snapshots()
        .map(_toList);
  }

  // Get all requests made by a receiver
  Stream<List<RequestModel>> getReceiverRequests(
    String receiverId,
  ) {
    return _ref
        .where('receiverId', isEqualTo: receiverId)
        .snapshots()
        .map(_toList);
  }

  // Get all requests received by a donor
  Stream<List<RequestModel>> getDonorRequests(
    String donorId,
  ) {
    return _ref
        .where('donorId', isEqualTo: donorId)
        .snapshots()
        .map(_toList);
  }

  // Accept a food request
  Future<String?> acceptRequest(RequestModel request) async {
    try {
      await _db.runTransaction((tx) async {
        final reqRef = _ref.doc(request.requestId);
        final donRef = _donations.doc(request.donationId);

        final reqSnap = await tx.get(reqRef);
        final donSnap = await tx.get(donRef);

        if (!reqSnap.exists || !donSnap.exists) {
          throw 'Request or donation not found.';
        }

        final current = RequestModel.fromMap(reqSnap.data()!);
        final donation = DonationModel.fromMap(donSnap.data()!);

        if (current.requestStatus != AppConstants.requestPending) {
          throw 'This request is no longer pending.';
        }

        if (donation.isExpired) {
          throw 'This food has expired.';
        }

        if (donation.quantity < current.requestedQuantity) {
          throw 'Not enough quantity left. Only ${donation.quantity} available.';
        }

        final left = donation.quantity - current.requestedQuantity;

        tx.update(donRef, {
          'quantity': left,
          'status': left <= 0
              ? AppConstants.donationUnavailable
              : donation.status,
        });

        tx.update(reqRef, {
          'requestStatus': AppConstants.requestAccepted,
        });
      });

      // Notify receiver after successful acceptance
      try {
        await _notifyReceiver(
          receiverId: request.receiverId,
          title: 'Request Accepted',
          message:
              'Your request for ${request.foodName} has been accepted.',
          type: 'request_accepted',
          requestId: request.requestId,
        );
      } catch (e) {
        // Acceptance remains successful if notification fails.
      }

      return null;
    } on FirebaseException {
      return 'Could not accept request. Please try again.';
    } catch (e) {
      return e is String
          ? e
          : 'Could not accept request. Please try again.';
    }
  }

  // Change request status
  Future<String?> _changeStatus({
    required String requestId,
    required String newStatus,
    required List<String> allowedFrom,
  }) async {
    try {
      final doc = await _ref.doc(requestId).get();

      if (!doc.exists || doc.data() == null) {
        return 'Request not found.';
      }

      final data = doc.data()!;
      final current = data['requestStatus'];

      if (!allowedFrom.contains(current)) {
        return 'This request is already $current.';
      }

      await _ref.doc(requestId).update({
        'requestStatus': newStatus,
      });

      // Notify receiver after successful status update
      try {
        final receiverId = data['receiverId'] ?? '';
        final foodName = data['foodName'] ?? 'food';

        if (receiverId.isNotEmpty) {
          String title = '';
          String message = '';
          String type = '';

          if (newStatus == AppConstants.requestRejected) {
            title = 'Request Rejected';
            message = 'Your request for $foodName has been rejected.';
            type = 'request_rejected';
          } else if (newStatus == AppConstants.requestCompleted) {
            title = 'Food Collection Completed';
            message = 'Your request for $foodName has been completed.';
            type = 'request_completed';
          }

          if (title.isNotEmpty) {
            await _notifyReceiver(
              receiverId: receiverId,
              title: title,
              message: message,
              type: type,
              requestId: requestId,
            );
          }
        }
      } catch (e) {
        // Status update remains successful if notification fails.
      }

      return null;
    } catch (e) {
      return 'Could not update request. Please try again.';
    }
  }

  // Reject request
  Future<String?> rejectRequest(String requestId) {
    return _changeStatus(
      requestId: requestId,
      newStatus: AppConstants.requestRejected,
      allowedFrom: [AppConstants.requestPending],
    );
  }

  // Cancel request
  Future<String?> cancelRequest(String requestId) {
    return _changeStatus(
      requestId: requestId,
      newStatus: AppConstants.requestCancelled,
      allowedFrom: [AppConstants.requestPending],
    );
  }

  // Complete request
  Future<String?> completeRequest(String requestId) {
    return _changeStatus(
      requestId: requestId,
      newStatus: AppConstants.requestCompleted,
      allowedFrom: [AppConstants.requestAccepted],
    );
  }
}
