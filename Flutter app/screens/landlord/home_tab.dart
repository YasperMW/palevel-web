import 'package:flutter/material.dart';
import '../../services/user_session_service.dart';
import 'package:palevel/screens/landlord/payment_preferences_screen.dart';
import '../../services/api_service.dart';
import 'add_property_screen.dart';
import 'property_details_screen.dart';
import 'reports_page.dart';
import '../../services/hostel_service.dart';
import '../../services/activity_service.dart';
import '../../models/activity.dart';


class HomeTab extends StatefulWidget {
  final ScrollController? scrollController;
  final ValueChanged<int> onPageChange;

  const HomeTab({super.key, this.scrollController, required this.onPageChange});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final HostelService _hostelService = HostelService();
  final ActivityService _activityService = ActivityService();
  List<Activity> _recentActivities = [];
  User? _userData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _properties = [];
  int _totalProperties = 0;
int _totalRooms = 0;
double _occupancyRate = 0.0;
bool _isStatsLoading = true;
bool _isLoadingActivities = true;
bool _hasPaymentMethods = false;
Map<String, dynamic> _verificationStatus = {
  'status': 'not_submitted',
  'idType': null,
  'verifiedAt': null,
};
bool _isVerificationLoading = true;
 


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProperties();
    _loadStats();
   _setupActivities();
   _loadVerificationStatus();
    }





