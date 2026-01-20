// auth_checker.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/user_session_service.dart';

class AuthCheckerPage extends StatefulWidget {
  const AuthCheckerPage({super.key});

  @override
  State<AuthCheckerPage> createState() => _AuthCheckerPageState();
}

class _AuthCheckerPageState extends State<AuthCheckerPage> {
  @override
  void initState() {
    super.initState();
    // Delay authentication check to avoid blocking main thread
    Future.delayed(const Duration(milliseconds: 100), _checkAuthenticationAndNavigate);
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    // Check if user has an active session
    final hasActiveSession = await UserSessionService.hasUserSession();
    
    if (hasActiveSession) {
      // User is already logged in, navigate to appropriate dashboard
      final userType = await UserSessionService.getUserType();
      _navigateToDashboard(userType);
    } else {
      // Check for remembered credentials
      final hasRememberedCreds = await UserSessionService.hasRememberMeCredentials();
      
      if (hasRememberedCreds) {
        // Auto-authenticate with remembered credentials
        await _autoAuthenticate();
      } else {
        // No remembered credentials, go to login
        _goToLogin();
      }
    }
  }

  Future<void> _autoAuthenticate() async {
    try {
      final credentials = await UserSessionService.getRememberMeCredentials();
      final email = credentials['email'];
      final password = credentials['password'];

      if (email != null && password != null) {
        final response = await http.post(
          Uri.parse('$kBaseUrl/authenticate/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          final userType = (data['user_type'] as String?) ?? 'tenant';
          final isVerified = (data['is_verified'] as bool?) ?? false;

          if (!isVerified) {
            // If not verified, go to login
            _goToLogin();
            return;
          }

          // Save user session
          await UserSessionService.saveUserSession(
            email: email,
            userId: data['user_id']?.toString(),
            userType: userType,
          );

          // Navigate to appropriate dashboard
          _navigateToDashboard(userType);
          return;
        }
      }
    } catch (e) {
      // Auto-authentication failed, clear credentials and go to login
      await UserSessionService.clearRememberMeCredentials();
    }
    
    // If we reach here, auto-authentication failed
    _goToLogin();
  }

  void _navigateToDashboard(String? userType) {
    if (!mounted) return;
    
    final route = userType == 'landlord'
        ? '/landlord-dashboard'
        : '/student-dashboard';
    
    Navigator.pushReplacementNamed(context, route);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // This page is completely invisible - no UI at all
    return const SizedBox.shrink();
  }
}
