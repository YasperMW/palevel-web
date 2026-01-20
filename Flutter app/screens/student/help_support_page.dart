// lib/screens/student/help_support_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';


class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class SupportContact {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  SupportContact({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I book a room?',
      answer: 'To book a room, navigate to the home screen, browse available hostels, and click on "Book Now" for your preferred room. Follow the on-screen instructions to complete your booking.',
    ),
    FAQItem(
      question: 'What payment methods are accepted?',
      answer: 'We accept various payment methods including mobile money (Airtel Money, TNM Mpamba), credit/debit cards, and bank transfers. All transactions are secure and encrypted.',
    ),
    FAQItem(
      question: 'How can I cancel my booking?',
      answer: 'Go to your bookings, select the booking you want to cancel, and click "Cancel Booking". Please note that cancellation policies may apply depending on the hostel\'s terms.',
    ),
    FAQItem(
      question: 'Is my personal information secure?',
      answer: 'Yes, we take your privacy seriously. All personal information is encrypted and stored securely in compliance with data protection regulations.',
    ),
    FAQItem(
      question: 'How do I contact a landlord?',
      answer: 'You can contact a landlord directly through the messaging system in the app. Go to the hostel details page and click on the "Message" button to start a conversation.',
    ),
  ];

  final List<SupportContact> _supportContacts = [];

  @override
  void initState() {
    super.initState();
    _initSupportContacts();
  }

  void _initSupportContacts() {
    _supportContacts.addAll([
      SupportContact(
        title: 'Live Chat',
        description: 'Chat with our support team in real-time',
        icon: Icons.chat_bubble_rounded,
        iconColor: AppColors.primary,
        onTap: () => _showComingSoonSnackbar('Live Chat'),
      ),
      SupportContact(
        title: 'Email Us',
        description: 'support@palevel.com',
        icon: Icons.email_rounded,
        iconColor: AppColors.primaryLight,
        onTap: () => _launchEmail(),
      ),
      SupportContact(
        title: 'Call Support',
        description: '+265 883271664',
        icon: Icons.phone_rounded,
        iconColor: AppColors.success,
        onTap: () => _makePhoneCall('+265883271664'),
      ),
      SupportContact(
        title: 'FAQ',
        description: 'Frequently asked questions',
        icon: Icons.help_outline_rounded,
        iconColor: AppColors.warning,
      ),
    ]);
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'kernelsoft1@gmail.com',
      queryParameters: {
        'subject': 'PaLevel App Support',
        'body': 'Hello PaLevel Support Team,\n\n',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      _showErrorSnackbar('Could not launch email client');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackbar('Could not launch phone app');
    }
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.white,
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20), // Increased padding
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 48,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re here to help with any questions or issues you might have.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha:0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 8),
              child: Text(
                'QUICK HELP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0, // Adjusted for better proportions
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final contact = _supportContacts[index];
                  return _buildSupportCard(contact);
                },
                childCount: _supportContacts.length,
              ),
            ),
          ),

          // FAQ Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FREQUENTLY ASKED QUESTIONS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Show all FAQs
                    },
                    child: Text(
                      'See All',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final faq = _faqs[index];
                return _buildFAQItem(faq);
              },
              childCount: _faqs.length,
            ),
          ),

          // Additional Help Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 8),
              child: Text(
                'STILL NEED HELP?',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.grey.shade200, width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_center_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Visit our Help Center',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Find answers to common questions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey.shade600,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.grey.shade600),
                  onTap: () {
                    // Navigate to help center
                  },
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    ));
  }

  Widget _buildSupportCard(SupportContact contact) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: contact.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 170, // Slightly reduced to prevent overflow
            maxWidth: double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: contact.iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(contact.icon, color: contact.iconColor, size: 20), // Increased icon size
                ),
                const SizedBox(height: 8),
                Text(
                  contact.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.black.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  contact.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey.shade600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey.shade200, width: 1),
      ),
      elevation: 0,
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            faq.isExpanded = expanded;
          });
        },
        trailing: Icon(
          faq.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          color: AppColors.grey.shade600,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}