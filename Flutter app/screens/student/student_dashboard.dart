// lib/screens/student/student_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'home_tab.dart';
import 'bookings_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';
import 'notifications_page.dart';
import '../../services/api_service.dart';
import '../../services/user_session_service.dart';
import '../../services/notifications_service.dart';

import '../../theme/app_colors.dart';

class StudentDashboard extends StatefulWidget {
  final int initialIndex;
  final String? transactionReference;
  final Map<String, dynamic>? paymentArguments;

  const StudentDashboard({
    super.key,
    this.initialIndex = 0,
    this.transactionReference,
    this.paymentArguments,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  bool _isScrolled = false;
  User? _userData;
  String? _transactionReference;
  Map<String, dynamic>? _paymentArguments;
  int _unreadNotificationCount = 0;
  late final StreamSubscription<List<AppNotification>> _notifSub;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _transactionReference = widget.transactionReference;
    _paymentArguments = widget.paymentArguments;
    _loadUserData();
    
    // Initialize notification count
    _unreadNotificationCount = NotificationsService().unreadCount;
    
    // Listen for notification updates
    _notifSub = NotificationsService().notificationsStream.listen((notifs) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = NotificationsService().unreadCount;
        });
      }
    });
  }

  void _onVerificationDone() {
    setState(() {
      _transactionReference = null;
    });
  }

  Future<void> _loadUserData() async {
    // First try to get cached data
    final cachedUser = await UserSessionService.getCachedUserData();
    if (cachedUser != null) {
      setState(() {
        _userData = cachedUser;
      });
    }

    // Then try to fetch fresh data from server
    final userEmail = await UserSessionService.getUserEmail();
    if (userEmail != null && userEmail.isNotEmpty) {
      try {
        final user = await ApiService.getUserProfile(userEmail);
        setState(() {
          _userData = user;
        });
        // Cache the fresh data
        await UserSessionService.saveUserData(user);
      } catch (e) {

        // If we have cached data, don't show error to user
        if (cachedUser == null) {

        }
      }
    }
  }

  @override
  void dispose() {
    _notifSub.cancel();
    super.dispose();
  }

  List<Widget> _pages(BuildContext context) => [
        const HomeTab(),
        BookingsTab(
          transactionReference: _transactionReference,
          paymentArguments: _paymentArguments,
          onVerificationDone: _onVerificationDone,
        ),
        const MessagesTab(),
        const ProfileTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.mainGradient,
            stops: [0.0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(context, size),
              
              // Page Content
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      setState(() {
                        _isScrolled = notification.metrics.pixels > 30;
                      });
                    }
                    return false;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Modern Floating Navigation Bar
      bottomNavigationBar: _buildModernBottomNav(context, size),
    );
  }

  Widget _buildModernAppBar(BuildContext context, Size size) {
    final logoSize = _isScrolled ? 20.0 : 28.0;
    final verticalPadding = _isScrolled ? 8.0 : 16.0;
    final titleFontSize = _isScrolled ? 16.0 : 18.0;
    final subtitleFontSize = _isScrolled ? 11.0 : 14.0;
    final isHomeTab = _selectedIndex == 0;
    final showSubtitle = !_isScrolled && isHomeTab;

    // Get title based on selected tab
    String getTitle() {
      switch (_selectedIndex) {
        case 0:
          return 'Find your home';
        case 1:
          return 'My Bookings';
        case 2:
          return 'Messages';
        case 3:
          return 'Profile';
        default:
          return 'Find your home';
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo/Title Section
          Expanded(
            child: Row(
              children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(_isScrolled ? 6 : 10),
                decoration: BoxDecoration(
                  color: AppColors.glassBackground,
                  borderRadius: BorderRadius.circular(_isScrolled ? 12 : 16),
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 1.5,
                  ),
                ),
                child: Image.asset(
                  'lib/assets/images/PaLevel Logo-White.png',
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: showSubtitle
                    ? const SizedBox(width: 12)
                    : const SizedBox(width: 8),
              ),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showSubtitle)
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                                fontSize: subtitleFontSize,
                              ) ?? TextStyle(
                            color: AppColors.white,
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Roboto',
                          ),
                          child: Text(
                            _userData != null 
                                ? 'Welcome back, ${_userData!.firstName} ${_userData!.lastName}!'
                                : 'Welcome back!',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.white,
                              fontSize: titleFontSize,
                            ) ?? TextStyle(
                          color: AppColors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Anta',
                        ),
                        child: Text(
                          getTitle(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
          
          // Notification Icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(_isScrolled ? 8 : 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(_isScrolled ? 10 : 12),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.3),
                  width: 1.5,
                ),
              ),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87, // Changed from white to black87 for better visibility
                  size: _isScrolled ? 20 : 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: _unreadNotificationCount > 0
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav(BuildContext context, Size size) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                _buildNavItem(Icons.bookmark_outline_rounded, 'Bookings', 1),
                _buildNavItem(Icons.chat_bubble_outline_rounded, 'Messages', 2),
                _buildNavItem(Icons.person_outline_rounded, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: AppColors.primaryGradient,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _isScrolled = false; // Reset scroll state when switching tabs

    });
  }
}
