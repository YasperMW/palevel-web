import 'package:flutter/material.dart';
import '../../services/user_session_service.dart';
import '../../services/api_service.dart';
import '../../services/oauth_service.dart';
import '../../services/fcm_service.dart';
import 'edit_profile_page.dart';
import 'notifications_page.dart';
import 'payment_preferences_screen.dart';
// import 'privacy_security_page.dart'; // Temporarily removed
import 'help_support_page.dart';
import 'about_page.dart';
import 'national_id_resubmission_screen.dart';

class ProfileTab extends StatefulWidget {
  final ScrollController? scrollController;

  const ProfileTab({super.key, this.scrollController});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  User? _userData;
  bool _isLoading = true;
  bool _isStatsLoading = true;
  bool _isVerificationLoading = true;
  String? _error;
  String? _selectedUniversity;
  Map<String, dynamic> _stats = {
    'totalProperties': 0,
    'totalRooms': 0,
    'occupancyRate': 0.0,
  };
  Map<String, dynamic> _verificationStatus = {
    'status': 'not_submitted',
    'idType': null,
    'verifiedAt': null,
    'updatedAt': null,
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadVerificationStatus() async {
    if (_userData == null || _userData!.userId.isEmpty) return;
    
    try {
      setState(() {
        _isVerificationLoading = true;
      });
      
      final status = await ApiService.getLandlordVerificationStatus(_userData!.userId);
      
      if (mounted) {
        setState(() {
          _verificationStatus = status;
          _isVerificationLoading = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _isVerificationLoading = false;
          // Don't show error to user, just keep the default state
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    // Get user email from session storage
    final userEmail = await UserSessionService.getUserEmail();
    
    // Get selected university from session storage
    final university = await UserSessionService.getUniversity();
    
    // Reset verification loading state
    setState(() {
      _isVerificationLoading = true;
    });

    if (userEmail == null || userEmail.isEmpty) {
      setState(() {
        _error = 'No user session found. Please log in again.';
        _isLoading = false;
        _isStatsLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _isStatsLoading = true;
        _error = null;
        _selectedUniversity = university;
      });

      // First try to get cached data
      final cachedUser = await UserSessionService.getCachedUserData();
      if (cachedUser != null) {
        setState(() {
          _userData = cachedUser;
          _isLoading = false;
        });
      }

      // Then try to fetch fresh data from server
      final user = await ApiService.getUserProfile(userEmail);
      
      // Load landlord stats if user is a landlord
      if (user.userType == 'landlord') {
        try {
          final stats = await ApiService.getLandlordStats(userEmail);
          if (mounted) {
            setState(() {
              _stats = stats;
            });
          }
        } catch (e) {

          // Continue with default stats (0 values)
        }
      }
      
      if (mounted) {
        setState(() {
          _userData = user;
          _isLoading = false;
          _isStatsLoading = false;
        });
        // Cache the fresh data
        await UserSessionService.saveUserData(user);
        
        // Load verification status after user data is loaded
        _loadVerificationStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _isLoading = false;
          _isStatsLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Remove FCM device token before logout
      final fcmService = FCMService();
      await fcmService.removeDeviceToken();
      
      await UserSessionService.clearUserSession();
      await UserSessionService.clearRememberMeCredentials();
      
      // Clear OAuth session to force account selection on next login
      final oauthService = OAuthService();
      await oauthService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {

      // Still try to navigate even if clearing session fails
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
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
          
          // Profile Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              children: [
                // Profile Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _userData?.firstName.isNotEmpty == true
                          ? _userData!.firstName[0].toUpperCase()
                          : 'L',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF07746B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Landlord Name
                Text(
                  '${_userData?.firstName ?? ''} ${_userData?.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Landlord Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Property Landlord',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile Information
          _buildSectionCard(
            title: 'Personal Information',
            children: [
              _buildInfoRow('Full Name', '${_userData?.firstName ?? ''} ${_userData?.lastName ?? ''}'),
              _buildInfoRow('Email', _userData?.email ?? ''),
              _buildInfoRow('Phone Number', _userData?.phoneNumber ?? 'Not provided'),
              _buildInfoRow('Account Status', _userData?.isVerified == true ? 'Verified' : 'Not Verified'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Business Information
          _buildSectionCard(
            title: 'Business Information',
            children: [
              _buildInfoRow('Total Properties', _isStatsLoading ? '...' : '${_stats['totalProperties']}'),
              _buildInfoRow('Total Rooms', _isStatsLoading ? '...' : '${_stats['totalRooms']}'),
              _buildInfoRow('Occupancy Rate', _isStatsLoading ? '...' : '${_stats['occupancyRate']?.toStringAsFixed(1)}%'),
              _buildInfoRow('Member Since', _userData?.createdAt?.substring(0, 10) ?? 'N/A'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // University Information (if applicable)
          if (_selectedUniversity != null) ...[
            _buildSectionCard(
              title: 'University Association',
              children: [
                _buildInfoRow('University', _selectedUniversity!),
                _buildInfoRow('Campus Area', 'Main Campus'),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Verification Status
          _buildSectionCard(
            title: 'Verification Status',
            children: [
              if (_isVerificationLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildVerificationStatus(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Payment Preferences
            _buildSectionCard(
              title: 'Payment Preferences',
              children: [
                _buildActionRow(
                  icon: Icons.payment,  
                  title: 'Manage Payment Methods',
                  onTap: () async {
                    // Navigate to payment preferences screen and wait for result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentPreferencesScreen()),
                    );
                    
                    // Refresh payment methods if we returned from the payment screen
                    if (result == true) {
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
                ),
                // Add a FutureBuilder to show the preferred payment method
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchPaymentMethods(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildInfoRow(
                        'Default Payout Method',
                        'Not set',
                      );
                    }
                    
                    // Find the preferred payment method
                    final preferredMethod = snapshot.data!.firstWhere(
                      (method) => method['isPreferred'] == true,
                      orElse: () => snapshot.data!.isNotEmpty ? snapshot.data!.first : {},
                    );
                    
                    if (preferredMethod.isEmpty) {
                      return _buildInfoRow(
                        'Default Payout Method',
                        'Not set',
                      );
                    }
                    
                    // Format the payment method details
                    String paymentDetails = '';
                    final details = preferredMethod['details'] as Map<String, dynamic>? ?? {};
                    
                    if (preferredMethod['type'] == 'mobile_money' && details['mobileNumber'] != null) {
                      final number = details['mobileNumber'].toString();
                      paymentDetails = 'Mobile Money (••••${number.length > 4 ? number.substring(number.length - 4) : number})';
                    } 
                    else if (preferredMethod['type'] == 'bank_transfer' && details['accountNumber'] != null) {
                      final accountNumber = details['accountNumber'].toString();
                      paymentDetails = 'Bank Transfer (••••${accountNumber.length > 4 ? accountNumber.substring(accountNumber.length - 4) : accountNumber})';
                      if (details['bankName'] != null) {
                        paymentDetails += ' • ${details['bankName']}';
                      }
                    }
                    
                    return _buildInfoRow(
                      'Default Payout Method',
                      paymentDetails.isNotEmpty ? paymentDetails : 'Not set',
                    );
                  },
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Account Actions
          _buildSectionCard(
            title: 'Account Actions',
            children: [
              _buildActionRow(
                icon: Icons.edit,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LandlordEditProfilePage()),
                  );
                },
              ),
              _buildActionRow(
                icon: Icons.lock,
                title: 'Notifications',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LandlordNotificationsPage()),
                  );
                },
              ),
              // _buildActionRow(
              //   icon: Icons.lock,
              //   title: 'Privacy & Security',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const PrivacySecurityPage()),
              //     );
              //   },
              // ),
              _buildActionRow(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                  );
                },
              ),
               _buildActionRow(
                icon: Icons.settings,
                title: 'About Palevel',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
              _buildActionRow(
                icon: Icons.logout,
                title: 'Logout',
                titleColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFF07746B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      actions: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF0000), Color(0xFF880808)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF07746B), Color(0xFF0DDAC9)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],

                    ),
                  );

                  if (shouldLogout == true) {
                    await _logout();
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

Future<List<Map<String, dynamic>>> _fetchPaymentMethods() async {
  try {
    final response = await ApiService.getPaymentPreferences();
    final paymentMethods = response['paymentMethods'] as List<dynamic>? ?? [];
    return paymentMethods.cast<Map<String, dynamic>>();
  } catch (e) {
    //todo: add toast;
    return [];
  }
}


  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF07746B),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? const Color(0xFF07746B),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: titleColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: titleColor ?? Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationStatus() {
    final status = _verificationStatus['status'] as String;
    final idType = _verificationStatus['idType'] as String?;
    final verifiedAt = _verificationStatus['verifiedAt'] as String?;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String description;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.verified_user;
        statusText = 'Verified';
        description = 'Your identity has been successfully verified';
        if (verifiedAt != null) {
          description += ' on ${verifiedAt.substring(0, 10)}';
        }
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        statusText = 'Pending Review';
        description = 'Your verification is under review. This usually takes 1-2 business days.';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.warning_amber_rounded;
        statusText = 'Verification Rejected';
        description = 'Your verification was not approved. Please check your email for details.';
        break;
      default: // not_submitted
        statusColor = Colors.grey;
        statusIcon = Icons.person_outline;
        statusText = 'Not Verified';
        description = 'Complete identity verification to access all features';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (status == 'not_submitted' || status == 'rejected')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NationalIdResubmissionScreen()),
                );
                
                // Refresh verification status if we returned from the resubmission screen
                if (result == true) {
                  _loadVerificationStatus();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(status == 'rejected' ? 'Resubmit ID' : 'Start Verification'),
            ),
          ),
        if (status == 'pending')
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We\'ll notify you once your verification is complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        if (status == 'approved' && idType != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'ID Type: ${idType.toUpperCase()}${verifiedAt != null ? ' • Verified on ${verifiedAt.substring(0, 10)}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}
