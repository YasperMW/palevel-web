import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/oauth_service.dart';
import '../services/user_session_service.dart';

class OAuthStudentCompletion extends StatefulWidget {
  final String temporaryToken;
  final Map<String, dynamic> googleUserData;

  const OAuthStudentCompletion({
    super.key,
    required this.temporaryToken,
    required this.googleUserData,
  });

  @override
  State<OAuthStudentCompletion> createState() => _OAuthStudentCompletionState();
}

class _OAuthStudentCompletionState extends State<OAuthStudentCompletion> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _phoneController = TextEditingController();


  DateTime? _selectedDate;
  String? _selectedYear;
  String? _selectedUniversity;
  String? _selectedGender;

  bool _isSubmitting = false;

  final _oauthService = OAuthService();
  
  // OAuth data from route arguments
  late String _temporaryToken;
  late Map<String, dynamic> _googleUserData;

  final List<String> _years = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', 'Postgraduate'
  ];

  final List<String> _genders = [
    'male', 'female', 'other', 'prefer_not_to_say'
  ];

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
    "K & M School of Accountancy (KM)"
  ];

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
                    'Complete your student profile',
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
            'Student Information',
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
                _buildSection("Personal details", _buildPersonalDetails(screenWidth, isSmallScreen, smallSpacing)),
                _buildSection("University/College details", _buildAcademicDetails(screenWidth, isSmallScreen, smallSpacing)),
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

  Widget _buildPersonalDetails(double screenWidth, bool isSmallScreen, double smallSpacing) {
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
        SizedBox(height: smallSpacing),
        
        // Date of Birth
        _buildDateField(screenWidth),
        SizedBox(height: smallSpacing),
        
        // Gender
        _buildGenderDropdown(screenWidth),
      ],
    );
  }

  Widget _buildAcademicDetails(double screenWidth, bool isSmallScreen, double smallSpacing) {
    return Column(
      children: [
        // University Dropdown
        _buildUniversityDropdown(screenWidth),
        SizedBox(height: smallSpacing),
        
        // Year of Study Dropdown
        _buildYearDropdown(screenWidth),
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

  Widget _buildDateField(double screenWidth) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
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
          child: TextField(
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
              hintText: _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Date of Birth *',
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
                  Icons.calendar_today,
                  color: const Color(0xFF07746B),
                  size: (screenWidth * 0.05).clamp(18.0, 20.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityDropdown(double screenWidth) {
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
      child: DropdownSearch<String>(
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search for a university",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        items: (f, cs) => _universities,
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            labelText: "University *",
            hintText: "Select your university",
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
                Icons.school,
                color: const Color(0xFF07746B),
                size: (screenWidth * 0.05).clamp(18.0, 20.0),
              ),
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _selectedUniversity = value;
          });
        },
        selectedItem: _selectedUniversity,
      ),
    );
  }

  Widget _buildYearDropdown(double screenWidth) {
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
      child: DropdownButtonFormField<String>(
        initialValue: _selectedYear,
        decoration: InputDecoration(
          labelText: "Year of Study *",
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
              Icons.school_outlined,
              color: const Color(0xFF07746B),
              size: (screenWidth * 0.05).clamp(18.0, 20.0),
            ),
          ),
        ),
        items: _years.map((year) {
          return DropdownMenuItem(
            value: year,
            child: Text(
              year,
              style: TextStyle(fontSize: (screenWidth * 0.038).clamp(13.0, 15.0)),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedYear = value;
          });
        },
      ),
    );
  }

  Widget _buildGenderDropdown(double screenWidth) {
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
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        decoration: InputDecoration(
          labelText: "Gender *",
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
              Icons.person_outline,
              color: const Color(0xFF07746B),
              size: (screenWidth * 0.05).clamp(18.0, 20.0),
            ),
          ),
        ),
        items: _genders.map((gender) {
          return DropdownMenuItem(
            value: gender,
            child: Text(
              gender.replaceAll('_', ' ').split(' ').map((word) => 
                word[0].toUpperCase() + word.substring(1)
              ).join(' '),
              style: TextStyle(fontSize: (screenWidth * 0.038).clamp(13.0, 15.0)),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
      ),
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

  Future<void> _submit() async {
    // Validation
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required');
      return;
    }
    
    if (_selectedDate == null) {
      _showErrorSnackBar('Date of birth is required');
      return;
    }
    
    if (_selectedUniversity == null) {
      _showErrorSnackBar('University is required');
      return;
    }
    
    if (_selectedYear == null) {
      _showErrorSnackBar('Year of study is required');
      return;
    }
    
    if (_selectedGender == null) {
      _showErrorSnackBar('Gender is required');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _oauthService.completeRoleSelection(
        temporaryToken: _temporaryToken,
        userType: 'tenant',
        phoneNumber: _phoneController.text.trim(),
        university: _selectedUniversity,
        dateOfBirth: _selectedDate!.toIso8601String(),
        yearOfStudy: _selectedYear,
        gender: _selectedGender,
      );

      // Save user session
      await UserSessionService.saveSession(
        result['token'],
        result['user'],
      );

      // Navigate to student dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/student-dashboard');
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
