// landlord_signup.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:palevel/config.dart';


class SignUpLandlord extends StatefulWidget {
  const SignUpLandlord({super.key});

  @override
  State<SignUpLandlord> createState() => _SignUpLandlordState();
}
enum PasswordStrength {
  weak,
  moderate,
  strong,
}
class _SignUpLandlordState extends State<SignUpLandlord> {
  final PageController _pageController = PageController();
  int _currentStep = 0;


 PasswordStrength _passwordStrength = PasswordStrength.weak;
  String? _passwordStrengthText;
  Color _passwordStrengthColor = Colors.red;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus nodes
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  DateTime? _selectedDate;
  File? _idImage;
  bool _isSubmitting = false;
  bool _hasSubmitAttempted = false;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Responsive sizing
    final horizontalPadding = (screenWidth * 0.075).clamp(16.0, 30.0);
    final titleFontSize = (screenWidth * 0.07).clamp(20.0, 28.0);
    final cardPadding = (screenWidth * 0.07).clamp(20.0, 28.0);
    final cardBorderRadius = (screenWidth * 0.08).clamp(24.0, 32.0);
    final logoSize = (screenWidth * 0.35).clamp(100.0, 150.0);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0DDAC9),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: _currentStep == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.canPop(context)
                    ? Navigator.pop(context)
                    : Navigator.pushReplacementNamed(context, '/signup'),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF07746B), Color(0xFF0DDAC9)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (screenWidth > 300)
                Align(
                  alignment: Alignment.topRight,
                  child: Transform.translate(
                    offset: Offset(logoSize * 0.3, -logoSize * 0.3),
                    child: Transform.rotate(
                      angle: -0.4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: SizedBox(
                          width: logoSize,
                          height: logoSize,
                          
                          child: Image.asset(
                            'lib/assets/images/PaLevel Logo-White.png',
                            width: logoSize * 0.5,
                            height: logoSize * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: screenWidth * 0.1, bottom: 20),
                                child: Text(
                                  "Fill in your details and we'll have you all set",
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Anta',
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(maxWidth: 500),
                                padding: EdgeInsets.all(cardPadding),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(cardBorderRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha:0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: screenHeight * 0.48,
                                      child: PageView(
                                        controller: _pageController,
                                        physics: const NeverScrollableScrollPhysics(),
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentStep = index;
                                          });
                                        },
                                        children: [
                                          _buildSection("Personal details", _buildPersonalDetails(screenWidth)),
                                          _buildSection("Verification", _buildVerificationDetails(screenWidth)),
                                          _buildSection("Password", _buildPasswordSection(screenWidth)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    if (_currentStep == 2) const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        if (_currentStep > 0)
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _prevStep,
                                              style: buttonStyle,
                                              child: const Text('Back'),
                                            ),
                                          ),
                                        if (_currentStep > 0 && _currentStep < 2) const SizedBox(width: 16),
                                        if (_currentStep < 2)
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _nextStep,
                                              style: buttonStyle,
                                              child: const Text('Next'),
                                            ),
                                          ),
                                        if (_currentStep == 2)
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _isSubmitting ? null : _submit,
                                              style: buttonStyle,
                                              child: _isSubmitting
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Text('Sign Up'),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF07746B),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: SingleChildScrollView(child: content)),
      ],
    );
  }

  Widget _buildPersonalDetails(double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       _buildField(
  label: 'First Name *',
  controller: _firstNameController,
  focusNode: _firstNameFocus,
  icon: Icons.person_outline,
  screenWidth: screenWidth,
  error: _hasSubmitAttempted ? _validateName(_firstNameController.text, 'First name') : null,
  onChanged: (value) {
    setState(() {});
  },
),
        const SizedBox(height: 16),
      _buildField(
  label: 'Last Name *',
  controller: _lastNameController,
  focusNode: _lastNameFocus,
  icon: Icons.person_outline,
  screenWidth: screenWidth,
  error: _hasSubmitAttempted ? _validateName(_lastNameController.text, 'Last name') : null,
  onChanged: (value) {
    setState(() {});
  },
),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: _buildField(
              label: 'Date of Birth',
              controller: TextEditingController(
                text: _selectedDate == null ? '' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
              focusNode: null,
              icon: Icons.calendar_today,
              screenWidth: screenWidth,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
  label: 'Phone Number',
  controller: _phoneController,
  focusNode: _phoneFocus,
  icon: Icons.phone_outlined,
  keyboardType: TextInputType.phone,
  screenWidth: screenWidth,
  error: _hasSubmitAttempted ? _validatePhone(_phoneController.text) : null,
  onChanged: (value) {
    setState(() {});
  },
),
      ],
    );
  }

  Widget _buildVerificationDetails(double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildField(
  label: 'Email Address *',
  controller: _emailController,
  focusNode: _emailFocus,
  icon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
  screenWidth: screenWidth,
  error: _hasSubmitAttempted ? _validateEmail(_emailController.text) : null,
  onChanged: (value) {
    setState(() {});
  },
),
        const SizedBox(height: 16),
        // Upload National ID
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF07746B).withValues(alpha:0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07746B).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFF07746B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _idImage == null
                              ? 'Upload a clear image of your National ID'
                              : 'ID document uploaded',
                          style: TextStyle(
                            color: _idImage == null 
                                ? Colors.grey.shade600 
                                : const Color(0xFF07746B),
                            fontSize: (screenWidth * 0.038).clamp(13.0, 15.0),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_idImage != null)
                          Text(
                            'Tap to change image',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: (screenWidth * 0.032).clamp(11.0, 13.0),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_idImage != null)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF07746B).withValues(alpha:0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _idImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

 Widget _buildPasswordSection(double screenWidth) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Password Field
      _buildField(
        label: 'Password',
        controller: _passwordController,
        focusNode: _passwordFocus,
        icon: Icons.lock_outline,
        obscure: true,
        showVisibility: true,
        screenWidth: screenWidth,
        onChanged: (value) {
          _updatePasswordStrength(value);
          setState(() {
            _passwordError = _validatePassword(value);
            if (_confirmPasswordController.text.isNotEmpty) {
              _confirmPasswordError = _validateConfirmPassword(
                _passwordController.text,
                _confirmPasswordController.text,
              );
            }
          });
        },
      ),

      // Password Strength Indicator
      if (_passwordController.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Strength indicator bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.grey[200],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: (_passwordStrength.index / (PasswordStrength.values.length - 1)) *
                          (MediaQuery.of(context).size.width - 32),
                      decoration: BoxDecoration(
                        color: _passwordStrengthColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Strength: ${_passwordStrengthText ?? ''}',
                    style: TextStyle(
                      color: _passwordStrengthColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_passwordController.text.isEmpty ? 0 : _passwordStrength.index + 1}/4 criteria',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Password requirements
              _buildRequirement('At least 8 characters', _passwordController.text.length >= 8),
              _buildRequirement('1 uppercase letter', _passwordController.text.contains(RegExp(r'[A-Z]'))),
              _buildRequirement('1 lowercase letter', _passwordController.text.contains(RegExp(r'[a-z]'))),
              _buildRequirement('1 number', _passwordController.text.contains(RegExp(r'[0-9]'))),
              _buildRequirement(
                '1 special character',
                _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ] else
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 16.0, right: 16.0),
          child: Text(
            'Must contain: 8+ characters, 1 uppercase, 1 lowercase, 1 number, 1 special character',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: (screenWidth * 0.028).clamp(9.0, 11.0),
            ),
            maxLines: 2,
          ),
        ),

      const SizedBox(height: 16),

      // Confirm Password Field
      _buildField(
        label: 'Confirm Password',
        controller: _confirmPasswordController,
        focusNode: _confirmPasswordFocus,
        icon: Icons.lock_outline,
        obscure: true,
        showVisibility: true,
        screenWidth: screenWidth,
        onChanged: (value) {
          setState(() {
            _confirmPasswordError = _validateConfirmPassword(_passwordController.text, value);
          });
        },
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6, left: 16.0, right: 16.0),
        child: Builder(
          builder: (context) {
            final confirm = _confirmPasswordController.text;
            final errorFontSize = (screenWidth * 0.028).clamp(9.0, 11.0);
            if (confirm.isEmpty) return const SizedBox.shrink();
            if (_confirmPasswordError != null) {
              return Text(
                _confirmPasswordError!,
                style: TextStyle(
                  color: Colors.red, 
                  fontSize: errorFontSize, 
                  fontFamily: 'Roboto'
                )
              );
            }
            return Text(
              'Passwords match',
              style: TextStyle(
                color: const Color(0xFF2E7D32), 
                fontSize: errorFontSize, 
                fontFamily: 'Roboto'
              )
            );
          },
        ),
      ),
    ],
  );
}
  Widget _buildRequirement(String text, bool isMet) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.grey,
            fontSize: 12,
            decoration: isMet ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildField({
  required String label,
  required TextEditingController controller,
  FocusNode? focusNode,
  required IconData icon,
  bool obscure = false,
  bool showVisibility = false,
  TextInputType keyboardType = TextInputType.text,
  ValueChanged<String>? onChanged,
  required double screenWidth,
  String? error,
  TextInputAction? textInputAction,
  ValueChanged<String>? onSubmitted,
  bool enabled = true,
  int? maxLines = 1,
}) {
  bool obscure0 = obscure;
  final fontSize = (screenWidth * 0.038).clamp(13.0, 15.0);
  final iconSize = (screenWidth * 0.05).clamp(18.0, 20.0);
  final hasError = error != null && error.isNotEmpty;

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: hasError 
                      ? Colors.red.withValues(alpha:0.1)
                      : const Color(0xFF07746B).withValues(alpha:0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: hasError 
                  ? Border.all(color: Colors.red.withValues(alpha:0.5), width: 1)
                  : null,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure0,
              keyboardType: keyboardType,
              onChanged: onChanged,
              enabled: enabled,
              maxLines: maxLines,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: fontSize,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF07746B),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.red.withValues(alpha:0.8),
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                ),
                hintText: label,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400, 
                  fontSize: fontSize,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, 
                  vertical: 18,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasError 
                        ? Colors.red.withValues(alpha:0.1)
                        : const Color(0xFF07746B).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: hasError ? Colors.red : const Color(0xFF07746B),
                    size: iconSize,
                  ),
                ),
                suffixIcon: showVisibility
                    ? Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07746B).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            obscure0 
                                ? Icons.visibility_off_outlined 
                                : Icons.visibility_outlined,
                            color: const Color(0xFF07746B), 
                            size: iconSize,
                          ),
                          onPressed: () => setState(() => obscure0 = !obscure0),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                error,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: (screenWidth * 0.028).clamp(11.0, 13.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4), // Add some spacing after the field
        ],
      );
    },
  );
}

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB
        
        if (fileSize > maxSize) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size must be less than 5MB')),
          );
          return;
        }
        
        // Check file type
        final ext = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only JPG and PNG images are allowed')),
          );
          return;
        }
        
        setState(() {
          _idImage = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }

void _updatePasswordStrength(String password) {
  int strength = 0;
  String message = 'Weak';
  Color color = Colors.red;

  if (password.length >= 8) strength++;
  if (password.contains(RegExp(r'[A-Z]'))) strength++;
  if (password.contains(RegExp(r'[a-z]'))) strength++;
  if (password.contains(RegExp(r'[0-9]'))) strength++;
  if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength++;

  switch (strength) {
    case 0:
    case 1:
      message = 'Weak';
      color = Colors.red;
      break;
    case 2:
      message = 'Moderate';
      color = Colors.orange;
      break;
    case 3:
      message = 'Good';
      color = Colors.lightGreen;
      break;
    case 4:
      message = 'Strong';
      color = Colors.green;
      break;
    case 5:
      message = 'Very Strong';
      color = Colors.green;
      break;
  }

  if (mounted) {
    setState(() {
      _passwordStrength = strength <= 1
          ? PasswordStrength.weak
          : strength <= 3
              ? PasswordStrength.moderate
              : PasswordStrength.strong;
      _passwordStrengthText = message;
      _passwordStrengthColor = color;
    });
  }
}

String? _validatePassword(String value) {
  if (value.isEmpty) return 'Password is required.';
  if (value.length < 8) return 'Password must be at least 8 characters.';
  if (!value.contains(RegExp(r'[A-Z]'))) return 'Include at least one uppercase letter.';
  if (!value.contains(RegExp(r'[a-z]'))) return 'Include at least one lowercase letter.';
  if (!value.contains(RegExp(r'[0-9]'))) return 'Include at least one number.';
  if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) return 'Include at least one symbol.';
  return null;
}

  String? _validateConfirmPassword(String p1, String p2) {
    if (p2.isEmpty) return 'Please confirm your password.';
    if (p1 != p2) return 'Passwords do not match.';
    return null;
  }


