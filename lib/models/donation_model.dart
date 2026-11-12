import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

class DonationModel {
  final String donationId;
  final String donorId;
  final String donorName;
  final String donorPhone;
  final String foodName;
  final String category;
  final String description;
  final int quantity;
  final String foodImage;
  final String collectionAddress;
  final DateTime expiryDate;
  final String status;
  final DateTime createdAt;

  DonationModel({
    required this.donationId,
    required this.donorId,
    required this.donorName,
    required this.donorPhone,
    required this.foodName,
    required this.category,
    required this.description,
    required this.quantity,
    this.foodImage = '',
    required this.collectionAddress,
    required this.expiryDate,
    this.status = AppConstants.donationAvailable,
    required this.createdAt,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isAvailable =>
      status == AppConstants.donationAvailable && quantity > 0 && !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'donationId': donationId,
      'donorId': donorId,
      'donorName': donorName,
      'donorPhone': donorPhone,
      'foodName': foodName,
      'category': category,
      'description': description,
      'quantity': quantity,
      'foodImage': foodImage,
      'collectionAddress': collectionAddress,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      donationId: map['donationId'] ?? '',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      donorPhone: map['donorPhone'] ?? '',
      foodName: map['foodName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      foodImage: map['foodImage'] ?? '',
      collectionAddress: map['collectionAddress'] ?? '',
      expiryDate:
          (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? AppConstants.donationAvailable,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}