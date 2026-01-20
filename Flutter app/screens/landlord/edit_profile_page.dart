import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/user_session_service.dart';

class LandlordEditProfilePage extends StatefulWidget {
  const LandlordEditProfilePage({super.key});

  @override
  State<LandlordEditProfilePage> createState() => _LandlordEditProfilePageState();
}

class _LandlordEditProfilePageState extends State<LandlordEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _taxIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _selectedUniversity;
  List<String> _universities = [];
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUniversities();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final userEmail = await UserSessionService.getUserEmail();
      if (userEmail == null) {
        throw Exception('User not authenticated');
      }
      
      // TODO: Replace with actual API call to fetch landlord profile
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock data for now
      final userData = {
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'phoneNumber': '+1234567890',
        'companyName': 'Doe Properties',
        'companyAddress': '123 Business St, City, Country',
        'taxId': 'TAX123456789',
        'university': 'University of Example',
      };
      
      setState(() {
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneController.text = userData['phoneNumber'] ?? '';
        _companyNameController.text = userData['companyName'] ?? '';
        _companyAddressController.text = userData['companyAddress'] ?? '';
        _taxIdController.text = userData['taxId'] ?? '';
        _selectedUniversity = userData['university'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadUniversities() async {
    try {
      // TODO: Replace with actual API call to fetch universities
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Mock data for now
      setState(() {
        _universities = [
          'University of Example',
          'Tech University',
          'City College',
          'State University',
          'Global Institute of Technology',
        ];
      });
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
      _error = null;
    });
    
    try {
      // TODO: Replace with actual API call to update profile
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF07746B),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update profile: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
    bool enabled = true,
    Widget? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF07746B), width: 1.5),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[100]!,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorStyle: const TextStyle(fontSize: 12, height: 0.8),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    Widget? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: prefixIcon,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF07746B), width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorStyle: const TextStyle(fontSize: 12, height: 0.8),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
            validator: validator,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 28),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            menuMaxHeight: 300,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07746B),
              Color(0xFF0DDAC9),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SAVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.white),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadUserData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF07746B),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profile Picture Section
                                    Center(
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey[200],
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 4,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha:0.1),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                                image: _profileImage != null
                                                    ? DecorationImage(
                                                        image: FileImage(_profileImage!),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: _profileImage == null
                                                  ? const Icon(
                                                      Icons.person,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    )
                                                  : null,
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              right: 4,
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF07746B),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Personal Information Section
                                    _buildSectionTitle('Personal Information'),
                                    
                                    // First Name & Last Name Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFormField(
                                            label: 'First Name',
                                            controller: _firstNameController,
                                            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildFormField(
                                            label: 'Last Name',
                                            controller: _lastNameController,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Email
                                    _buildFormField(
                                      label: 'Email Address',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      enabled: false, // Email is not editable
                                      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
                                    ),

                                    // Phone Number
                                    _buildFormField(
                                      label: 'Phone Number',
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[600]),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        // Add phone validation if needed
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 8),
                                    
                                    // Company Information Section
                                    _buildSectionTitle('Company Information'),

                                    // Company Name
                                    _buildFormField(
                                      label: 'Company Name',
                                      controller: _companyNameController,
                                      prefixIcon: Icon(Icons.business_outlined, color: Colors.grey[600]),
                                    ),

                                    // Company Address
                                    _buildFormField(
                                      label: 'Company Address',
                                      controller: _companyAddressController,
                                      maxLines: 2,
                                      prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                                    ),

                                    // Tax ID
                                    _buildFormField(
                                      label: 'Tax ID',
                                      controller: _taxIdController,
                                      prefixIcon: Icon(Icons.receipt_long_outlined, color: Colors.grey[600]),
                                    ),

                                    // University Dropdown
                                    _buildDropdownField(
                                      label: 'University',
                                      value: _selectedUniversity,
                                      items: _universities,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedUniversity = value;
                                        });
                                      },
                                      prefixIcon: Icon(Icons.school_outlined, color: Colors.grey[600]),
                                    ),

                                    // Save Button
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isSaving ? null : _saveProfile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF07746B),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 2,
                                          shadowColor: const Color(0xFF07746B).withValues(alpha:0.3),
                                        ),
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'SAVE CHANGES',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