// Add these methods to the _SignUpLandlordState class

String? _validateName(String value, String fieldName) {
  if (value.isEmpty) return '$fieldName is required';
  if (value.length < 2) return '$fieldName must be at least 2 characters';
  if (!RegExp(r'^[a-zA-Z\s-]+$').hasMatch(value)) {
    return '$fieldName can only contain letters, spaces, and hyphens';
  }
  return null;
}

String? _validateEmail(String value) {
  if (value.isEmpty) return 'Email is required';
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
  return null;
}

String? _validatePhone(String value) {
  if (value.isEmpty) return null; // Phone is optional
  final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
  if (!phoneRegex.hasMatch(value)) return 'Please enter a valid phone number';
  return null;
}

String? _validateDateOfBirth(DateTime? date) {
  if (date == null) return 'Date of birth is required';
  final now = DateTime.now();
  final minAgeDate = DateTime(now.year - 18, now.month, now.day);
  if (date.isAfter(minAgeDate)) return 'You must be at least 18 years old';
  return null;
}

 Future<void> _submit() async {
  // Set submit attempt flag to show validation errors
  setState(() => _hasSubmitAttempted = true);
  
  // Get field values
  final firstName = _firstNameController.text.trim();
  final lastName = _lastNameController.text.trim();
  final email = _emailController.text.trim();
  final phone = _phoneController.text.trim();
  final password = _passwordController.text;
  final confirmPassword = _confirmPasswordController.text;

  // Validate all fields
  final firstNameError = _validateName(firstName, 'First name');
  final lastNameError = _validateName(lastName, 'Last name');
  final emailError = _validateEmail(email);
  final phoneError = _validatePhone(phone);
  final dobError = _validateDateOfBirth(_selectedDate);
  _passwordError = _validatePassword(password);
  _confirmPasswordError = _validateConfirmPassword(password, confirmPassword);
  
  // Check ID image
  if (_idImage == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please upload a valid ID document')),
    );
    return;
  }

  // Show first error if any and focus on the corresponding field
  final errors = {
    'First name': firstNameError,
    'Last name': lastNameError,
    'Email': emailError,
    'Phone': phoneError,
    'Date of birth': dobError,
    'Password': _passwordError,
    'Confirm password': _confirmPasswordError,
  }..removeWhere((key, value) => value == null);

  if (errors.isNotEmpty) {
    if (!mounted) return;
    // Show first error
    final firstError = errors.values.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(firstError!)),
    );
    
    // Focus on the first error field - delay until after UI rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final firstErrorField = errors.keys.first;
      FocusNode? focusNode;
      
      switch (firstErrorField) {
        case 'First name':
          focusNode = _firstNameFocus;
          break;
        case 'Last name':
          focusNode = _lastNameFocus;
          break;
        case 'Email':
          focusNode = _emailFocus;
          break;
        case 'Phone':
          focusNode = _phoneFocus;
          break;
        case 'Date of birth':
          // Date picker will be opened when user taps the field
          break;
        case 'Password':
          focusNode = _passwordFocus;
          break;
        case 'Confirm password':
          focusNode = _confirmPasswordFocus;
          break;
      }
      
      if (focusNode != null) {
        // Try to focus first, then attempt scrolling
        if (mounted) {
          focusNode.requestFocus();
        }
        
        // Then try to scroll if context is available
        if (focusNode.context != null) {
          try {
            Scrollable.ensureVisible(
              focusNode.context!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } catch (e) {
            // Ignore scrolling errors, focus should still work
          }
        }
      }
    });
    
    setState(() {});
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/create_user_with_id/'));
    request.fields.addAll({
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone_number': phone,
      'date_of_birth': _selectedDate!.toIso8601String().split('T').first,
      'user_type': 'landlord',
    });
    
    request.files.add(await http.MultipartFile.fromPath('national_id_image', _idImage!.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (!mounted) return;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      Navigator.pushNamed(
        context,
        '/otp-verification',
        arguments: {'email': email, 'userType': 'landlord'},
      );
    } else {
      String msg = 'Signup failed. Please try again.';
      try {
        final err = jsonDecode(response.body);
        if (err['detail'] is String) {
          if (err['detail'].contains('Email')) {
            msg = 'Email already in use.';
          } else if (err['detail'].contains('phone')) {
            msg = 'Phone number is already registered.';
          }
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
}