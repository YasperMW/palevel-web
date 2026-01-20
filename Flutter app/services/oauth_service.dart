import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config.dart';

class OAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize Google Sign-In
  Future<void> initializeGoogleSignIn() async {
    await _googleSignIn.initialize();
  }

  /// Firebase Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure initialized
      await initializeGoogleSignIn();
      
      // Trigger authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Get authorization for required scopes
      final GoogleSignInClientAuthorization? authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email', 'openid']);
      
      if (authorization == null) {
        throw Exception('Failed to get authorization for Google Sign-In');
      }

      // Create a new credential using idToken from authentication
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: authorization.accessToken, // Use accessToken from authorization
      );

      // Sign in with credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Firebase Google sign-in failed: $e');
    }
  }

  /// Get Firebase ID Token for backend
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    return await user?.getIdToken();
  }

  /// Firebase Google Sign-In with backend integration
  Future<Map<String, dynamic>> authenticateWithGoogle() async {
    try {
      // Step 1: Sign in with Firebase
      final UserCredential? userCredential = await signInWithGoogle();
      
      if (userCredential == null) {
        throw Exception('Firebase sign-in failed');
      }

      // Step 2: Get Firebase ID token
      final String? idToken = await getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Step 3: Send Firebase token to backend
      final response = await http.post(
        Uri.parse('$kBaseUrl/auth/firebase/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'email': userCredential.user?.email,
          'display_name': userCredential.user?.displayName,
          'photo_url': userCredential.user?.photoURL,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - backend not responding');
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Backend authentication failed');
      }

      final backendData = jsonDecode(response.body);
      
      return {
        'firebaseUser': {
          'uid': userCredential.user?.uid,
          'email': userCredential.user?.email,
          'displayName': userCredential.user?.displayName,
          'photoUrl': userCredential.user?.photoURL,
        },
        'user': backendData['user'],
        'token': backendData['token'],
        'needsRoleSelection': backendData['needs_role_selection'] ?? false,
        'temporaryToken': backendData['temporary_token'],
      };
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
      
      if (isNetworkError) {
        throw Exception('No network connection. Please check your internet connection and try again.');
      } else {
        throw Exception('Authentication failed. Please try again.');
      }
    }
  }

  /// Complete role selection with additional user details
  Future<Map<String, dynamic>> completeRoleSelection({
    required String temporaryToken,
    required String userType,
    String? phoneNumber,
    String? university,
    String? dateOfBirth,
    String? yearOfStudy,
    String? gender,
    File? nationalIdImage,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'user_type': userType,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
      };

      if (userType == 'tenant') {
        requestBody['university'] = university;
        requestBody['year_of_study'] = yearOfStudy;
        requestBody['gender'] = gender;
      }

      // Handle national ID image upload for landlords
      if (userType == 'landlord' && nationalIdImage != null) {
        // Use multipart form request for file upload
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$kBaseUrl/auth/role-selection-with-id'),
        );
        
        // Add headers
        request.headers['Authorization'] = 'Bearer $temporaryToken';
        
        // Add form fields
        request.fields['user_type'] = userType;
        if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;
        
        // Add file
        request.files.add(await http.MultipartFile.fromPath('national_id_image', nationalIdImage.path));
        
        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseData = jsonDecode(response.body);
          return responseData;
        } else {
          throw Exception('Failed to complete role selection: ${response.body}');
        }
      }

      // Regular JSON request for tenants or landlords without ID image
      final response = await http.post(
        Uri.parse('$kBaseUrl/auth/role-selection'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $temporaryToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to complete role selection: ${response.body}');
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
      
      if (isNetworkError) {
        throw Exception('No network connection. Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to complete role selection. Please try again.');
      }
    }
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Check if user is currently signed in with Firebase
  Future<bool> isSignedIn() async {
    return _auth.currentUser != null;
  }

  /// Get current signed-in Firebase user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}
