import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/booking_service.dart';
import '../../config.dart';
import 'booking_detail.dart';
import '../../services/user_session_service.dart';
import 'extension_dialog.dart';
import 'complete_payment_dialog.dart';
import '../payment_webview.dart';

// Model for a booking
class Booking {
  final String id;
  final String hostelName;
  final String? roomNumber;
  final String hostelImage;
  final double price;
  final String status;
  final String checkIn;
  final String checkOut;
  final String bookingDate;
  final String roomType;
  final String landlord;
  final String? paymentMethod;
  final String? transactionId;
  final String? paymentType;
  final double? baseRoomPrice;
  final double? platformFee;
  final String genderSpecification;
final int? durationMonths;


  Booking({
    this.paymentType,
    required this.id,
    required this.hostelName,
    this.roomNumber,
    required this.hostelImage,
    required this.price,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.bookingDate,
    required this.roomType,
    required this.landlord,
    this.paymentMethod,
    this.transactionId,
    this.baseRoomPrice,
    this.platformFee,
this.durationMonths,
    required this.genderSpecification,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Helper to safely access nested properties
    T? getProp<T>(Map<String, dynamic> data, List<String> path) {
      dynamic current = data;
      for (var key in path) {
        if (current is Map<String, dynamic> && current.containsKey(key)) {
          current = current[key];
        } else {
          return null;
        }
      }
      return current as T?;
    }

    // Prioritize room image, fall back to hostel image
    String? imageUrl;
    
    // Try to get room media
    final roomMedia = getProp<List>(json, ['room', 'media']);
    if (roomMedia?.isNotEmpty ?? false) {
      imageUrl = roomMedia!.first['url'];
    } 
    
    // If no room media, try hostel media
    if (imageUrl == null) {
      final hostelMedia = getProp<List>(json, ['room', 'hostel', 'media']);
      if (hostelMedia?.isNotEmpty ?? false) {
        imageUrl = hostelMedia!.first['url'];
      }
    }

    return Booking(
      id: json['booking_id'] as String? ?? 'N/A',
      hostelName: getProp<String>(json, ['room', 'hostel', 'name']) ?? 'Unknown Hostel',
      roomNumber: getProp<String>(json, ['room', 'room_number']),
      hostelImage: imageUrl != null
          ? (imageUrl.startsWith('http') ? imageUrl : '$kBaseUrl/uploads/$imageUrl')
          : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b026e?w=400',
      price: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] as String? ?? 'pending').capitalize(),
      checkIn: json['check_in_date'] as String? ?? 'N/A',
      checkOut: json['check_out_date'] as String? ?? 'N/A',
      bookingDate: json['created_at'] as String? ?? 'N/A',
      roomType: getProp<String>(json, ['room', 'room_type']) ?? 'Unknown Type',
      landlord: getProp<String>(json, ['room', 'hostel', 'landlord', 'first_name']) != null
          ? '${getProp<String>(json, ['room', 'hostel', 'landlord', 'first_name'])} ${getProp<String>(json, ['room', 'hostel', 'landlord', 'last_name'])}'
          : 'N/A',
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      paymentType: (json['payment_type'] as String?)?.toLowerCase(),
       platformFee: json['platform_fee'] != null ? (json['platform_fee'] as num).toDouble() : null,
      durationMonths: json['duration_months'] as int?,
      baseRoomPrice: json['base_room_price'] != null ? (json['base_room_price'] as num).toDouble() : null,
      genderSpecification: getProp<String>(json, ['room', 'hostel', 'gender_specification']) ?? 'Mixed',

    );
  }
}

