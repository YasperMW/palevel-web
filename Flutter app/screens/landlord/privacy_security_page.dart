import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // Header with back button and title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Privacy & Security',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Account Security'),
                        _buildSecurityOption(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          onTap: () {
                            // TODO: Implement change password
                            _showComingSoonSnackBar(context);
                          },
                        ),
                        _buildSecurityOption(
                          icon: Icons.phone_android_outlined,
                          title: 'Two-Factor Authentication',
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {
                              // TODO: Implement 2FA toggle
                              _showComingSoonSnackBar(context);
                            },
                            activeThumbColor: const Color(0xFF07746B),
                          ),
                        ),
                        
                        _buildSectionTitle('Privacy'),
                        _buildSecurityOption(
                          icon: Icons.visibility_off_outlined,
                          title: 'Hide My Profile',
                          subtitle: 'Prevent others from seeing your profile',
                          trailing: Switch(
                            value: false,
                            onChanged: (value) {
                              // TODO: Implement profile visibility toggle
                              _showComingSoonSnackBar(context);
                            },
                            activeThumbColor: const Color(0xFF07746B),
                          ),
                        ),
                        _buildSecurityOption(
                          icon: Icons.location_off_outlined,
                          title: 'Location Services',
                          subtitle: 'Control location-based features',
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {
                              // TODO: Implement location services toggle
                              _showComingSoonSnackBar(context);
                            },
                            activeThumbColor: const Color(0xFF07746B),
                          ),
                        ),
                        
                        _buildSectionTitle('Data & Permissions'),
                        _buildSecurityOption(
                          icon: Icons.notifications_none_outlined,
                          title: 'Notification Preferences',
                          onTap: () {
                            // TODO: Navigate to notification preferences
                            _showComingSoonSnackBar(context);
                          },
                        ),
                        _buildSecurityOption(
                          icon: Icons.storage_outlined,
                          title: 'Data Usage',
                          onTap: () {
                            // TODO: Navigate to data usage
                            _showComingSoonSnackBar(context);
                          },
                        ),
                        
                        _buildSectionTitle('Legal'),
                        _buildSecurityOption(
                          icon: Icons.description_outlined,
                          title: 'Privacy Policy',
                          onTap: () {
                            // TODO: Show privacy policy
                            _showComingSoonSnackBar(context);
                          },
                        ),
                        _buildSecurityOption(
                          icon: Icons.gavel_outlined,
                          title: 'Terms of Service',
                          onTap: () {
                            // TODO: Show terms of service
                            _showComingSoonSnackBar(context);
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        _buildDangerZone(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF07746B),
        ),
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF07746B).withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF07746B)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Danger Zone',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.red),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () {
              // TODO: Show delete account confirmation
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature will be available soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}