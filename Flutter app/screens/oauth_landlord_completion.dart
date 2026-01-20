import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/oauth_service.dart';
import '../services/user_session_service.dart';

class OAuthLandlordCompletion extends StatefulWidget {
  final String temporaryToken;
  final Map<String, dynamic> googleUserData;

  const OAuthLandlordCompletion({
    super.key,
    required this.temporaryToken,
    required this.googleUserData,
  });

  @override
  State<OAuthLandlordCompletion> createState() => _OAuthLandlordCompletionState();
}

class _OAuthLandlordCompletionState extends State<OAuthLandlordCompletion> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _phoneController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  
  File? _nationalIdImage;
  bool _isSubmitting = false;
  
  // OAuth data from route arguments
  late String _temporaryToken;
  late Map<String, dynamic> _googleUserData;

  final _oauthService = OAuthService();
  
  @override
  void dispose() {
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract arguments from route and assign to class variables
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _temporaryToken = args?['temporaryToken'] as String? ?? '';
    _googleUserData = args?['googleUserData'] as Map<String, dynamic>? ?? {};
    
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final horizontalPadding = (screenWidth * 0.075).clamp(16.0, 30.0);
    final cardPadding = (screenWidth * 0.07).clamp(20.0, 28.0);
    final cardBorderRadius = (screenWidth * 0.08).clamp(24.0, 32.0);
    
    // Small screen optimization
    final isSmallScreen = screenHeight < 600;
    final optimizedHorizontalPadding = isSmallScreen ? 16.0 : horizontalPadding;
    final optimizedCardPadding = isSmallScreen ? 12.0 : cardPadding;
    final spacing = isSmallScreen ? 12.0 : 20.0;
    final smallSpacing = isSmallScreen ? 4.0 : 10.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: optimizedHorizontalPadding),
            child: Column(
              children: [
                SizedBox(height: smallSpacing),
                _buildGoogleUserInfo(isSmallScreen, smallSpacing),
                SizedBox(height: spacing - 2),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                SizedBox(height: spacing - 2),
                _buildFormCard(optimizedCardPadding, cardBorderRadius, screenWidth, isSmallScreen, spacing, smallSpacing),
                SizedBox(height: spacing - 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleUserInfo(bool isSmallScreen, double smallSpacing) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.9),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: isSmallScreen ? 8 : 10,
            offset: Offset(0, isSmallScreen ? 3 : 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(_googleUserData['photoUrl'] ?? ''),
            radius: isSmallScreen ? 32 : 40,
            backgroundColor: Colors.grey[300],
            child: _googleUserData['photoUrl'] == null
                ? Icon(Icons.person, size: isSmallScreen ? 32 : 40)
                : null,
          ),
          SizedBox(width: smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _googleUserData['displayName'] ?? 'Google User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF07746B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _googleUserData['email'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0DDAC9).withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Complete your landlord profile',
                    style: TextStyle(
                      color: Color(0xFF07746B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(double cardPadding, double cardBorderRadius, double screenWidth, bool isSmallScreen, double spacing, double smallSpacing) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: isSmallScreen ? 15 : 20,
            offset: Offset(0, isSmallScreen ? 5 : 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Landlord Information',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF07746B),
            ),
          ),
          SizedBox(height: smallSpacing),
          
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildSection("Contact details", _buildContactDetails(screenWidth, isSmallScreen, smallSpacing)),
                _buildSection("Identity verification", _buildIdentityVerification(screenWidth, isSmallScreen, smallSpacing)),
              ],
            ),
          ),
          
          SizedBox(height: spacing - 2),
          _buildNavigationButtons(isSmallScreen, screenWidth),
        ],
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF07746B),
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildContactDetails(double screenWidth, bool isSmallScreen, double smallSpacing) {
    return Column(
      children: [
        // Phone Number
        _buildField(
          'Phone Number *',
          _phoneController,
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          screenWidth: screenWidth,
        ),
      ],
    );
  }

  Widget _buildIdentityVerification(double screenWidth, bool isSmallScreen, double smallSpacing) {
    return Column(
      children: [
        // National ID Upload
        _buildNationalIdUpload(screenWidth),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isSmallScreen, double screenWidth) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: _prevStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: isSmallScreen ? 16 : 20),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_currentStep > 0)
          const SizedBox(width: 16),
        if (_currentStep < 1)
          Expanded(
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: isSmallScreen ? 16 : 20),
                ],
              ),
            ),
          ),
        if (_currentStep == 1)
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    required double screenWidth,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: (screenWidth * 0.038).clamp(13.0, 15.0),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
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
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: (screenWidth * 0.038).clamp(13.0, 15.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF07746B).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF07746B),
              size: (screenWidth * 0.05).clamp(18.0, 20.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNationalIdUpload(double screenWidth) {
    return GestureDetector(
      onTap: _pickNationalId,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _nationalIdImage != null 
                ? const Color(0xFF07746B)
                : const Color(0xFF07746B).withValues(alpha:0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF07746B).withValues(alpha:0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _nationalIdImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      _nationalIdImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF07746B)),
                        onPressed: _pickNationalId,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload National ID',
                    style: TextStyle(
                      fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select image',
                    style: TextStyle(
                      fontSize: (screenWidth * 0.032).clamp(11.0, 13.0),
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Required for verification',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: (screenWidth * 0.028).clamp(9.0, 11.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }


  Future<void> _pickNationalId() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
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
          _showErrorSnackBar('Image size must be less than 5MB');
          return;
        }
        
        // Check file type
        final ext = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          _showErrorSnackBar('Please select a valid image file (JPG, PNG)');
          return;
        }
        
        setState(() {
          _nationalIdImage = file;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    // Validation
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required');
      return;
    }
    
    if (_nationalIdImage == null) {
      _showErrorSnackBar('National ID image is required');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _oauthService.completeRoleSelection(
        temporaryToken: _temporaryToken,
        userType: 'landlord',
        phoneNumber: _phoneController.text.trim(),
        nationalIdImage: _nationalIdImage,
      );

      // Save user session
      await UserSessionService.saveSession(
        result['token'],
        result['user'],
      );

      // Navigate to landlord dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/landlord-dashboard');
      }
    } catch (e) {
      // Check for network connectivity errors
      String errorStr = e.toString().toLowerCase();
      List<String> networkErrors = [
        'connection', 'network', 'timeout', 'unreachable', 
        'dns', 'host', 'resolve', 'socket', 'connection refused',
        'no internet', 'offline', 'network is unreachable',
        'socket exception', 'connection timeout'
      ];
      
      bool isNetworkError = networkErrors.any((error) => errorStr.contains(error));
      
      // Show appropriate error message
      String errorMessage;
      if (isNetworkError) {
        errorMessage = 'No network connection. Please check your internet connection and try again.';
      } else {
        errorMessage = 'Failed to complete profile. Please try again.';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
