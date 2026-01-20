// signup.dart
import 'package:flutter/material.dart';
import '../services/oauth_service.dart';
import '../services/user_session_service.dart';

class SignUp1 extends StatelessWidget {
  const SignUp1({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    
    // Responsive sizing
    final horizontalPadding = (screenWidth * 0.08).clamp(16.0, 32.0);
    final topPadding = (screenHeight * 0.1).clamp(60.0, 80.0);
    final introFontSize = (screenWidth * 0.05).clamp(16.0, 20.0);
    final signUpFontSize = (screenWidth * 0.11).clamp(32.0, 45.0);
    final questionFontSize = (screenWidth * 0.2).clamp(50.0, 80.0);
    final roleQuestionFontSize = (screenWidth * 0.087).clamp(24.0, 35.0);
    final logoSize = (screenWidth * 0.65).clamp(180.0, 260.0);
    
    // Small screen optimization
    final isSmallScreen = screenHeight < 600;
    final optimizedHorizontalPadding = isSmallScreen ? 16.0 : horizontalPadding;
    final optimizedTopPadding = isSmallScreen ? 20.0 : topPadding.clamp(20.0, 80.0);
    final optimizedIntroFontSize = isSmallScreen ? 14.0 : introFontSize;
    final optimizedSignUpFontSize = isSmallScreen ? 24.0 : signUpFontSize;
    final optimizedRoleQuestionFontSize = isSmallScreen ? 18.0 : roleQuestionFontSize;
    final optimizedLogoSize = isSmallScreen ? 120.0 : logoSize;
    final spacing = isSmallScreen ? 8.0 : 16.0;
    final smallSpacing = isSmallScreen ? 6.0 : 12.0;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),
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
          child: Stack(
            children: [
              // Bottom decorative logo (painted BEHIND content)
              if (screenWidth > 300)
                IgnorePointer(
                  ignoring: true,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Transform.translate(
                      offset: Offset(optimizedLogoSize * 0.02, -optimizedLogoSize * 0.02),
                      child: Transform.rotate(
                        angle: 0, // ~40 degrees
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: SizedBox(
                            width: optimizedLogoSize,
                            height: optimizedLogoSize,
                            child: Image.asset(
                              'lib/assets/images/PaLevel Logo-White.png',
                              width: optimizedLogoSize * 0.5,
                              height: optimizedLogoSize * 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Main content (in front of decoration)
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: optimizedHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: optimizedTopPadding),

                    // "Let's get you signed up..."
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Text(
                        "Let's get you signed up\nfor your next level up!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: optimizedIntroFontSize,
                          fontFamily: 'Anta',
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),

                    SizedBox(height: smallSpacing),

                    // "Sign up"
                    Text(
                      'Sign up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF07746B),
                        fontSize: optimizedSignUpFontSize,
                        fontFamily: 'Anta',
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: spacing),

                    // "Would you like to sign up as a"
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Text(
                        'Would you like\nto sign up as a',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: optimizedRoleQuestionFontSize,
                          fontFamily: 'Anta',
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),

                    SizedBox(height: spacing),

                    // Student & Landlord buttons - always side by side with ? in between
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: _roleButton(
                            context,
                            label: 'Student',
                            onTap: () => Navigator.pushNamed(context, '/student-signup'),
                            screenWidth: screenWidth,
                          ),
                        ),
                        SizedBox(width: smallSpacing),
                        Text(
                          '?',
                          style: TextStyle(
                            color: const Color(0xFF07746B),
                            fontSize: isSmallScreen ? 32.0 : questionFontSize,
                            fontFamily: 'Anta',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: smallSpacing),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _roleButton(
                            context,
                            label: 'Landlord',
                            onTap: () => Navigator.pushNamed(context, '/landlord-signup'),
                            screenWidth: screenWidth,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: spacing),

                    // Divider with "OR" text
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: smallSpacing),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isSmallScreen ? 12.0 : (screenWidth * 0.04).clamp(14.0, 16.0),
                              fontFamily: 'Anta',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: spacing),

                    // Google Sign-In section
                    Text(
                      'Sign up with Google',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isSmallScreen ? 14.0 : (screenWidth * 0.045).clamp(16.0, 18.0),
                        fontFamily: 'Anta',
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: smallSpacing),

                    // Google Sign-In buttons for Student and Landlord
                    Column(
                      children: [
                        _googleSignInButton(
                          context,
                          label: 'Continue as Student',
                          userType: 'tenant',
                          screenWidth: screenWidth,
                        ),
                        SizedBox(height: smallSpacing),
                        _googleSignInButton(
                          context,
                          label: 'Continue as Landlord',
                          userType: 'landlord',
                          screenWidth: screenWidth,
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 20.0 : 30.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(BuildContext context, {required String label, required VoidCallback onTap, required double screenWidth}) {
    final fontSize = (screenWidth * 0.055).clamp(16.0, 21.0);
    final horizontalPadding = (screenWidth * 0.08).clamp(22.0, 30.0);
    final verticalPadding = (screenWidth * 0.032).clamp(10.0, 14.0);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF07746B),
          borderRadius: BorderRadius.circular(30),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontFamily: 'Anta',
              fontWeight: FontWeight.w500,
            ),
            softWrap: false,
          ),
        ),
      ),
    );
  }

  Widget _googleSignInButton(BuildContext context, {required String label, required String userType, required double screenWidth}) {
    final fontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
    final horizontalPadding = (screenWidth * 0.06).clamp(20.0, 28.0);
    final verticalPadding = (screenWidth * 0.03).clamp(12.0, 16.0);
    
    return GestureDetector(
      onTap: () => _handleGoogleSignIn(context, userType),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFF34A853)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google Logo
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontFamily: 'Anta',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, String userType) async {
    try {
      final oauthService = OAuthService();
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Authenticate with Google
      final result = await oauthService.authenticateWithGoogle();
      
      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Check if user needs role selection or is already complete
      if (result['needsRoleSelection'] == true) {
        // Navigate to appropriate completion screen
        if (userType == 'tenant') {
          if (context.mounted) {
            Navigator.of(context).pushNamed(
              '/oauth-student-completion',
              arguments: {
                'temporaryToken': result['temporaryToken'],
                'googleUserData': result['firebaseUser'],
              },
            );
          }
        } else {
          if (context.mounted) {
            Navigator.of(context).pushNamed(
              '/oauth-landlord-completion',
              arguments: {
                'temporaryToken': result['temporaryToken'],
                'googleUserData': result['firebaseUser'],
              },
            );
          }
        }
      } else {
        // User already exists and has role, save session and navigate to appropriate dashboard
        await UserSessionService.saveSession(
          result['token'],
          result['user'],
        );
        
        if (context.mounted) {
          // Navigate to appropriate dashboard based on user type
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
    } catch (e) {
      // Close loading indicator if open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