// Helper to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class BookingsTab extends StatefulWidget {
  final String? transactionReference;
  final Map<String, dynamic>? paymentArguments;
  final VoidCallback? onVerificationDone;

  const BookingsTab({
    super.key,
    this.transactionReference,
    this.paymentArguments,
    this.onVerificationDone,
  });

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  late final ScrollController _scrollController;
  final BookingService _bookingService = BookingService();
  
  String _selectedFilter = 'All';
  bool _isLoading = true;
  String? _error;

  List<Booking> _bookings = [];

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'Confirmed', 'icon': Icons.check_circle_rounded},
    {'label': 'Pending', 'icon': Icons.pending_rounded},
    {'label': 'Extension In Progress', 'icon': Icons.hourglass_top_rounded},
    {'label': 'Pending Extension', 'icon': Icons.pending_actions_rounded},
    {'label': 'Cancelled', 'icon': Icons.cancel_rounded},
    {'label': 'Paid In Full', 'icon': Icons.payments_rounded},
    {'label': 'Booking Fee Only', 'icon': Icons.bookmark_rounded},
  ];
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.transactionReference != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyAndReload());
    } else {
      _loadBookings();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BookingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactionReference != null &&
        widget.transactionReference != oldWidget.transactionReference) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyAndReload());
    }
  }

  Future<void> _verifyAndReload() async {
    if (!mounted) return;

    // Show a snackbar while verifying
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verifying payment...')),
    );

    try {
      // Get payment type from widget arguments
      final isExtension = widget.paymentArguments?['isExtension'] ?? false;
      final isCompletePayment = widget.paymentArguments?['isCompletePayment'] ?? false;
      
      if (isExtension) {
        // Use extension payment verification
        await _bookingService.verifyExtensionPayment(widget.transactionReference!);
      } else if (isCompletePayment) {
        // Use complete payment verification
        await _bookingService.verifyCompletePayment(widget.transactionReference!);
      } else {
        // Use regular payment verification
        await _bookingService.verifyPayment(widget.transactionReference!);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Check if this is a stuck payment scenario
      if (e.toString().contains('not found') || 
          e.toString().contains('Invalid payment') ||
          e.toString().contains('already completed')) {
        
        // Check if we have a booking with stuck status
        await _checkAndHandleStuckPayments();
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: $e')),
      );
    } finally {
      // Reload bookings and notify parent that verification is done
      if (mounted) {
        await _loadBookings();
        widget.onVerificationDone?.call();
      }
    }
  }

  Future<void> _checkAndHandleStuckPayments() async {
    if (!mounted) return;
    
    try {
      // Reload bookings to get current status
      await _loadBookings();
      
      // Check for any bookings stuck in payment status
      final stuckBookings = _bookings.where((booking) => 
          booking.status == 'completing_payment' ||
          booking.status == 'extension_in_progress'
      );
      
      if (stuckBookings.isNotEmpty) {
        for (final booking in stuckBookings) {
          if (booking.status == 'completing_payment') {
            _showResetCompletePaymentDialog();
          } else if (booking.status == 'extension_in_progress') {
            _showResetExtensionDialog(1); // Default to 1 month for reset
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking payment status: $e')),
        );
      }
    }
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookingsData = await _bookingService.getUserBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookingsData.map((data) => Booking.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load bookings. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _showResetCompletePaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Complete Payment Status'),
          content: const Text(
            'This booking appears to be stuck in complete payment status. Would you like to reset the status so you can try completing the payment again?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final bookingService = BookingService();
                  // Find the stuck booking and get its ID
                  final stuckBooking = _bookings.firstWhere(
                    (booking) => booking.status == 'completing_payment',
                    orElse: () => throw Exception('No stuck booking found'),
                  );
                  final result = await bookingService.resetCompletePaymentStatus(
                    bookingId: stuckBooking.id,
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Complete payment status reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload bookings to show updated status
                    await _loadBookings();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reset complete payment status: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reset Status'),
            ),
          ],
        );
      },
    );
  }

  void _showResetExtensionDialog(int additionalMonths) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Extension Status'),
          content: const Text(
            'This booking appears to be stuck in extension status. Would you like to reset the status so you can try extending again?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final bookingService = BookingService();
                  // Find the stuck booking and get its ID
                  final stuckBooking = _bookings.firstWhere(
                    (booking) => booking.status == 'extension_in_progress',
                    orElse: () => throw Exception('No stuck booking found'),
                  );
                  final result = await bookingService.resetExtensionStatus(
                    stuckBooking.id,
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Extension status reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload bookings to show updated status
                    await _loadBookings();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reset extension status: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reset Status'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _getFilteredBookings();

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_bookings.length} total bookings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Filter Chips
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter['label'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter['label']! as String;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppColors.primary.withValues(alpha:0.3),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha:0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filter['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                filter['label']! as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Body Content
        _buildBody(filteredBookings),

        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
      ),
    );
  }

  Widget _buildBody(List<Booking> filteredBookings) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadBookings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (filteredBookings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Bookings Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${_selectedFilter.toLowerCase()} bookings will appear here',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final booking = filteredBookings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _BookingCard(
                booking: booking,
                onReloadBookings: _loadBookings,
              ),
            );
          },
          childCount: filteredBookings.length,
        ),
      ),
    );
  }

  // Helper method to filter bookings based on selected filter
  List<Booking> _getFilteredBookings() {
    if (_selectedFilter == 'All') {
      return _bookings;
    }
    
    // Status-based filters - map display labels to actual status values
    if (_selectedFilter == 'Confirmed' || 
        _selectedFilter == 'Pending' || 
        _selectedFilter == 'Extension In Progress' ||
        _selectedFilter == 'Pending Extension' ||
        _selectedFilter == 'Cancelled') {
      
      // Map display labels back to actual status values
      String actualStatus;
      switch (_selectedFilter) {
        case 'Extension In Progress':
          actualStatus = 'extension_in_progress';
          break;
        case 'Pending Extension':
          actualStatus = 'pending_extension';
          break;
        case 'Paid In Full':
          actualStatus = 'paid in full';
          break;
        default:
          actualStatus = _selectedFilter.toLowerCase();
      }
      
      return _bookings.where((b) => b.status.toLowerCase() == actualStatus).toList();
    }
    
    // Payment-based filters
    if (_selectedFilter == 'Paid In Full') {
      return _bookings.where((b) => b.paymentType == 'full').toList();
    }
    
    if (_selectedFilter == 'Booking Fee Only') {
      return _bookings.where((b) => b.paymentType == 'booking_fee').toList();
    }
    
    return _bookings;
  }
}

