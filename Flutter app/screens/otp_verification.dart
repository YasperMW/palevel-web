// otp_verification.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/user_session_service.dart';
import '../services/api_service.dart';

class OtpVerification extends StatefulWidget {
  const OtpVerification({super.key});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  // ──────────────────────────────────────────────────────────────
  // Controllers & focus
  // ──────────────────────────────────────────────────────────────
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // ──────────────────────────────────────────────────────────────
  // State
  // ──────────────────────────────────────────────────────────────
  bool _isVerifying = false;
  bool _isResending = false;
  bool _canResend = true;
  int _resendSeconds = 30;
  Timer? _resendTimer;
  String? _email;
  String? _userType; // 'tenant' or 'landlord'
  bool _initialized = false;

  // ──────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _email = args['email'] as String?;
        _userType = args['userType'] as String? ?? 'tenant';
      }
      // Automatically send OTP once when arriving from unverified login
      _resendOtp(ignoreFlags: true);
      _startResendCountdown();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // Resend timer
  // ──────────────────────────────────────────────────────────────
  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _canResend = false;
      _resendSeconds = 30;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _canResend = true);
        t.cancel();
      }
    });
  }

  Future<void> _resendOtp({bool ignoreFlags = false}) async {
    if (!ignoreFlags && (!_canResend || _isResending)) return;
    setState(() => _isResending = true);

    try {
      final resp = await http.post(
        Uri.parse('$kBaseUrl/send-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email}),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New code sent.')));
        if (!ignoreFlags) {
          _startResendCountdown();
        }
      } else {
        String msg = 'Failed to resend.';
        try {
          final err = jsonDecode(resp.body);
          msg = err['detail'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error.')));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    setState(() => _isVerifying = true);
    try {
      final resp = await http.post(
        Uri.parse('$kBaseUrl/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email, 'otp': otp}),
      );

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final responseData = jsonDecode(resp.body);
        final token = responseData['token'];
        final userData = responseData['user'];

        if (token != null && userData != null) {
          // Save the session using UserSessionService
          await UserSessionService.saveUserSession(
            email: userData['email'],
            token: token,
            userId: userData['user_id'],
            userType: userData['user_type'] ?? _userType ?? 'tenant',
          );

          // Save additional user data
          final user = User(
            userId: userData['user_id'],
            email: userData['email'],
            userType: userData['user_type'] ?? _userType ?? 'tenant',
            firstName: userData['first_name'],
            lastName: userData['last_name'],
            phoneNumber: userData['phone_number'],
            isVerified: userData['is_verified'] ?? true,
            isBlacklisted: false,
            university: userData['university'],
          );
          await UserSessionService.saveUserData(user);

          // Navigate to the appropriate dashboard
          final route = userData['user_type'] == 'landlord'
              ? '/landlord-dashboard'
              : '/student-dashboard';

          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            route,
            (route) => false, // Remove all previous routes
          );
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        String msg = 'OTP verification failed.';
        try {
          final err = jsonDecode(resp.body);
          msg = err['detail'] ?? msg;
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error.')));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Responsive sizing
    final horizontalPadding = (screenWidth * 0.075).clamp(16.0, 30.0);
    final topPadding = (screenHeight * 0.08).clamp(40.0, 60.0);
    final titleFontSize = (screenWidth * 0.07).clamp(20.0, 28.0);
    final otpTitleFontSize = (screenWidth * 0.06).clamp(18.0, 24.0);
    final bodyFontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
    final otpBoxSize = (screenWidth * 0.12).clamp(40.0, 48.0);
    final otpBoxHeight = (screenHeight * 0.07).clamp(50.0, 58.0);
    final logoSize = (screenWidth * 0.65).clamp(180.0, 260.0);

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
              // ───── Rotated logo (bottom-left) - hide on very small screens ─────
              if (screenWidth > 300)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Transform.translate(
                    offset: Offset(-logoSize * 0.3, logoSize * 0.3),
                    child: Transform.rotate(
                      angle: 0.698, // ~40 degrees
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
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topPadding),

                    Text(
                      "Almost done! Let's just\nverify your information.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        fontFamily: 'Anta',
                      ),
                    ),

                    SizedBox(height: (screenHeight * 0.04).clamp(20.0, 32.0)),

                    Center(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom * 0.6,
                        ),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 500),
                          padding: EdgeInsets.all((screenWidth * 0.07).clamp(20.0, 28.0)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular((screenWidth * 0.08).clamp(24.0, 32.0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'OTP Verification',
                                style: TextStyle(
                                  color: const Color(0xFF07746B),
                                  fontSize: otpTitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Anta',
                                ),
                              ),

                              SizedBox(height: (screenHeight * 0.015).clamp(10.0, 16.0)),

                              Text(
                                'We have sent a 6-digit code to your email address:',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: bodyFontSize,
                                  height: 1.3,
                                  fontFamily: 'Roboto',
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                _email ?? 'example@example.com',
                                style: TextStyle(
                                  color: const Color(0xFF07746B),
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 8),

                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Wrong email address? Change email address',
                                  style: TextStyle(
                                    color: const Color(0xFF07746B),
                                    fontSize: (screenWidth * 0.037).clamp(12.0, 15.0),
                                    decoration: TextDecoration.underline,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),

                              SizedBox(height: (screenHeight * 0.03).clamp(18.0, 24.0)),

                              Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(6, (i) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: SizedBox(
                                          width: otpBoxSize,
                                          height: otpBoxHeight,
                                          child: TextField(
                                            controller: _otpControllers[i],
                                            focusNode: _focusNodes[i],
                                            autofocus: i == 0,
                                            maxLength: 1,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: (screenWidth * 0.06).clamp(18.0, 24.0),
                                              color: Colors.black,
                                              fontFamily: 'Roboto',
                                            ),
                                            decoration: InputDecoration(
                                              counterText: '',
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: const Color(0xFF07746B).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: const Color(0xFF07746B).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF07746B),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) {
                                              if (v.length == 1 && i < 5) {
                                                _focusNodes[i + 1].requestFocus();
                                              } else if (v.isEmpty && i > 0) {
                                                _focusNodes[i - 1].requestFocus();
                                              }
                                              if (i == 5 && v.length == 1) _verifyOtp();
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),

                              SizedBox(height: (screenHeight * 0.035).clamp(20.0, 28.0)),

                              SizedBox(
                                width: double.infinity,
                                height: (screenHeight * 0.065).clamp(45.0, 50.0),
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _verifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0DDAC9),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isVerifying
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Submit',
                                          style: TextStyle(
                                            fontSize: (screenWidth * 0.045).clamp(16.0, 18.0),
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                ),
                              ),

                              SizedBox(height: (screenHeight * 0.03).clamp(18.0, 24.0)),

                              Center(
                                child: GestureDetector(
                                  onTap: _canResend && !_isResending ? _resendOtp : null,
                                  child: Text(
                                    _canResend
                                        ? 'Resend code'
                                        : 'Resend in $_resendSeconds s',
                                    style: TextStyle(
                                      color: const Color(0xFF07746B),
                                      fontSize: (screenWidth * 0.037).clamp(13.0, 15.0),
                                      decoration: TextDecoration.underline,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}