
import 'package:shared_preferences/shared_preferences.dart';
import '../app_navigator.dart';

class AuthHelper {
  /// Clear stored session and navigate to login when an unauthorized response is received.
  static Future<void> handleUnauthorized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_token');
      await prefs.remove('user_id');
      await prefs.remove('user_type');
      await prefs.remove('selected_university');
      await prefs.remove('user_data');
    } catch (_) {
      // ignore
    }

    // Use navigatorKey to clear navigation stack and go to login
    try {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      // ignore navigation errors
    }
  }
}
