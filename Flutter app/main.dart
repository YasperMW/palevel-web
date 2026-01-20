import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'app_navigator.dart';
import 'screens/auth_checker.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/student_signup.dart';
import 'screens/landlord_signup.dart';
import 'screens/otp_verification.dart';
import 'screens/password_reset_request.dart';
import 'screens/password_reset_otp.dart';
import 'screens/password_reset_new_password.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/landlord/landlord_dashboard.dart';
import 'screens/payment_webview.dart';
import 'screens/oauth_student_completion.dart';
import 'screens/oauth_landlord_completion.dart';
import 'services/app_lifecycle_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


import 'services/notifications_service.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Firebase here - move other services to splash screen
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize app lifecycle service (lightweight)
  final appLifecycleService = AppLifecycleService();
  appLifecycleService.initialize();

  runApp(MyApp(
    appLifecycleService: appLifecycleService,
  ));
}



class MyApp extends StatefulWidget {
  final AppLifecycleService appLifecycleService;
  
  const MyApp({
    super.key,
    required this.appLifecycleService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationsService().initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaLevel',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Set the initial route to the splash screen
      initialRoute: '/',
      // Define all your routes
      routes: <String, WidgetBuilder>{
        '/': (context) => const SplashPage(),
        '/auth-check': (context) => const AuthCheckerPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUp1(),
        '/student-signup': (context) => const SignUpStudent(),
        '/landlord-signup': (context) => const SignUpLandlord(),
        '/otp-verification': (context) => const OtpVerification(),
        '/password-reset-request': (context) => const PasswordResetRequestScreen(),
        '/password-reset-otp': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final identifier = args?['identifier'] as String? ?? '';
          return PasswordResetOtpScreen(identifier: identifier);
        },
        '/password-reset-new-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final identifier = args?['identifier'] as String? ?? '';
          return PasswordResetNewPasswordScreen(identifier: identifier);
        },
        '/student-dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialIndex = args is int ? args : 0;
          return StudentDashboard(initialIndex: initialIndex);
        },
        '/landlord-dashboard': (context) => const LandlordDashboard(),
        '/oauth-student-completion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final temporaryToken = args?['temporaryToken'] as String? ?? '';
          final googleUserData = args?['googleUserData'] as Map<String, dynamic>? ?? {};
          return OAuthStudentCompletion(
            temporaryToken: temporaryToken,
            googleUserData: googleUserData,
          );
        },
        '/payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final paymentUrl = args?['paymentUrl'] as String? ?? '';
          final bookingId = args?['bookingId'] as String?;
          final isExtension = args?['isExtension'] as bool? ?? false;
          return PaymentWebView(
            url: paymentUrl,
            bookingId: bookingId,
            isExtension: isExtension,
          );
        },
        '/oauth-landlord-completion': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final temporaryToken = args?['temporaryToken'] as String? ?? '';
          final googleUserData = args?['googleUserData'] as Map<String, dynamic>? ?? {};
          return OAuthLandlordCompletion(
            temporaryToken: temporaryToken,
            googleUserData: googleUserData,
          );
        },
      },
    );
  }
}
