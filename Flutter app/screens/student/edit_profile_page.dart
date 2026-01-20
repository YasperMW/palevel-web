import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../services/user_session_service.dart';
import '../../theme/app_colors.dart';

import '../../widgets/modern_bottom_nav.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();

  String? _selectedUniversity;
  final List<String> _universities = [
    "University of Malawi (UNIMA)",
    "Malawi University of Science and Technology (MUST)",
    "Lilongwe University of Agriculture and Natural Resources (LUANAR)",
    "Mzuzu University (MZUNI)",
    "Malawi University of Business and Applied Sciences (MUBAS)",
    "Kamuzu University of Health Sciences (KUHeS)",
    "Malawi College of Accountancy (MCA)",
    "Malawi School of Government (MSG)",
    "Domasi College of Education (DCE)",
    "Nalikule College of Education (NCE)",
    "Malawi College of Health Sciences (MCHS)",
    "Mikolongwe College of Veterinary Sciences (MCVS)",
    "Malawi College of Forestry and Wildlife (MCFW)",
    "Malawi Institute of Tourism (MIT)",
    "Marine College (MC)",
    "Civil Aviation Training Centre (CATC)",
    "Montfort Special Needs Education Centre (MSNEC)",
    "National College of Information Technology (NACIT)",
    "Guidance, Counselling and Youth Development Centre for Africa (GCYDCA)",
    "Catholic University of Malawi (CUNIMA)",
    "DMI St John the Baptist University (DMI)",
    "Nkhoma University (NKHUNI)",
    "Malawi Assemblies of God University (MAGU)",
    "Daeyang University (DU)",
    "Malawi Adventist University (MAU)",
    "Pentecostal Life University (PLU)",
    "African Bible College (ABC)",
    "University of Livingstonia (UNILIA)",
    "Exploits University (EU)",
    "University of Lilongwe (UNILIL)",
    "Millennium University (MU)",
    "Lake Malawi Anglican University (LAMAU)",
    "Unicaf University Malawi (UNICAF)",
    "Blantyre International University (BIU)",
    "ShareWORLD Open University (SWOU)",
    "Skyway University (SU)",
    "University of Blantyre Synod (UBS)",
    "Jubilee University (JU)",
    "Marble Hill University (MHU)",
    "Zomba Theological College (ZTC)",
    "Emmanuel University (EMUNI)",
    "ESAMI (ESAMI)",
    "Evangelical Bible College of Malawi (EBCoM)",
    "University of Hebron (UOH)",
    "Malawi Institute of Journalism (MIJ)",
    "International Open University (IOU)",
    "International College of Business and Management (ICBM)",
    "St John of God College of Health Sciences (SJOG)",
    "PACT College (PACT)",
    "K & M School of Accountancy (KM)",
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final user = await UserSessionService.getCachedUserData();
    if (user != null && mounted) {
      setState(() {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _phoneController.text = user.phoneNumber ?? '';

        final uni = user.university;
        if (uni != null && _universities.contains(uni)) {
          _universityController.text = uni;
          _selectedUniversity = uni;
        } else {
          _universityController.text = '';
          _selectedUniversity = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final password = await _askForPassword();
    if (password == null || password.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final updated = await ApiService.updateUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        university: _universityController.text.trim().isEmpty ? null : _universityController.text.trim(),
        password: password,
      );

      // Update local cache using the app's User model
      try {
        final userModel = User.fromJson(updated);
        await UserSessionService.saveUserData(userModel);
      } catch (_) {
        // Fallback: if the returned shape isn't exactly what User.fromJson expects,
        // build a minimal User object to cache important fields.
        await UserSessionService.saveUserData(User(
          userId: updated['user_id']?.toString() ?? '',
          email: updated['email'] ?? '',
          userType: updated['user_type'] ?? '',
          firstName: updated['first_name'] ?? '',
          lastName: updated['last_name'] ?? '',
        ));
      }

      // Also save university separately
      if (updated['university'] != null) {
        await UserSessionService.saveUniversity(updated['university']);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppColors.success,
      ));

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update profile: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _askForPassword() async {
    final TextEditingController pwController = TextEditingController();
    String? result;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Confirm Password',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          scrollable: true,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your password to confirm changes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.errorGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  result = pwController.text;
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Confirm',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    return result;
  }

  // Custom text field widget for consistent styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.grey.shade600,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCached,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                child: FutureBuilder<User?>(
                  future: UserSessionService.getCachedUserData(),
                  builder: (context, snap) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Update your personal information',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha:0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha:0.2),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey[700],
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Form Fields
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Information',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // First Name
                              _buildFormField(
                                controller: _firstNameController,
                                label: 'First Name',
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'First name is required';
                                  if (value.length < 2) {
                                    return 'First name must be at least 2 characters';
                                  }
                                  if (!RegExp(r'^[a-zA-Z\s-]+').hasMatch(value)) {
                                    return 'First name can only contain letters, spaces, and hyphens';
                                  }
                                  return null;
                                },
                              ),
                              
                              // Last Name
                              _buildFormField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Last name is required';
                                  if (value.length < 2) {
                                    return 'Last name must be at least 2 characters';
                                  }
                                  if (!RegExp(r'^[a-zA-Z\s-]+').hasMatch(value)) {
                                    return 'Last name can only contain letters, spaces, and hyphens';
                                  }
                                  return null;
                                },
                              ),
                              
                              // Phone Number
                              _buildFormField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Phone number is required';
                                  final phoneRegex = RegExp(r'^[0-9]{9,15}$');
                                  if (!phoneRegex.hasMatch(value)) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              
                              // University (searchable dropdown)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: DropdownSearch<String>(
                                  items: (f, cs) => _universities,
                                  selectedItem: _selectedUniversity,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'University is required';
                                    }
                                    return null;
                                  },
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Search for a university',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'University',
                                      hintText: 'Select a university',
                                      labelStyle: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                      floatingLabelStyle: const TextStyle(
                                        color: AppColors.primary,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.error),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUniversity = value;
                                      _universityController.text = value ?? '';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                              : Text(
                                  'SAVE CHANGES',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: ModernBottomNav(
        selectedIndex: 3,
        onTabChanged: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil('/student-dashboard', (route) => false, arguments: 0);
              break;
            case 1:
              Navigator.of(context).pushNamedAndRemoveUntil('/student-dashboard', (route) => false, arguments: 1);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil('/student-dashboard', (route) => false, arguments: 2);
              break;
            case 3:
              Navigator.of(context).pushNamedAndRemoveUntil('/student-dashboard', (route) => false, arguments: 3);
              break;
          }
        },
      ),
    );
  }
}
