// lib/screens/landlord/landlord_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/user_session_service.dart';
import '../../services/api_service.dart';
import '../../services/notifications_service.dart';
import 'home_tab.dart';
import 'properties_tab.dart';
import 'bookings_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';
import 'notifications_page.dart';

class LandlordDashboard extends StatefulWidget {
  const LandlordDashboard({super.key});

  @override
  State<LandlordDashboard> createState() => _LandlordDashboardState();
}

class _LandlordDashboardState extends State<LandlordDashboard> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  User? _userData;
  int _unreadNotificationCount = 0;
  late final StreamSubscription<List<AppNotification>> _notifSub;

  @override
  void initState() {
    super.initState();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static List<Widget> _pages(BuildContext context, ScrollController scrollController, ValueChanged<int> onPageChange) => [
        HomeTab(scrollController: scrollController, onPageChange: onPageChange),
        PropertiesTab(scrollController: scrollController),
        BookingsTab(scrollController: scrollController),
        MessagesTab(scrollController: scrollController),
        ProfileTab(scrollController: scrollController),
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
            colors: [
              Color(0xFF07746B),
              Color(0xFF0DDAC9),
              Colors.white,
            ],
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
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollUpdateNotification) {
                      setState(() {
                      });
                    }
                    return false;
                  },
                  child: _pages(context, _scrollController, _onItemTapped)[_selectedIndex],
                ),
              ),
            ],
          ),
        ),
      ),
      // Modern Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                _buildNavItem(Icons.apartment_outlined, Icons.apartment, 'Properties', 1),
                _buildNavItem(Icons.book_online_outlined, Icons.book_online, 'Bookings', 2),
                _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages', 3),
                _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, Size size) {
    return Container(
      height: size.height * 0.12,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PaLevel',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Anta',
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Landlord Portal',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha:0.9),
                  height: 1.0,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Notification Icon
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LandlordNotificationsPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha:0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.black87,
                        size: 24,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: _unreadNotificationCount > 0
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            )
                          : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha:0.3),
                child: _userData != null
                    ? Text(
                        _userData!.firstName.isNotEmpty 
                            ? _userData!.firstName[0].toUpperCase()
                            : 'L',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData inactiveIcon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF07746B).withValues(alpha:0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF07746B) : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF07746B) : Colors.grey.shade600,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
