import '../services/auth_service.dart';
import '../services/user_session_service.dart';
import '../services/fcm_service.dart';
import '../services/oauth_service.dart';

class LoginController {
  final AuthService _authService = AuthService();
  final OAuthService _oauthService = OAuthService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final data = await _authService.login(email, password);
      
      final token = data['token'] as String;
      final user = (data['user'] as Map<String, dynamic>?) ?? {};
      final userType = (user['user_type'] as String?) ?? 'tenant';
      final isVerified = (user['is_verified'] as bool?) ?? false;

      if (!isVerified) {
        return {
          'success': true,
          'isVerified': false,
          'userType': userType,
          'email': email,
        };
      }

      await UserSessionService.saveUserSession(
        email: email,
        token: token,
        userId: user['user_id']?.toString(),
        userType: userType,
        userGender: user['gender']?.toString(),
      );

      final userUniversity = user['university']?.toString();
      if (userUniversity != null && userUniversity.isNotEmpty) {
        await UserSessionService.saveUniversity(userUniversity);
      }
      
      try {
        await FCMService().registerTokenWithCurrentUser();
      } catch (_) {}

      return {
        'success': true,
        'isVerified': true,
        'userType': userType,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final result = await _oauthService.authenticateWithGoogle();
      
      if (result['needsRoleSelection'] == true) {
        return {
          'success': true,
          'needsRoleSelection': true,
          'temporaryToken': result['temporaryToken'],
          'firebaseUser': result['firebaseUser'],
        };
      }
      
      // User exists and has role
      await UserSessionService.saveSession(
        result['token'],
        result['user'],
      );
      
      try {
        await FCMService().registerTokenWithCurrentUser();
      } catch (_) {}
      
      final userType = (result['user']['user_type'] as String?) ?? 'tenant';
      
      return {
        'success': true,
        'needsRoleSelection': false,
        'userType': userType,
      };

    } catch (e) {
        String errorStr = e.toString().toLowerCase();
        List<String> networkErrors = [
          'connection', 'network', 'timeout', 'unreachable', 
          'dns', 'host', 'resolve', 'socket', 'connection refused',
          'no internet', 'offline', 'network is unreachable',
          'socket exception', 'connection timeout'
        ];
        
        bool isNetworkError = networkErrors.any((error) => errorStr.contains(error));
        
        String errorMessage;
        if (isNetworkError) {
          errorMessage = 'No network connection. Please check your internet connection and try again.';
        } else {
          errorMessage = 'Google sign-in failed. Please try again.';
        }

       return {
         'success': false,
         'error': errorMessage,
       };
    }
  }
}
