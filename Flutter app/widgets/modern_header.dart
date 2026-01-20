import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ModernHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double logoSize;

  const ModernHeader({super.key, required this.title, this.subtitle, this.logoSize = 28});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder, width: 1.5),
                  ),
                  child: Image.asset(
                    'lib/assets/images/PaLevel Logo-White.png',
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.white,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notification icon
          Semantics(
            label: 'Notifications',
            button: true,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder, width: 1.5),
              ),
              child: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: AppColors.white),
                  Positioned(
                    right: 0, 
                    top: 0, 
                    child: SizedBox(
                      width: 8, 
                      height: 8, 
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.error, 
                          shape: BoxShape.circle
                        )
                      )
                    )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
