import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config.dart';
import '../services/user_session_service.dart';
import '../services/auth_helper.dart';
import '../../services/websocket_service.dart';

import '../services/fcm_service.dart';
import 'package:http/http.dart' as http;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize heavy services in background
    _initializeServices();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // After animation completes, check stored token and verify with backend
    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _checkAndNavigate();
      }
    });
  }

  Future<void> _initializeServices() async {
    try {
      // ✅ Initialize WebSocket globally
      await WebSocketService().connect();

      // ✅ Initialize FCM independently
      await FCMService().initialize();
    } catch (e) {
      debugPrint('Service initialization error: $e');
    }
  }


  Future<void> _checkAndNavigate() async {
    try {
      final token = await UserSessionService.getUserToken();

      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.post(
        Uri.parse('$kBaseUrl/verify_token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userType = (data['user_type'] as String?) ?? 'tenant';

        // Save/update session
        await UserSessionService.saveUserSession(
          email: data['email'] as String? ?? '',
          token: token,
          userId: data['user_id']?.toString(),
          userType: userType,
        );

        final route = userType == 'landlord' ? '/landlord-dashboard' : '/student-dashboard';
        if (mounted) {
          Navigator.pushReplacementNamed(context, route);
        }
      } else {
        await AuthHelper.handleUnauthorized();
      }
    } on TimeoutException catch (_) {
      // Server is unreachable
      await AuthHelper.handleUnauthorized();
    } on SocketException catch (_) {
      // Network error
      await AuthHelper.handleUnauthorized();
    } catch (_) {
      // Any other exception
      await AuthHelper.handleUnauthorized();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;


    final logoSize = (screenWidth * 0.4).clamp(120.0, 180.0);
    final fontSize = (screenWidth * 0.08).clamp(24.0, 36.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07746B),
              Color(0xFF0DDAC9),
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: _goToLogin,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo with modern container
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha:0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha:0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha:0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'lib/assets/images/PaLevel Logo-White.png',
                                  width: logoSize,
                                  height: logoSize,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(height: 40),

                              // App Name
                              Text(
                                'PaLevel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontFamily: 'Anta',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha:0.2),
                                      offset: const Offset(0, 4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Tagline
                              Text(
                                'Find Your Perfect Home',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha:0.9),
                                  fontSize: (screenWidth * 0.045).clamp(16.0, 20.0),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              const SizedBox(height: 60),

                              // Loading indicator
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withAlpha(204), // 80% opacity (255 * 0.8 = 204)
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Powered by Kernelsoft with logo in front of text
                        Positioned(
                          bottom: 20,
                          child: Container(
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
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 10),
                                // Text column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Powered by',
                                      style: TextStyle(
                                        color: const Color(0xFF07746B).withValues(alpha:0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(
                                      'Kernelsoft',
                                      style: TextStyle(
                                        color: Color(0xFF07746B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
