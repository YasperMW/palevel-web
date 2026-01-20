// login.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/user_session_service.dart';
import '../controllers/login_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final LoginController _loginController = LoginController();

  bool _isSigningIn = false;
  bool _obscurePassword = true;
  AnimationController? _animationController;


  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _checkActiveSession();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );



    _animationController?.forward();
  }

  Future<void> _checkActiveSession() async {
    final hasActiveSession = await UserSessionService.hasUserSession();
    
    if (hasActiveSession) {
      // User is already logged in, navigate to appropriate dashboard
      final userType = await UserSessionService.getUserType();
      if (mounted) {
        final route = userType == 'landlord'
            ? '/landlord-dashboard'
            : '/student-dashboard';
        Navigator.pushReplacementNamed(context, route);
      }
    }
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter both email and password.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSigningIn = true);

    final result = await _loginController.login(email, password);

    if (!mounted) return;
    setState(() => _isSigningIn = false);

    if (result['success'] == true) {
      if (result['isVerified'] == false) {
        Navigator.pushNamed(
          context,
          '/otp-verification',
          arguments: {'email': email, 'userType': result['userType']},
        );
      } else {
        final route = result['userType'] == 'landlord'
            ? '/landlord-dashboard'
            : '/student-dashboard';
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Login failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }



  Future<void> _signInWithGoogle() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final result = await _loginController.loginWithGoogle();
      
    // Close loading indicator
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      if (result['needsRoleSelection'] == true) {
        // User exists but needs role selection - show role selection dialog
        await _showRoleSelectionDialog(result['temporaryToken'], result['firebaseUser']);
      } else {
        if (mounted) {
          // Navigate to appropriate dashboard based on user type
          final userType = (result['userType'] as String?) ?? 'tenant';
          if (userType == 'tenant') {
            Navigator.of(context).pushReplacementNamed('/student-dashboard');
          } else if (userType == 'landlord') {
            Navigator.of(context).pushReplacementNamed('/landlord-dashboard');
          } else {
            // Fallback for admin or other types
            Navigator.of(context).pushReplacementNamed('/student-dashboard');
          }
        }
      }
    } else {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Google sign-in failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
       }
    }
  }

  Future<void> _showRoleSelectionDialog(String temporaryToken, Map<String, dynamic> firebaseUser) async {
    String? selectedRole;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select Your Role'),
        content: const Text('Please select your role to continue:'),
        actions: [
          TextButton(
            onPressed: () {
              selectedRole = 'tenant';
              Navigator.of(context).pop();
            },
            child: const Text('Student'),
          ),
          TextButton(
            onPressed: () {
              selectedRole = 'landlord';
              Navigator.of(context).pop();
            },
            child: const Text('Landlord'),
          ),
        ],
      ),
    );

    if (selectedRole != null && mounted) {
      // Navigate to appropriate completion screen
      if (selectedRole == 'tenant') {
        Navigator.of(context).pushNamed(
          '/oauth-student-completion',
          arguments: {
            'temporaryToken': temporaryToken,
            'googleUserData': firebaseUser,
          },
        );
      } else {
        Navigator.of(context).pushNamed(
          '/oauth-landlord-completion',
          arguments: {
            'temporaryToken': temporaryToken,
            'googleUserData': firebaseUser,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.mainGradient,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;

              final isSmallScreen = screenHeight < 600;
              
              // Responsive padding based on screen size
              final horizontalPadding = isSmallScreen ? 16.0 : 24.0;
              final logoSize = isSmallScreen ? 40.0 : 60.0;
              final welcomeFontSize = isSmallScreen ? 24.0 : 32.0;
              final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
              final cardPadding = isSmallScreen ? 12.0 : 16.0;
              final buttonHeight = isSmallScreen ? 44.0 : 50.0;
              final spacing = isSmallScreen ? 8.0 : 12.0;
              final smallSpacing = isSmallScreen ? 6.0 : 8.0;
              
              return SingleChildScrollView(
                reverse: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha:0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Image.asset(
                                'lib/assets/images/PaLevel Logo-White.png',
                                height: logoSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 8.0 : 12.0),

                          // Welcome Text
                          Text(
                            'Welcome To Palevel!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: welcomeFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Anta',
                            ),
                          ),
                          SizedBox(height: smallSpacing),
                          Text(
                            'Find your accommodation with ease',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.9),
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12.0 : 20.0),
                          // Login Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(cardPadding),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha:0.1),
                                  blurRadius: isSmallScreen ? 20 : 30,
                                  offset: Offset(0, isSmallScreen ? 5 : 10),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Anta',
                                  ),
                                ),
                                SizedBox(height: spacing),

                                // Email Field
                                _buildModernTextField(
                                  label: 'Email or Phone Number',
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                SizedBox(height: smallSpacing),

                                // Password Field
                                _buildModernTextField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  icon: Icons.lock_outlined,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),

                                SizedBox(height: spacing),

                                // Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: AppColors.mainGradient,
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha:0.4),
                                          blurRadius: isSmallScreen ? 10 : 15,
                                          offset: Offset(0, isSmallScreen ? 3 : 5),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isSigningIn ? null : _signIn,
                                        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                        child: Center(
                                          child: _isSigningIn
                                              ? SizedBox(
                                                  width: isSmallScreen ? 20 : 24,
                                                  height: isSmallScreen ? 20 : 24,
                                                  child: const CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: smallSpacing),

                                // Forgot Password Link
                                Center(
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/password-reset-request'),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: smallSpacing),

                                // Divider with "OR" text
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: smallSpacing),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: isSmallScreen ? 12 : 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: smallSpacing),

                                // Google Sign-In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4285F4), Color(0xFF34A853)], // Google Brand Colors
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha:0.2),
                                          blurRadius: isSmallScreen ? 8 : 10,
                                          offset: Offset(0, isSmallScreen ? 1 : 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _signInWithGoogle,
                                        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Google Logo
                                              Container(
                                                width: isSmallScreen ? 20 : 24,
                                                height: isSmallScreen ? 20 : 24,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'G',
                                                    style: TextStyle(
                                                      color: const Color(0xFF4285F4),
                                                      fontSize: isSmallScreen ? 12 : 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: smallSpacing),
                                              Text(
                                                'Sign in with Google',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: spacing),

                                // Sign Up Link
                                Center(
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/signup'),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                        children: const [
                                          TextSpan(text: "Don't have an account? "),
                                          TextSpan(
                                            text: 'Sign Up',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Powered by Kernelsoft with logo in front of text
                          Container(
                            margin: const EdgeInsets.only(bottom: 0, top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha:0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Kernelsoft logo (increased size)
                                Image.asset(
                                  'lib/assets/images/KernelSoft-Logo-V1.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                // Text column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Powered by',
                                      style: TextStyle(
                                        color: AppColors.primary.withValues(alpha:0.8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    const Text(
                                      'Kernelsoft',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.primary
              : Colors.grey.shade200,
          width: focusNode.hasFocus ? 2 : 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: focusNode.hasFocus
                ? AppColors.primary
                : Colors.grey.shade600,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: focusNode.hasFocus
                ? AppColors.primary
                : Colors.grey.shade600,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
