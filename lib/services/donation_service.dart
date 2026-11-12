import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_model.dart';

class DonationService {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('donations');

  Future<String?> createDonation(DonationModel donation) async {
    try {
      await _ref.doc(donation.donationId).set(donation.toMap());
      return null;
    } catch (e) {
      return 'Could not create donation. Please try again.';
    }
  }

  Future<String?> updateDonation(DonationModel donation) async {
    try {
      await _ref.doc(donation.donationId).update(donation.toMap());
      return null;
    } catch (e) {
      return 'Could not update donation. Please try again.';
    }
  }

  Future<String?> deleteDonation(String donationId) async {
    try {
      await _ref.doc(donationId).delete();
      return null;
    } catch (e) {
      return 'Could not delete donation. Please try again.';
    }
  }

  String newId() => _ref.doc().id;

  Stream<List<DonationModel>> getAllDonations() {
    return _ref.snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((d) => DonationModel.fromMap(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<DonationModel>> getMyDonations(String donorId) {
    return _ref.where('donorId', isEqualTo: donorId).snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((d) => DonationModel.fromMap(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<DonationModel?> getDonation(String donationId) async {
    final doc = await _ref.doc(donationId).get();
    if (!doc.exists || doc.data() == null) return null;
    return DonationModel.fromMap(doc.data()!);
  }
}