Future<void> _loadVerificationStatus() async {
  setState(() {
    _isVerificationLoading = true;
  });
  
  try {
    final email = await UserSessionService.getUserEmail();
    if (email != null && email.isNotEmpty) {
      final user = await ApiService.getUserProfile(email);
      
      if (user.userId.isNotEmpty) {
        final status = await ApiService.getLandlordVerificationStatus(user.userId);
        
        if (mounted) {
          setState(() {
            _verificationStatus = status;
            _isVerificationLoading = false;
          });
          return;
        }
      }
    }
  } catch (e) {
    //todo: add toast;
  }
  
  if (mounted) {
    setState(() {
      _isVerificationLoading = false;
    });
  }
}
  Future<void> _loadStats() async {
  try {
    final email = await UserSessionService.getUserEmail();
    if (email != null && email.isNotEmpty) {
      final stats = await ApiService.getLandlordStats(email);
      if (mounted) {
        setState(() {
          _totalProperties = stats['totalProperties'] ?? 0;
          _totalRooms = stats['totalRooms'] ?? 0;
          _occupancyRate = (stats['occupancyRate'] ?? 0.0).toDouble();
          _isStatsLoading = false;
        });
      }
    }
  } catch (e) {

    if (mounted) {
      setState(() {
        _isStatsLoading = false;
      });
    }
  }
}


 void _setupActivities() {
    // Initial load
    _loadRecentActivities();

    // Listen for updates
    _activityService.activitiesStream.listen((activities) {
      if (mounted) {
        setState(() {
          _recentActivities = activities;
          _isLoadingActivities = false;
        });
      }
    });
  }

  Future<void> _loadRecentActivities() async {
    try {
      setState(() => _isLoadingActivities = true);
      await _activityService.getRecentActivities(limit: 5);
    } catch (e) {
      //todo: add toast;
      if (mounted) {
        setState(() => _isLoadingActivities = false);
      }
    }
  }



  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'Not Verified';
    }
  }

  bool _hasPaymentDetails() {
    return _hasPaymentMethods;
  }

  Widget _buildVerificationAndPaymentStatus() {
    final status = _verificationStatus['status'] as String;
    final isVerified = status == 'approved';

    final isRejected = status == 'rejected';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF07746B),
              ),
            ),
            const SizedBox(height: 12),
            if (_isVerificationLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Verification Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isVerified 
                          ? Colors.green.withValues(alpha: 0.1)
                          : isRejected 
                              ? Colors.orange.withValues(alpha:0.1)
                              : Colors.blue.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isVerified 
                          ? Icons.verified_user 
                          : isRejected 
                              ? Icons.warning_amber_rounded 
                              : Icons.pending_actions,
                      color: isVerified 
                          ? Colors.green 
                          : isRejected 
                              ? Colors.orange 
                              : Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification: ${_getStatusText(status)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        if (isRejected)
                          const Text(
                            'Please update your documents and resubmit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isVerified && !isRejected)
                    TextButton(
                      onPressed: () {
                        // Navigate to profile page since verification is handled by admin
                        widget.onPageChange(4); // Index of the profile tab
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF07746B),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFF07746B)),
                        ),
                      ),
                      child: const Text('View Profile', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Payment Details Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _hasPaymentDetails() 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _hasPaymentDetails() ? Icons.payment : Icons.payment_outlined,
                      color: _hasPaymentDetails() ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hasPaymentDetails() 
                          ? 'Payment method added' 
                          : 'No payment method added',
                      style: TextStyle(
                        color: _hasPaymentDetails() ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (!_hasPaymentDetails())
                    TextButton(
                      onPressed: () {
                        // Navigate to payment preferences screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentPreferencesScreen(),
                          ),
                        ).then((_) {
                          // Refresh payment methods when returning from payment screen
                          _checkPaymentMethods();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF07746B),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFF07746B)),
                        ),
                      ),
                      child: const Text('Add Payment', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadProperties() async {
    try {
      final landlordEmail = await UserSessionService.getUserEmail();
      if (landlordEmail != null && landlordEmail.isNotEmpty) {
        final hostels = await _hostelService.getLandlordHostels(landlordEmail);
        if (mounted) {
          setState(() {
            _properties = hostels;
          });
        }
      }
    } catch (e) {
      //add better frontend error response

    }
  }


String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    final minutes = difference.inMinutes;
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
  } else if (difference.inDays < 1) {
    final hours = difference.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  } else if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  } else {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
  Future<void> _loadUserData() async {
    // First try to get cached data
    final cachedUser = await UserSessionService.getCachedUserData();
    if (cachedUser != null) {
      if (mounted) {
        setState(() {
          _userData = cachedUser;
          _isLoading = false;
        });
      }
    }

    // Then try to fetch fresh data from server
    final userEmail = await UserSessionService.getUserEmail();
    if (userEmail != null && userEmail.isNotEmpty) {
      try {
        final user = await ApiService.getUserProfile(userEmail);
        if (mounted) {
          setState(() {
            _userData = user;
            _isLoading = false;
          });
           // After loading user data, check for payment methods
        _checkPaymentMethods();
        }
        // Cache the fresh data
        await UserSessionService.saveUserData(user);
      } catch (e) {

        // If we have cached data, don't show error to user
        if (cachedUser == null) {

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } else {
      // No user email found
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

Future<void> _checkPaymentMethods() async {
  try {
    final response = await ApiService.getPaymentPreferences();
    if (mounted) {
      setState(() {
        final paymentMethods = response['paymentMethods'] ?? [];
        _hasPaymentMethods = paymentMethods.isNotEmpty;
      });
    }
  } catch (e) {
    // Handle error, but don't show error for this non-critical check

  }
}
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07746B)),
        ),
      );
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Welcome Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF07746B),
                  Color(0xFF0DDAC9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF07746B).withValues(alpha:0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome ${_userData?.firstName ?? 'Landlord'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s an overview of your property ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildVerificationAndPaymentStatus(),

const SizedBox(height: 24), 



          // Stats Overview
          Row(
  children: [
    Expanded(
      child: _buildStatCard(
        'Total Properties',
        _isStatsLoading ? '...' : '$_totalProperties',
        Icons.apartment,
        const Color(0xFF07746B),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildStatCard(
        'Total Rooms',
        _isStatsLoading ? '...' : '$_totalRooms',
        Icons.meeting_room,
        Colors.orange,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildStatCard(
        'Occupancy Rate',
        _isStatsLoading ? '...' : '${_occupancyRate.toStringAsFixed(1)}%',
        Icons.trending_up,
        Colors.green,
      ),
    ),
  ],
),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        'Add Property',
                        Icons.add_home,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddPropertyScreen(),
                            ),
                          ).then((_) {
                            // Refresh the properties list when returning from adding a property
                            if (mounted) {
                              // You can add any refresh logic here if needed
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        'View Bookings',
                        Icons.book_online,
                        Colors.green,
                        () {
                          widget.onPageChange(2); // Index of the bookings tab
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        'Manage Rooms',
                        Icons.door_front_door,
                        Colors.orange,
                        () {
                          if (_properties.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No properties found. Please add a property first.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          
                          // Navigate to the first property's details with rooms tab selected
                          final firstProperty = _properties.first;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailsScreen(
                                hostelId: firstProperty['hostel_id'] ?? '',
                                property: firstProperty,
                              ),
                            ),
                          ).then((_) {
                            // Refresh properties when returning
                            if (mounted) {
                              _loadProperties();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        'Reports',
                        Icons.assessment,
                        Colors.purple,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoadingActivities)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07746B)),
                    ),
                  )
                else if (_recentActivities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No recent activities',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: _recentActivities
                        .map((activity) => _buildActivityItem(activity))
                        .toList(),
                  )
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }








 Widget _buildActivityItem(Activity activity) {
    final iconData = _getActivityIcon(activity.type);
    final color = _getActivityColor(activity.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    fontWeight: activity.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimeAgo(activity.timestamp),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.assignment;
      case 'payment':
        return Icons.payment;
      case 'review':
        return Icons.star;
      case 'maintenance':
        return Icons.build;
      case 'message':
        return Icons.message;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'review':
        return Colors.amber;
      case 'maintenance':
        return Colors.orange;
      case 'message':
        return Colors.blueAccent;
      case 'system':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

}
