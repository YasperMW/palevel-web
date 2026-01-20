import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class PrivacySetting {
  final String title;
  final String description;
  bool isEnabled;
  final IconData icon;
  final String key;
  final bool requiresAuth;

  PrivacySetting({
    required this.title,
    required this.description,
    required this.icon,
    required this.key,
    this.isEnabled = true,
    this.requiresAuth = false,
  });
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _isLoading = true;
  final List<PrivacySetting> _settings = [];
  bool _isBiometricSupported = false;
  bool _isBiometricEnrolled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    // In a real app, you would check for biometric support here
    // For now, we'll simulate it
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isBiometricSupported = true;
        _isBiometricEnrolled = true; // Simulate that biometric is enrolled
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load settings or use defaults
    final settings = [
      PrivacySetting(
        title: 'Biometric Authentication',
        description: 'Use your fingerprint or face to log in quickly and securely',
        icon: Icons.fingerprint_rounded,
        key: 'biometric_auth',
        requiresAuth: true,
        isEnabled: prefs.getBool('biometric_auth') ?? false,
      ),
      PrivacySetting(
        title: 'Auto-Lock',
        description: 'Automatically lock the app when you\'re not using it',
        icon: Icons.lock_clock_rounded,
        key: 'auto_lock',
        isEnabled: prefs.getBool('auto_lock') ?? true,
      ),
      PrivacySetting(
        title: 'Show Email',
        description: 'Allow others to see your email address',
        icon: Icons.email_rounded,
        key: 'show_email',
        isEnabled: prefs.getBool('show_email') ?? true,
      ),
      PrivacySetting(
        title: 'Show Phone Number',
        description: 'Allow others to see your phone number',
        icon: Icons.phone_rounded,
        key: 'show_phone',
        isEnabled: prefs.getBool('show_phone') ?? false,
      ),
      PrivacySetting(
        title: 'Activity Status',
        description: 'Show when you were last active on the app',
        icon: Icons.access_time_rounded,
        key: 'show_activity',
        isEnabled: prefs.getBool('show_activity') ?? true,
      ),
    ];

    if (mounted) {
      setState(() {
        _settings.clear();
        _settings.addAll(settings);
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSetting(PrivacySetting setting, bool value) async {
    if (setting.requiresAuth && value) {
      final confirmed = await _showBiometricPrompt();
      if (!confirmed) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(setting.key, value);

    setState(() {
      final index = _settings.indexWhere((s) => s.key == setting.key);
      if (index != -1) {
        _settings[index] = setting..isEnabled = value;
      }
    });
  }

  Future<bool> _showBiometricPrompt() async {
    // In a real app, show biometric prompt here
    // For now, we'll show a confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authenticate'),
        content: const Text('Please authenticate to enable this setting'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage your privacy and security settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.white.withValues(alpha:0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Control what information you share and how you stay secure',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha:0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Account Security Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 8),
            child: Text(
              'ACCOUNT SECURITY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.grey.shade600,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final setting = _settings[index];
              return _buildSettingItem(setting);
            },
            childCount: _settings.length,
          ),
        ),
        
        // Privacy Policy Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 8),
            child: Text(
              'PRIVACY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.grey.shade600,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.grey.shade200, width: 1),
            ),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'Privacy Policy',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.black.withOpacity(0.87),
                ),
              ),
              subtitle: Text(
                'Read our privacy policy to understand how we handle your data',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
              onTap: () {
                // Navigate to privacy policy
              },
            ),
          ),
        ),
        
        // Account Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 8),
            child: Text(
              'ACCOUNT ACTIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.grey.shade600,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.grey.shade200, width: 1),
            ),
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Logout from all devices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.black.withOpacity(0.87),
                    ),
                  ),
                  subtitle: Text(
                    'Sign out from all devices where you\'re logged in',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.grey.shade700,
                    ),
                  ),
                  onTap: () {
                    // Logout from all devices
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Delete Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    'Permanently delete your account and all data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  onTap: () {
                    // Show delete account confirmation
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildSettingItem(PrivacySetting setting) {
    final isBiometric = setting.key == 'biometric_auth';
    final isBiometricItem = isBiometric && (!_isBiometricSupported || !_isBiometricEnrolled);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey.shade200, width: 1),
      ),
      elevation: 0,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          setting.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: isBiometricItem ? AppColors.grey.shade400 : AppColors.black.withOpacity(0.87),
          ),
        ),
        subtitle: Text(
          isBiometricItem 
              ? _isBiometricSupported 
                  ? 'No biometrics enrolled on this device' 
                  : 'Biometric authentication not available'
              : setting.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: isBiometricItem ? AppColors.grey.shade400 : AppColors.grey.shade700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isBiometricItem 
                ? AppColors.grey.shade200
                : AppColors.primary.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            setting.icon,
            color: isBiometricItem 
                ? AppColors.grey.shade400
                : AppColors.primary,
            size: 20,
          ),
        ),
        value: isBiometricItem ? false : setting.isEnabled,
        onChanged: isBiometricItem 
            ? null 
            : (value) => _toggleSetting(setting, value),
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}