// Booking Card Widget
// Booking Card Widget
class _BookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onReloadBookings;

  const _BookingCard({
    required this.booking,
    this.onReloadBookings,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

// In bookings_tab.dart

class _BookingCardState extends State<_BookingCard> {
  String? _currentUserGender;
  bool _isVerifyingPayment = false;
  bool _isExtending = false;
  int _retryCount = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _fetchUserGender();
  }

  // [CORRECTED & FINAL] Method to get the user's gender from SharedPreferences via the service
  Future<void> _fetchUserGender() async {
    // Use the exact method from your UserSessionService
    final gender = await UserSessionService.getUserGender();
    if (mounted) {
      setState(() {
        _currentUserGender = gender;
      });
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  // Method to verify payment for pending bookings with smart retry mechanism
  Future<void> _verifyPayment() async {
    if (_isVerifyingPayment) return;

    setState(() {
      _isVerifyingPayment = true;
      _retryCount = 0;
    });

    await _performVerification();
  }

  Future<void> _performVerification() async {
    try {
      final bookingService = BookingService();
      Map<String, dynamic> result;
      
      // Use different verification method based on booking status
      if (widget.booking.status.toLowerCase() == 'pending_extension') {
        // For extension payments, we need to find the extension payment ID
        // Since we don't have payments array, we'll use the regular verification
        // but with a flag to indicate it's an extension
        result = await bookingService.verifyMyPayment(widget.booking.id);
        
        // Add extension-specific handling if needed
        if (result['status'] == 'success') {
          // The backend will handle extension-specific logic based on payment type
          result['message'] = 'Extension payment verified successfully';
        }
      } else {
        // Use regular verification
        result = await bookingService.verifyMyPayment(widget.booking.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment verification completed'),
            backgroundColor: result['status'] == 'success' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Handle cancelled booking case specifically
        if (errorMessage.contains('has been cancelled')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment was never initiated properly. This booking has been cancelled.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (errorMessage.contains('payment verification failed') && _retryCount < 3) {
          // Payment might still be processing, schedule retry with exponential backoff
          _scheduleRetry();
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verification failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPayment = false;
        });
        
        // Always reload bookings to reflect any status changes
        final parentState = context.findAncestorStateOfType<_BookingsTabState>();
        parentState?._loadBookings();
      }
    }
  }

  void _scheduleRetry() {
    if (_retryCount >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification is taking longer than expected. Please try again in a few minutes.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    _retryCount++;
    final delay = Duration(seconds: 5 * _retryCount); // 5s, 10s, 15s delays

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verification in progress... Retrying in $delay.inSeconds seconds ($_retryCount/3)'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _retryTimer = Timer(delay, () {
      if (mounted && !_isVerifyingPayment) {
        _performVerification();
      }
    });
  }

  // Method to verify stuck payments
  Future<void> _verifyStuckPayment() async {
    if (_isVerifyingPayment) return;

    setState(() {
      _isVerifyingPayment = true;
    });

    try {
      final bookingService = BookingService();
      Map<String, dynamic> result;
      
      // Use different verification method based on booking status
      if (widget.booking.status.toLowerCase() == 'extension_in_progress') {
        result = await bookingService.verifyStuckExtensionPayment(widget.booking.id);
      } else if (widget.booking.status.toLowerCase() == 'completing_payment') {
        result = await bookingService.verifyStuckCompletePayment(widget.booking.id);
      } else {
        throw Exception('Unknown stuck payment status');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment verification completed'),
            backgroundColor: result['status'] == 'success' ? Colors.green : Colors.orange,
          ),
        );
        
        // Reload bookings to show updated status
        if (widget.onReloadBookings != null) {
          widget.onReloadBookings!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify stuck payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPayment = false;
        });
      }
    }
  }

  // Method to show the confirmation dialog for a gender mismatch
  Future<void> _showGenderMismatchDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Gender Mismatch Warning'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'This accommodation is specified for "${widget.booking.genderSpecification}" residents. Are you sure you want to proceed?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Proceed Anyway'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _navigateToDetails(); // Navigate to the details page
              },
            ),
          ],
        );
      },
    );
  }

  // Centralized navigation logic
  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(booking: widget.booking),
      ),
    );
  }

  // The main logic to handle the tap event on the entire card
  void _handleTap() {
    final roomGender = widget.booking.genderSpecification;

    // We proceed without warning if:
    // 1. The user's gender couldn't be loaded (_currentUserGender is null).
    // 2. The room is for 'Mixed' gender.
    // 3. The user's gender matches the room's specification (case-insensitive).
    if (_currentUserGender == null ||
        roomGender.toLowerCase() == 'mixed' ||
        roomGender.toLowerCase() == _currentUserGender!.toLowerCase()) {
      _navigateToDetails();
    } else {
      // If there's a mismatch, show the warning dialog.
      _showGenderMismatchDialog();
    }
  }

  // Check if booking can be extended
  bool _canExtendBooking() {
    if (widget.booking.checkOut.isEmpty) return false;
    
    try {
      final checkoutDate = DateTime.parse(widget.booking.checkOut);
      final now = DateTime.now();
      return checkoutDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  // Show extension dialog
  Future<void> _showExtensionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ExtensionDialog(
          booking: widget.booking,
          onExtend: (additionalMonths) => _extendBooking(additionalMonths),
        );
      },
    );
  }

  // Show complete payment dialog
  Future<void> _showCompletePaymentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CompletePaymentDialog(
          booking: widget.booking,
          onComplete: _completePayment,
        );
      },
    );
  }

  // Extend booking
  Future<void> _extendBooking(int additionalMonths) async {
    if (_isExtending) return;

    setState(() {
      _isExtending = true;
    });

    try {
      final bookingService = BookingService();
      
      // Step 1: Update extension status when user proceeds to payment
      try {
        final statusResult = await bookingService.updateExtensionStatus(
          bookingId: widget.booking.id,
          additionalMonths: additionalMonths,
        );
        
        // Check if extension can proceed
        if (statusResult['action_required'] == 'complete_payment') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Extension payment already initiated. Please complete the payment.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 4),
              ),
            );
            // Navigate to payment with existing payment ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebView(
                  url: '', // Will need to get payment URL from existing payment
                  bookingId: widget.booking.id,
                  isExtension: true,
                ),
              ),
            );
            return;
          }
        }
      } catch (e) {
        // Check if booking is stuck in extension_in_progress
        if (e.toString().contains('extension_in_progress')) {
          _showResetExtensionDialog(additionalMonths);
          return;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update extension status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Step 2: Get user details for payment
      final email = await UserSessionService.getUserEmail();
      final userData = await UserSessionService.getCachedUserData();
      final firstName = userData?.firstName;
      final lastName = userData?.lastName;
      final phoneNumber = userData?.phoneNumber;

      if (email == null || firstName == null || lastName == null) {
        throw Exception('User information not complete');
      }

      // Step 3: Initiate extension payment
      final paymentResponse = await bookingService.initiateExtensionPayment(
        bookingId: widget.booking.id,
        additionalMonths: additionalMonths,
        email: email,
        phoneNumber: phoneNumber ?? '',
        firstName: firstName,
        lastName: lastName,
      );

      if (mounted) {
        final paymentUrl = paymentResponse['payment_url'];
        if (paymentUrl != null) {
          // Navigate to payment page
          Navigator.of(context).pushNamed('/payment', arguments: {
            'paymentUrl': paymentUrl,
            'bookingId': widget.booking.id,
            'isExtension': true,
          });
        } else {
          throw Exception('Payment URL not received');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extend booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtending = false;
        });
      }
    }
  }

  // Complete payment for booking fee only bookings
  Future<void> _completePayment() async {
    if (_isExtending) return;

    setState(() {
      _isExtending = true;
    });

    try {
      final bookingService = BookingService();
      
      // Step 1: Update complete payment status when user proceeds to payment
      try {
        final statusResult = await bookingService.updateCompletePaymentStatus(
          bookingId: widget.booking.id,
        );
        
        // Check if complete payment can proceed
        if (statusResult['action_required'] == 'complete_payment') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete payment already initiated. Please complete the payment.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 4),
              ),
            );
            // Navigate to payment with existing payment ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebView(
                  url: '', // Will need to get payment URL from existing payment
                  bookingId: widget.booking.id,
                  isCompletePayment: true,
                ),
              ),
            );
            return;
          }
        }
      } catch (e) {
        // Check if booking is stuck in completing_payment
        if (e.toString().contains('completing_payment')) {
          _showResetCompletePaymentDialog();
          return;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update complete payment status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Step 2: Get user details for payment
      final email = await UserSessionService.getUserEmail();
      final userData = await UserSessionService.getCachedUserData();
      final firstName = userData?.firstName;
      final lastName = userData?.lastName;
      final phoneNumber = userData?.phoneNumber;

      if (email == null || firstName == null || lastName == null) {
        throw Exception('User information not complete');
      }

      // Step 3: Get pricing from backend to calculate accurate remaining amount
      final pricingData = await bookingService.getCompletePaymentPricing(
        bookingId: widget.booking.id,
      );
      
      final remainingAmount = pricingData['remaining_amount']?.toDouble() ?? 0.0;

      // Step 4: Initiate complete payment
      final paymentResponse = await bookingService.initiateCompletePayment(
        bookingId: widget.booking.id,
        remainingAmount: remainingAmount,
        email: email,
        phoneNumber: phoneNumber ?? '',
        firstName: firstName,
        lastName: lastName,
      );

      if (mounted) {
        final paymentUrl = paymentResponse['payment_url'];
        if (paymentUrl != null) {
          // Navigate to payment page
          Navigator.of(context).pushNamed('/payment', arguments: {
            'paymentUrl': paymentUrl,
            'bookingId': widget.booking.id,
            'isCompletePayment': true,
          });
        } else {
          throw Exception('Payment URL not received');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtending = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'extension_in_progress':
        return Colors.blue;
      case 'completing_payment':
        return Colors.purple;
      case 'pending_extension':
        return Colors.deepOrange;
      case 'paid in full':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Format status display to remove underscores and capitalize properly
  String _formatStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'extension_in_progress':
        return 'Extension In Progress';
      case 'completing_payment':
        return 'Completing Payment';
      case 'pending_extension':
        return 'Pending Extension';
      case 'paid in full':
        return 'Paid In Full';
      default:
        return status.split('_').map((word) => word.capitalize()).join(' ');
    }
  }

  void _showResetCompletePaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Complete Payment Status'),
          content: const Text(
            'This booking appears to be stuck in complete payment status. Would you like to reset the status so you can try completing the payment again?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final bookingService = BookingService();
                  final result = await bookingService.resetCompletePaymentStatus(
                    bookingId: widget.booking.id,
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Complete payment status reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload bookings to show updated status
                    if (widget.onReloadBookings != null) {
                      widget.onReloadBookings!();
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reset complete payment status: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reset Status'),
            ),
          ],
        );
      },
    );
  }

  void _showResetExtensionDialog(int additionalMonths) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Extension Status'),
          content: const Text(
            'This booking appears to be stuck in extension status. Would you like to reset the status so you can try extending again?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final bookingService = BookingService();
                  final result = await bookingService.resetExtensionStatus(
                    widget.booking.id,
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Extension status reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload bookings to show updated status
                    if (widget.onReloadBookings != null) {
                      widget.onReloadBookings!();
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reset extension status: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reset Status'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.booking.status);

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Status
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha:0.1),
                          AppColors.primaryLight.withValues(alpha:0.1),
                        ],
                      ),
                    ),
                    child: Image.network(
                      widget.booking.hostelImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                // Status Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha:0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _formatStatusDisplay(widget.booking.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hostel Name
                  Text(
                    widget.booking.hostelName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (widget.booking.roomNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Room: ${widget.booking.roomNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Booking Details
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'Check-in: ${widget.booking.checkIn}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'Check-out: ${widget.booking.checkOut}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.home_rounded,
                    'Room Type: ${widget.booking.roomType}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.person_rounded,
                    'Landlord: ${widget.booking.landlord}',
                  ),
                  const SizedBox(height: 16),

                  // Price and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MK',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(widget.booking.price / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.booking.paymentType != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.booking.paymentType == 'full'
                                        ? Colors.green.withValues(alpha:0.1)
                                        : Colors.orange.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: widget.booking.paymentType == 'full'
                                          ? Colors.green.withValues(alpha:0.3)
                                          : Colors.orange.withValues(alpha:0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.booking.paymentType == 'full' ? 'Full Payment' : 'Booking Fee',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: widget.booking.paymentType == 'full'
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Actions Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Verify Payment Button for pending bookings
                          if (widget.booking.status.toLowerCase() == 'pending' || widget.booking.status.toLowerCase() == 'pending_extension')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: _isVerifyingPayment ? null : _verifyPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: _isVerifyingPayment
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.verified_rounded, size: 16),
                                  label: Text(
                                    _isVerifyingPayment ? 'Verifying...' : 'Verify Payment',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          // Extend Booking Button for confirmed bookings with full payment
                          // Complete Payment Button for confirmed bookings with booking fee only
                          if ((widget.booking.status.toLowerCase() == 'confirmed' || widget.booking.status.toLowerCase() == 'pending_extension') && _canExtendBooking())
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: _isExtending ? null : (widget.booking.paymentType == 'booking_fee' ? _showCompletePaymentDialog : _showExtensionDialog),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.booking.paymentType == 'booking_fee' ? Colors.orange : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: _isExtending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : widget.booking.paymentType == 'booking_fee' 
                                          ? const Icon(Icons.payment_rounded, size: 16)
                                          : const Icon(Icons.date_range_rounded, size: 16),
                                  label: Text(
                                    _isExtending ? 'Processing...' : (widget.booking.paymentType == 'booking_fee' ? 'Complete Payment' : 'Extend Booking'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Stuck Payment Recovery Button
                          if ((widget.booking.status.toLowerCase() == 'completing_payment' || widget.booking.status.toLowerCase() == 'extension_in_progress') && !_isExtending)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (widget.booking.status.toLowerCase() == 'completing_payment') {
                                      _showResetCompletePaymentDialog();
                                    } else if (widget.booking.status.toLowerCase() == 'extension_in_progress') {
                                      _showResetExtensionDialog(1);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text(
                                    'Reset Payment Status',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Verify Stuck Payment Button
                          if ((widget.booking.status.toLowerCase() == 'completing_payment' || widget.booking.status.toLowerCase() == 'extension_in_progress') && !_isExtending)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: _isVerifyingPayment ? null : _verifyStuckPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: _isVerifyingPayment
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.search_rounded, size: 16),
                                  label: Text(
                                    _isVerifyingPayment ? 'Verifying...' : 'Verify Stuck Payment',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Visual cue for tapping card
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



