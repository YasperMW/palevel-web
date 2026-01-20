import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'bookings_tab.dart';
import '../../services/booking_service.dart';

// Complete Payment Dialog Widget
class CompletePaymentDialog extends StatefulWidget {
  final Booking booking;
  final VoidCallback onComplete;

  const CompletePaymentDialog({super.key,
    required this.booking,
    required this.onComplete,
  });

  @override
  State<CompletePaymentDialog> createState() => CompletePaymentDialogState();
}

class CompletePaymentDialogState extends State<CompletePaymentDialog> {
  bool _isCalculating = true;
  double? _remainingAmount;
  double? _platformFee;
  double? _bookingFee;
  int? _remainingMonths;
  double? _monthlyRent;

  @override
  void initState() {
    super.initState();
    _calculateCompletePaymentAmount();
  }

  Future<void> _calculateCompletePaymentAmount() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      final bookingService = BookingService();
      
      // Fetch pricing from backend
      final pricingData = await bookingService.getCompletePaymentPricing(
        bookingId: widget.booking.id,
      );
      
      // Extract pricing information from backend response
      _platformFee = pricingData['platform_fee']?.toDouble() ?? 2500.0;
      _bookingFee = pricingData['booking_fee']?.toDouble();
      _remainingAmount = pricingData['remaining_amount']?.toDouble();
      _remainingMonths = pricingData['remaining_months']?.toInt();
      _monthlyRent = pricingData['monthly_rent']?.toDouble();
      
      setState(() {});
    } catch (e) {
      setState(() {
        _remainingAmount = null;
        _platformFee = null;
        _bookingFee = null;
        _remainingMonths = null;
        _monthlyRent = null;
      });
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.payment_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete Payment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
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
              'Complete the full payment for your booking at ${widget.booking.hostelName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            
            // Current booking info
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
                    'Current Payment: Booking Fee Only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Checkout Date: ${widget.booking.checkOut}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey.shade600,
                    ),
                  ),
                ],
              ),
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
            else if (_remainingAmount != null)
              Column(
                children: [
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
                        
                        // Total price for remaining months
                        if (_remainingMonths != null && _monthlyRent != null)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Monthly Rent × $_remainingMonths:',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'MK ${(_monthlyRent! * _remainingMonths!).toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        
                        // Platform fee
                        if (_platformFee != null)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Platform Fee:',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'MK ${(_platformFee!).toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        
                        // Less booking fee already paid
                        if (_bookingFee != null)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Less: Booking Fee Paid:',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '-MK ${(_bookingFee!).toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.error.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        
                        // Divider
                        Divider(color: AppColors.grey.shade300),
                        const SizedBox(height: 8),
                        
                        // Remaining amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Remaining Amount:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              'MK ${(_remainingAmount!).toStringAsFixed(0)}',
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
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unable to calculate payment amount. Please try again.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions:[
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
            onPressed: _remainingAmount != null
                ? () {
              Navigator.of(context).pop();
              widget.onComplete();
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
