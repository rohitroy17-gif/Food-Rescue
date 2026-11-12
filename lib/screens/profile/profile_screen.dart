import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isLoading = false;

  late String _fullName;
  late String _phone;

  @override
  void initState() {
    super.initState();

    _fullName = widget.user.fullName;
    _phone = widget.user.phone;

    _nameController = TextEditingController(text: _fullName);
    _phoneController = TextEditingController(text: _phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isDonor =>
      widget.user.role == AppConstants.roleDonor;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _authService.updateProfile(
      uid: widget.user.userId,
      fullName: _nameController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error == null) {
      setState(() {
        _fullName = _nameController.text.trim();
        _phone = _phoneController.text.trim();
        _isEditing = false;
      });

      showMessage(
        context,
        'Profile updated successfully!',
      );
    } else {
      showMessage(
        context,
        error,
        isError: true,
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = _fullName;
      _phoneController.text = _phone;
      _isEditing = false;
    });
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primaryLight,
          child: Icon(
            Icons.person,
            size: 55,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 15),

        Text(
          _fullName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isDonor ? 'DONOR' : 'RECEIVER',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 25),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.person_outline,
                title: 'Full Name',
                value: _fullName,
              ),

              const Divider(height: 1),

              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: widget.user.email,
              ),

              const Divider(height: 1),

              _buildInfoTile(
                icon: Icons.phone_outlined,
                title: 'Phone Number',
                value: _phone,
              ),

              const Divider(height: 1),

              _buildInfoTile(
                icon: Icons.calendar_month_outlined,
                title: 'Member Since',
                value: DateFormat('dd MMM yyyy')
                    .format(widget.user.createdAt),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _nameController.text = _fullName;
                _phoneController.text = _phone;
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Your Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 25),

          TextFormField(
            controller: _nameController,
            validator: Validators.validateName,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),

          const SizedBox(height: 18),

          TextFormField(
            initialValue: widget.user.email,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),

          const SizedBox(height: 18),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isLoading ? null : _cancelEditing,
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _isEditing
          ? _buildEditForm()
          : _buildProfileContent(),
    );
  }
}