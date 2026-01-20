// student_signup.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palevel/config.dart';
import '../services/user_session_service.dart';
import 'package:dropdown_search/dropdown_search.dart';


class SignUpStudent extends StatefulWidget {
  const SignUpStudent({super.key});

  @override
  State<SignUpStudent> createState() => _SignUpStudentState();
}

class _SignUpStudentState extends State<SignUpStudent> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

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
  String? _selectedYear;
  String? _selectedUniversity;
  bool _isSubmitting = false;
  bool _hasSubmitAttempted = false;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _selectedGender; // This will hold the chosen gender
  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say'];

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Postgraduate'];
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
                    offset: Offset(logoSize * 0.4, -logoSize * 0.4),
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
                                  "Fill in your student details and we'll have you all set",
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
                                          _buildSection("University/College details", _buildAcademicDetails(screenWidth)),
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
                                        if (_currentStep > 0 && _currentStep < 2)
                                          const SizedBox(width: 16),
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
        const SizedBox(height: 16), // Add some spacing

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07746B).withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              hintText: 'Select gender',
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF07746B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF07746B),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black),
            items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your gender';
              }
              return null;
            },
          ),
        ),



        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: _buildField(
              label: 'Date of Birth *',
              controller: TextEditingController(
                text: _selectedDate == null
                    ? ''
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
              focusNode: null,
              icon: Icons.calendar_today,
              screenWidth: screenWidth,
              error: _hasSubmitAttempted ? _validateDateOfBirth(_selectedDate) : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Phone Number *',
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

  Widget _buildAcademicDetails(double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildField(
          label: 'Email *',
          controller: _emailController,
          focusNode: _emailFocus,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          screenWidth: screenWidth,
          error: _hasSubmitAttempted ? _validateEmail(_emailController.text) : null,
          onChanged: (value) {
            setState(() {});
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        DropdownSearch<String>(
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
              labelText: "University",
              hintText: "Select a university",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.school),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _selectedUniversity = value;
            });
          },
          selectedItem: _selectedUniversity,
        ),
        const SizedBox(height: 16),
        Container(
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
            decoration: _dropdownDecoration('Year of Study', screenWidth),
            icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF07746B), size: (screenWidth * 0.055).clamp(18.0, 22.0)),
            items: _years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year, style: TextStyle(fontSize: (screenWidth * 0.038).clamp(13.0, 15.0))),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedYear = value),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection(double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildField(
          label: 'Password',
          controller: _passwordController,
          focusNode: _passwordFocus,
          icon: Icons.lock_outline,
          obscure: true,
          showVisibility: true,
          screenWidth: screenWidth,
          onChanged: (v) {
            setState(() {
              _passwordError = _validatePassword(v);
              if (_confirmPasswordController.text.isNotEmpty) {
                _confirmPasswordError = _validateConfirmPassword(
                  _passwordController.text,
                  _confirmPasswordController.text,
                );
              }
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Builder(
            builder: (context) {
              final pwd = _passwordController.text;
              final errorFontSize = (screenWidth * 0.028).clamp(9.0, 11.0);
              if (pwd.isEmpty) {
                return Text(
                  '*Must contain at least 8 characters, one uppercase, one lowercase, one symbol, and one number.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: errorFontSize, fontFamily: 'Roboto'),
                  maxLines: 2,
                );
              }
              if (_passwordError != null) {
                return Text(_passwordError!, style: TextStyle(color: Colors.red, fontSize: errorFontSize, fontFamily: 'Roboto'));
              }
              return Text('Strong password', style: TextStyle(color: const Color(0xFF2E7D32), fontSize: errorFontSize, fontFamily: 'Roboto'));
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          icon: Icons.lock_outline,
          obscure: true,
          showVisibility: true,
          screenWidth: screenWidth,
          onChanged: (v) {
            setState(() {
              _confirmPasswordError = _validateConfirmPassword(_passwordController.text, v);
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Builder(
            builder: (context) {
              final confirm = _confirmPasswordController.text;
              final errorFontSize = (screenWidth * 0.028).clamp(9.0, 11.0);
              if (confirm.isEmpty) return const SizedBox.shrink();
              if (_confirmPasswordError != null) {
                return Text(_confirmPasswordError!, style: TextStyle(color: Colors.red, fontSize: errorFontSize, fontFamily: 'Roboto'));
              }
              return Text('Passwords match', style: TextStyle(color: const Color(0xFF2E7D32), fontSize: errorFontSize, fontFamily: 'Roboto'));
            },
          ),
        ),
      ],
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

  InputDecoration _dropdownDecoration(String label, double screenWidth) {
    final fontSize = (screenWidth * 0.038).clamp(13.0, 15.0);
    final iconSize = (screenWidth * 0.05).clamp(18.0, 20.0);

    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      hintText: label,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: fontSize),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF07746B).withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.school_outlined, color: const Color(0xFF07746B), size: iconSize),
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

  // Add these new validation methods
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
    if (value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^[+]?[0-9]{10,15}$');
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

  String? _validateUniversity(String? value) {
    if (value == null || value.isEmpty) return 'Please select your university';
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.isEmpty) return 'Please select your year of study';
    return null;
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

  Future<void> _submit() async {
    // Set submit attempt flag to show validation errors
    setState(() => _hasSubmitAttempted = true);
    
    // Store the context in a local variable before any async operations
    final currentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
    
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
    final universityError = _validateUniversity(_selectedUniversity);
    final yearError = _validateYear(_selectedYear);
    _passwordError = _validatePassword(password);
    _confirmPasswordError = _validateConfirmPassword(password, confirmPassword);
    
    // Show first error if any and focus on the corresponding field
    final errors = {
      'First name': firstNameError,
      'Last name': lastNameError,
      'Email': emailError,
      'Phone': phoneError,
      'Date of birth': dobError,
      'University': universityError,
      'Year of study': yearError,
      'Password': _passwordError,
      'Confirm password': _confirmPasswordError,
    }..removeWhere((key, value) => value == null);

    if (errors.isNotEmpty) {
      if (!mounted) return;
      // Show first error
      final firstError = errors.values.first;
      scaffoldMessenger.showSnackBar(
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
        
        if (focusNode != null && focusNode.context != null) {
          // Scroll to the field first, then focus
          try {
            Scrollable.ensureVisible(
              focusNode.context!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ).then((_) {
              if (mounted) {
                focusNode?.requestFocus();
              }
            });
          } catch (e) {
            // If scrolling fails, just try to focus
            if (mounted) {
              focusNode.requestFocus();
            }
          }
        }
      });
      
      setState(() {});
      return;
    }

    _passwordError = _validatePassword(password);
    _confirmPasswordError = _validateConfirmPassword(password, confirmPassword);

    if (_passwordError != null || _confirmPasswordError != null) {
      setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final body = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'phone_number': phone,
        'date_of_birth': _selectedDate!.toIso8601String().split('T').first,
        'year_of_study': _selectedYear,
        'university': _selectedUniversity,
        'user_type': 'tenant',
        'gender': _selectedGender,
      };

      final response = await http.post(
        Uri.parse('$kBaseUrl/create_user/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await UserSessionService.saveUserEmail(email);
        if (_selectedUniversity != null && _selectedUniversity!.isNotEmpty) {
          await UserSessionService.saveUniversity(_selectedUniversity!);
        }

        if (!mounted) return;
        Navigator.of(context).pushNamed(
          '/otp-verification',
          arguments: {'email': email, 'userType': 'tenant'},
        );
      } else {
        String msg = 'Signup failed. Please try again.';
        try {
          final err = jsonDecode(response.body);
          if (err['detail'] is String && err['detail'].contains('Email')) {
            msg = 'Email already in use.';
          }
        } catch (_) {}
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
