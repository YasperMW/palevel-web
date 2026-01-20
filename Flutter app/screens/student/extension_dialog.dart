import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'bookings_tab.dart';
import '../../services/booking_service.dart';

// Extension Dialog Widget
class ExtensionDialog extends StatefulWidget {
  final Booking booking;
  final Function(int) onExtend;
  final int selectedMonths;

  const ExtensionDialog({super.key,
    required this.booking,
    required this.onExtend,
    this.selectedMonths = 1,
  });

  @override
  State<ExtensionDialog> createState() => ExtensionDialogState();
}

class ExtensionDialogState extends State<ExtensionDialog> {
  int _selectedMonths = 1;
  bool _isCalculating = false;
  double? _extensionAmount;
  double? _monthlyPrice;
  double? _platformFee;
  String? _newCheckoutDate;

  @override
  void initState() {
    super.initState();
    _selectedMonths = widget.selectedMonths;
    _calculateExtensionAmount();
  }

  Future<void> _calculateExtensionAmount() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      final bookingService = BookingService();
      
      // Fetch current pricing from backend
      final pricingData = await bookingService.getExtensionPricing(
        bookingId: widget.booking.id,
        additionalMonths: _selectedMonths,
      );
      
      // Extract pricing information from backend response
      _monthlyPrice = pricingData['monthly_price']?.toDouble();
      _platformFee = pricingData['platform_fee']?.toDouble() ?? 2500.0;
      final total = pricingData['total_amount']?.toDouble();
      
      // Calculate new checkout date
      _newCheckoutDate = _calculateNewCheckoutDate();
      
      setState(() {
        _extensionAmount = total;
      });
    } catch (e) {
      setState(() {
        _extensionAmount = null;
        _newCheckoutDate = null;
        _monthlyPrice = null;
        _platformFee = null;
      });
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  String _calculateNewCheckoutDate() {
    try {
      // Parse current checkout date (format: YYYY-MM-DD)
      final currentCheckout = widget.booking.checkOut;
      final parts = currentCheckout.split('-');
      if (parts.length != 3) return currentCheckout;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      // Add selected months
      var newMonth = month + _selectedMonths;
      var newYear = year;
      
      // Handle year overflow
      while (newMonth > 12) {
        newMonth -= 12;
        newYear++;
      }
      
      // Format back to YYYY-MM-DD
      return '${newYear.toString().padLeft(4, '0')}-${newMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    } catch (e) {
      return widget.booking.checkOut;
    }
  }

  @override
  void didUpdateWidget(ExtensionDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonths != _selectedMonths) {
      _calculateExtensionAmount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.date_range_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'Extend Booking',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Extend your stay at ${widget.booking.hostelName} (Full Amount Payment)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Current checkout info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Checkout: ${widget.booking.checkOut}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Month selection
          Text(
            'Select additional months:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          // Month selector buttons
          Row(
            children: [1, 2].map((months) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$months ${months == 1 ? 'month' : 'months'}'),
                  selected: _selectedMonths == months,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMonths = months;
                      });
                      _calculateExtensionAmount();
                    }
                  },
                  backgroundColor: AppColors.grey.shade200,
                  selectedColor: AppColors.primary.withValues(alpha:0.2),
                  labelStyle: TextStyle(
                    color: _selectedMonths == months ? AppColors.primary : AppColors.black.withOpacity(0.87),
                    fontWeight: _selectedMonths == months ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Price calculation
          if (_isCalculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_extensionAmount != null)
            Column(
              children: [
                // New checkout date
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Checkout Date:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey.shade600,
                            ),
                          ),
                          Text(
                            _newCheckoutDate ?? widget.booking.checkOut,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Payment breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha:0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Breakdown:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Monthly rent
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Rent × $_selectedMonths:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey.shade700,
                            ),
                          ),
                          Text(
                            _monthlyPrice != null 
                                ? 'MK ${((_monthlyPrice! * _selectedMonths)).toStringAsFixed(0)}'
                                : 'Calculating...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Platform fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Platform Fee:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.grey.shade700,
                            ),
                          ),
                          Text(
                            _platformFee != null
                                ? 'MK ${(_platformFee!).toStringAsFixed(0)}'
                                : 'Calculating...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Divider
                      Divider(color: AppColors.grey.shade300),
                      const SizedBox(height: 8),
                      
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            _extensionAmount != null
                                ? 'MK ${(_extensionAmount!).toStringAsFixed(0)}'
                                : 'Calculating...',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.errorGradient,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: _extensionAmount != null
                ? () {
              Navigator.of(context).pop();
              widget.onExtend(_selectedMonths);
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.transparent,
              shadowColor: AppColors.transparent,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Proceed to Payment',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],

    );
  }
}
