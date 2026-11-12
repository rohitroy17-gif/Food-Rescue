import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/donation_model.dart';
import '../../models/user_model.dart';
import '../../services/donation_service.dart';
import '../../services/image_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class CreateDonationScreen extends StatefulWidget {
  final UserModel user;
  final DonationModel? existing;

  const CreateDonationScreen({super.key, required this.user, this.existing});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _donationService = DonationService();
  final _imageService = ImageService();

  String _category = AppConstants.categories.first;
  String _imageBase64 = '';
  DateTime? _expiry;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    if (d != null) {
      _nameController.text = d.foodName;
      _descController.text = d.description;
      _quantityController.text = d.quantity.toString();
      _addressController.text = d.collectionAddress;
      _phoneController.text = d.donorPhone;
      _category = d.category;
      _imageBase64 = d.foodImage;
      _expiry = d.expiryDate;
    } else {
      _phoneController.text = widget.user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await _imageService.pickImageAsBase64();
    if (result != null) {
      setState(() => _imageBase64 = result);
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiry != null && _expiry!.isAfter(now) ? _expiry! : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiry ?? now),
    );
    if (time == null) return;

    setState(() {
      _expiry = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiry == null) {
      showMessage(context, 'Please select expiry date and time', isError: true);
      return;
    }
    if (_expiry!.isBefore(DateTime.now())) {
      showMessage(context, 'Expiry time must be in the future', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final old = widget.existing;
    final quantity = int.parse(_quantityController.text.trim());

    String status = old?.status ?? AppConstants.donationAvailable;
    if (old != null && quantity > 0 && status == AppConstants.donationUnavailable) {
      status = AppConstants.donationAvailable;
    }

    final donation = DonationModel(
      donationId: old?.donationId ?? _donationService.newId(),
      donorId: widget.user.userId,
      donorName: widget.user.fullName,
      donorPhone: _phoneController.text.trim(),
      foodName: _nameController.text.trim(),
      category: _category,
      description: _descController.text.trim(),
      quantity: quantity,
      foodImage: _imageBase64,
      collectionAddress: _addressController.text.trim(),
      expiryDate: _expiry!,
      status: status,
      createdAt: old?.createdAt ?? DateTime.now(),
    );

    final error = _isEdit
        ? await _donationService.updateDonation(donation)
        : await _donationService.createDonation(donation);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      showMessage(context, error, isError: true);
      return;
    }

    showMessage(
      context,
      _isEdit ? 'Donation updated successfully' : 'Donation posted successfully',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Donation' : 'Create Donation'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imageBase64.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      size: 44, color: AppColors.primary),
                                  SizedBox(height: 8),
                                  Text('Tap to add food photo',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              )
                            : Image.memory(
                                base64Decode(_imageBase64),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    if (_imageBase64.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _imageBase64 = ''),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          label: const Text('Remove photo',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        prefixIcon: Icon(Icons.fastfood_outlined),
                      ),
                      validator: (v) =>
                          Validators.validateRequired(v, 'Food name'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: AppConstants.categories
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (v) =>
                          Validators.validateRequired(v, 'Description'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Available Quantity (portions/pieces)',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Quantity is required';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) {
                          return 'Enter a whole number greater than 0';
                        }
                        if (n > 1000) {
                          return 'Quantity cannot exceed 1000';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Collection Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) =>
                          Validators.validateRequired(v, 'Address'),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickExpiry,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date & Time',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        child: Text(
                          _expiry == null
                              ? 'Tap to select'
                              : DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(_expiry!),
                          style: TextStyle(
                            color: _expiry == null
                                ? AppColors.textGrey
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEdit ? 'Update Donation' : 'Post Donation'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}