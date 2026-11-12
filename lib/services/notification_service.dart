import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('notifications');

  // Generate unique notification ID
  String newId() => _ref.doc().id;

  // Create notification
  Future<String?> createNotification(
    NotificationModel notification,
  ) async {
    try {
      await _ref
          .doc(notification.notificationId)
          .set(notification.toMap());

      return null;
    } catch (e) {
      return 'Could not create notification.';
    }
  }

  // Get all notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(
    String userId,
  ) {
    return _ref
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();

      notifications.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return notifications;
    });
  }

  // Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _ref
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark one notification as read
  Future<String?> markAsRead(String notificationId) async {
    try {
      await _ref.doc(notificationId).update({
        'isRead': true,
      });

      return null;
    } catch (e) {
      return 'Could not update notification.';
    }
  }

  // Mark all notifications as read
  Future<String?> markAllAsRead(String userId) async {
    try {
      final snapshot = await _ref
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
        });
      }

      await batch.commit();

      return null;
    } catch (e) {
      return 'Could not update notifications.';
    }
  }

  // Delete one notification
  Future<String?> deleteNotification(String notificationId) async {
    try {
      await _ref.doc(notificationId).delete();

      return null;
    } catch (e) {
      return 'Could not delete notification.';
    }
  }
}