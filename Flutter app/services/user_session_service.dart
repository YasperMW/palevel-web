import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class UserSessionService {
  static const String _userEmailKey = 'user_email';
  static const String _userTokenKey = 'user_token';
  static const String _userIdKey = 'user_id';
  static const String _userGender = 'gender';
  static const String _universityKey = 'selected_university';
  static const String _userDataKey = 'user_data';
  static const String _userTypeKey = 'user_type';
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';


  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getString(_userIdKey);
    final userType = prefs.getString(_userTypeKey);
    final token = prefs.getString(_userTokenKey);

    if (userId == null || userType == null || token == null) {
      return null;
    }

    return {
      'user_id': userId,
      'user_type': userType,
      'token': token,
      'email': prefs.getString(_userEmailKey),
      'gender': prefs.getString(_userGender),
    };
  }

  // Add this method for WebSocket connection
  static Future<String?> getWebSocketAuthParams() async {
    final userData = await getCurrentUserData();
    if (userData == null) return null;

    final userId = userData['user_id'];
    final token = userData['token'];

    if (userId == null || token == null) return null;

    return 'user_id=$userId&token=$token';
  }

  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_userTokenKey);
    final userId = prefs.getString(_userIdKey);
    return token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
  }
  static Future<void> saveUserSession({
    required String email,
    String? token,
    String? userId,
    String? userType,
    String? userGender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    if (token != null) {
      await prefs.setString(_userTokenKey, token);
    }
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    if (userType != null) {
      await prefs.setString(_userTypeKey, userType);
    }
    if (userGender != null) {
      await prefs.setString(_userGender, userGender);
    }
  }

  // OAuth session saving method
  static Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    // Save token
    await prefs.setString(_userTokenKey, token);

    // Save user data
    if (user['email'] != null) {
      await prefs.setString(_userEmailKey, user['email']);
    }
    if (user['user_id'] != null) {
      await prefs.setString(_userIdKey, user['user_id'].toString());
    }
    if (user['user_type'] != null) {
      await prefs.setString(_userTypeKey, user['user_type']);
    }
    if (user['gender'] != null) {
      await prefs.setString(_userGender, user['gender']);
    }

    // Save complete user data as JSON for OAuth users
    final userJson = jsonEncode(user);
    await prefs.setString(_userDataKey, userJson);
  }

  static Future<void> saveUniversity(String university) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_universityKey, university);
  }

  static Future<String?> getUniversity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_universityKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  static Future<String?> getUserGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userGender);
  }

  static Future<bool> hasUserSession() async {
    final email = await getUserEmail();
    return email != null && email.isNotEmpty;
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_universityKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_userGender);
  }

  // User data caching methods
  static Future<void> saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode({
      'user_id': user.userId,
      'email': user.email,
      'user_type': user.userType,
      'first_name': user.firstName,
      'last_name': user.lastName,
      'phone_number': user.phoneNumber,
      'is_verified': user.isVerified,
      'is_blacklisted': user.isBlacklisted,
      'university': user.university,
      'gender':user.gender,
    });
    await prefs.setString(_userDataKey, userJson);
  }

  static Future<User?> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userDataKey);

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        await prefs.remove(_userDataKey);
        return null;
      }
    }
    return null;
  }

  static Future<void> clearCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  // Remember Me functionality
  static Future<void> saveRememberMeCredentials({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, true);
    await prefs.setString(_rememberedEmailKey, email);
    await prefs.setString(_rememberedPasswordKey, password);
  }

  static Future<Map<String, String?>> getRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isRememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (isRememberMe) {
      final email = prefs.getString(_rememberedEmailKey);
      final password = prefs.getString(_rememberedPasswordKey);
      return {
        'email': email,
        'password': password,
      };
    }

    return {'email': null, 'password': null};
  }

  static Future<bool> hasRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isRememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final email = prefs.getString(_rememberedEmailKey);
    final password = prefs.getString(_rememberedPasswordKey);

    return isRememberMe &&
        email != null && email.isNotEmpty &&
        password != null && password.isNotEmpty;
  }

  static Future<void> clearRememberMeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_rememberedEmailKey);
    await prefs.remove(_rememberedPasswordKey);
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
