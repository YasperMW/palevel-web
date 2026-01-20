
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'bookings_tab.dart';
import '../../services/review_service.dart';
import '../../services/pdf_service.dart';

class BookingDetailPage extends StatefulWidget {
  final Booking booking;

  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final int _selectedIndex = 1; // Default to bookings tab
  final ReviewService _reviewService = ReviewService();
bool _loadingReview = true;
int _currentRating = 0;
String _currentComment = '';
String? _reviewId; // optional
bool _submittingReview = false;
bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 100;
      });
    });
     _loadReview();
  }


Future<void> _loadReview() async {
  try {
    final review = await _reviewService.getReviewForBooking(widget.booking.id); // adjust property name to your Booking model
    if (!mounted || review == null) {
      setState(() => _loadingReview = false);
      return;
    }
    setState(() {
      _reviewId = review['review_id'] as String?;
      _currentRating = review['rating'] as int? ?? 0;
      _currentComment = review['comment'] as String? ?? '';
      _loadingReview = false;
    });
  } catch (_) {
    if (mounted) {
      setState(() => _loadingReview = false);
    }
  }
}


Future<void> _submitReview() async {
  setState(() {
    _submittingReview = true;
  });
  try {
    await _reviewService.submitReview(
      bookingId: widget.booking.id, // adjust property
      rating: _currentRating,
      comment: _currentComment.isEmpty ? null : _currentComment,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review saved')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save review: $e')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _submittingReview = false;
      });
    }
  }
}
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.mainGradient,
            stops: [0.0, 0.2, 0.2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Image.network(
                            widget.booking.hostelImage,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(24),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildTitleSection(),
                              const SizedBox(height: 24),
                              _buildDetailItem(
                                'Check-in',
                                widget.booking.checkIn,
                                Icons.calendar_today_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildDetailItem(
                                'Check-out',
                                widget.booking.checkOut,
                                Icons.event_available_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildDetailItem(
                                'Room Type',
                                widget.booking.roomType,
                                Icons.king_bed_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildDetailItem(
                                'Landlord',
                                widget.booking.landlord,
                                Icons.person_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildDetailItem(
                                'Status',
                                widget.booking.status,
                                Icons.info_outline_rounded,
                              ),
                              const SizedBox(height: 24),
                              _buildPaymentDetails(),
                              const SizedBox(height: 24),
                              _buildReviewSection(),
                              const SizedBox(height: 100),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(context),
    );
  }



Widget _buildReviewSection() {
  // you may also check booking status here (e.g., only allow confirmed/completed)
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Rate your stay',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loadingReview)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = starIndex <= _currentRating;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.rating,
                    ),
                    onPressed: () {
                      setState(() {
                        _currentRating = starIndex;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) => _currentComment = value,
                controller: TextEditingController(text: _currentComment),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: _submittingReview || _currentRating == 0
                        ? null
                        : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _reviewId == null ? 'Submit review' : 'Update review',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
  Widget _buildModernAppBar(BuildContext context) {
    final verticalPadding = _isScrolled ? 8.0 : 12.0;
    final iconSize = _isScrolled ? 20.0 : 24.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(_isScrolled ? 10 : 12),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: iconSize,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.booking.hostelName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
        if (widget.booking.roomNumber != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Room: ${widget.booking.roomNumber}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MK',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(widget.booking.price / 1000).toStringAsFixed(0)}k',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '/month',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                softWrap: true,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          'Booking Date',
          widget.booking.bookingDate,
          Icons.calendar_today_rounded,
        ),
         if (widget.booking.durationMonths != null) ...[
        const SizedBox(height: 16),
        _buildDetailItem(
          'Duration',
          '${widget.booking.durationMonths} ${widget.booking.durationMonths == 1 ? 'month' : 'months'}',
          Icons.calendar_month_rounded,
        ),
      ],
        const SizedBox(height: 16),
        if (widget.booking.baseRoomPrice != null) ...[
        
        _buildDetailItem(
          'Base Room Price',
          'MK${widget.booking.baseRoomPrice!.toStringAsFixed(2)}/month',
          Icons.attach_money_rounded,
        ),
      ],const SizedBox(height: 16),
         if (widget.booking.platformFee != null) ...[
        
        _buildDetailItem(
          'Platform Fee',
          'MK${widget.booking.platformFee!.toStringAsFixed(2)}',
          Icons.receipt_rounded,
        ),
      ],
      const SizedBox(height: 16),
        _buildDetailItem(
          'Total Amount Paid',
          'MK${widget.booking.price.toStringAsFixed(2)}',
          Icons.monetization_on_rounded,
        ),
        if (widget.booking.paymentType != null) ...[
          const SizedBox(height: 16),
          _buildDetailItem(
            'Payment Type',
            widget.booking.paymentType == 'full' ? 'Full Payment' : 'Booking Fee',
            Icons.receipt_long_rounded,
          ),
        ],
        const SizedBox(height: 16),
        _buildDetailItem(
          'Payment Method',
          widget.booking.paymentMethod ?? 'N/A',
          Icons.payment_rounded,
        ),
        const SizedBox(height: 16),
        _buildDetailItem(
          'Transaction ID',
          widget.booking.transactionId ?? 'N/A',
          Icons.receipt_long_rounded,
        ),
        const SizedBox(height: 24),
        // Download PDF Receipt Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: _isDownloading ? null : () async {
              setState(() {
                _isDownloading = true;
              });
              
              try {
                await PdfService.downloadBookingReceipt(widget.booking.id, context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt downloaded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to download receipt: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isDownloading = false;
                  });
                }
              }
            },
            icon: _isDownloading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.download_rounded),
            label: Text(
              _isDownloading ? 'Downloading...' : 'Download Receipt',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.bookmark_outline_rounded, 'Bookings', 1),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 'Messages', 2),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha:0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: AppColors.primaryGradient,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade600,
                ) ?? TextStyle(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabChanged(int index) {
    if (_selectedIndex == index) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/student-dashboard',
      (Route<dynamic> route) => false,
      arguments: {'initialIndex': index},
    );
  }
}
