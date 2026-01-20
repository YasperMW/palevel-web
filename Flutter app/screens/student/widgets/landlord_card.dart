import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../models/hostel.dart';
import '../../../screens/chat/chat_screen.dart';

class LandlordCard extends StatelessWidget {
  final dynamic hostel;
  final String currentUserId;

  const LandlordCard({
    super.key, 
    required this.hostel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha:0.08),
            AppColors.primaryLight.withValues(alpha:0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha:0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                hostel['landlord']?[0]?.toString().toUpperCase() ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hostel['title']} Landlord',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                 
                  // Get landlord information
                  final hostelModel = Hostel.fromMap(hostel);
                  final landlordId = hostelModel.landlordId;
                  final landlordName = hostelModel.landlord ?? 'Landlord';
                  
                  
                  if (landlordId == null || landlordId.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Debug: Landlord ID missing. Available keys: ${hostel.keys.toList()}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  
                  
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserName: landlordName,
                        otherUserInitial: landlordName.isNotEmpty 
                            ? landlordName[0].toUpperCase() 
                            : 'L',
                        hostelName: (hostel['title'] as String?) ?? 'Hostel',
                        isLandlord: true,
                        receiverId: landlordId,
                        currentUserId: currentUserId,
                        isCurrentUserLandlord: false,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.message_rounded, color: AppColors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
