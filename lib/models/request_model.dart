import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

class RequestModel {
  final String requestId;
  final String donationId;
  final String foodName;
  final String donorId;
  final String receiverId;
  final String receiverName;
  final int requestedQuantity;
  final String message;
  final String requestStatus;
  final DateTime createdAt;

  RequestModel({
    required this.requestId,
    required this.donationId,
    required this.foodName,
    required this.donorId,
    required this.receiverId,
    required this.receiverName,
    required this.requestedQuantity,
    this.message = '',
    this.requestStatus = AppConstants.requestPending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'donationId': donationId,
      'foodName': foodName,
      'donorId': donorId,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'requestedQuantity': requestedQuantity,
      'message': message,
      'requestStatus': requestStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      requestId: map['requestId'] ?? '',
      donationId: map['donationId'] ?? '',
      foodName: map['foodName'] ?? '',
      donorId: map['donorId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      requestedQuantity: (map['requestedQuantity'] ?? 0).toInt(),
      message: map['message'] ?? '',
      requestStatus: map['requestStatus'] ?? AppConstants.requestPending,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}