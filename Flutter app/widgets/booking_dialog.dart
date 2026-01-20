import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDialog {
  /// Shows a responsive booking dialog as a keyboard-aware bottom sheet.
  /// Returns a map with keys: `startDate`, `duration`, `phoneNumber` on success.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Map<String, dynamic> hostel,
    required Map<String, dynamic> room,
    String? initialPhone,
  }) async {
    
    final roomPrice = (room['price_per_month'] ?? 0).toDouble();
    final bookingFee = (room['booking_fee'] ?? 0); 
    const platformFee = 2500.0; // PalLevel platform fee
    final startDateController = TextEditingController();
    final durationController = TextEditingController(text: '1');
    final phoneController = TextEditingController(text: initialPhone ?? '');
    bool listenersAttached = false;
    bool payFullAmount = false; // Toggle between booking fee and full amount
    String? errorMessage; // Track validation errors

    // showModalBottomSheet with isScrollControlled so it can expand above keyboard
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        // Use SafeArea + Padding using viewInsets so the sheet moves above keyboard
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return StatefulBuilder(builder: (context, setState) {
                  // Attach listeners once so the AnimatedSwitcher and UI
                  // update when controller values change (live total update).
                  if (!listenersAttached) {
                    durationController.addListener(() {
                      setState(() {});
                    });
                    startDateController.addListener(() {
                      setState(() {});
                    });
                    listenersAttached = true;
                  }

                  // no autofocus requested here

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // grab handle
                          Center(
                            child: Container(
                              width: 48,
                              height: 6,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),

                          Text(
                            'Book This Room',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${hostel['name'] ?? hostel['title'] ??
                                      ''} - Room ${room['room_number'] ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text('Type: ${room['room_type'] ??
                                    room['type'] ?? ''}'),
                                Text('Price: MWK ${room['price_per_month']
                                    ?.toStringAsFixed(2) ?? ''}/month'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Start Date (read-only trigger)
                          TextFormField(
                            controller: startDateController,
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              suffixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                    const Duration(days: 365)),
                              );
                              if (date != null) {
                                startDateController.text =
                                '${date.year}-${date.month.toString().padLeft(
                                    2, '0')}-${date.day.toString().padLeft(
                                    2, '0')}';
                                // scroll to bottom so total/controls are visible
                                await Future.delayed(
                                    const Duration(milliseconds: 50));
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // Duration
                          TextFormField(
                            controller: durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (months)',
                              border: OutlineInputBorder(),
                              suffixText: 'months',
                            ),
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 16),

                          // Phone
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixText: '+265 ',
                              border: OutlineInputBorder(),
                              hintText: '991234567',
                            ),
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 16),

                          // Payment options
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Option',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: RadioGroup<bool>(
                                  groupValue: payFullAmount,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        payFullAmount = value;
                                      });
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      RadioListTile<bool>(
                                        title: Text('Pay Booking Fee Only (MWK ${bookingFee.toStringAsFixed(2)})'),
                                        value: false,
                                      ),
                                      RadioListTile<bool>(
                                        title: Text('Pay Full Amount (MWK ${(roomPrice * (int.tryParse(durationController.text) ?? 1)).toStringAsFixed(2)})'),
                                        value: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Total amount preview
                          Builder(builder: (ctx) {
                            final dur = int.tryParse(durationController.text) ?? 0;
                            // Show total live based on duration (no need to wait for user edits)
                            final showTotal = dur > 0;
                            final totalAmount = payFullAmount
                                ? (roomPrice * dur) + platformFee
                                : bookingFee + platformFee;
                            final currencyFormat = NumberFormat.currency(
                              symbol: 'MWK ',
                              decimalDigits: 2,
                            );
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: showTotal
                                  ? Container(
                                key: ValueKey('total-$payFullAmount'),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFB2EBF2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (payFullAmount) ...[
                                      _buildFeeRow('Room ($dur ${dur > 1 ? 'months' : 'month'})', roomPrice * dur, currencyFormat),
                                      const SizedBox(height: 4),
                                    ],
                                    if (!payFullAmount)
                                      _buildFeeRow('Booking Fee', bookingFee, currencyFormat),
                                    _buildFeeRow('PalLevel Platform Fee', platformFee, currencyFormat),
                                    const Divider(thickness: 1, height: 24),
                                    _buildFeeRow('Total Amount', totalAmount, currencyFormat, isBold: true),
                                  ],
                                ),
                              )
                                  : const SizedBox.shrink(),
                            );
                          }),

                          const SizedBox(height: 20),

                          // Error message display
                          if (errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF0000), Color(0xFF880808)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide.none,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF07746B), Color(0xFF0DDAC9)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final dur = int.tryParse(durationController.text) ?? 0;

                                      setState(() {
                                        errorMessage = null;
                                      });

                                      if (startDateController.text.isEmpty) {
                                        setState(() {
                                          errorMessage = 'Please select a start date';
                                        });
                                        return;
                                      }

                                      if (dur <= 0) {
                                        setState(() {
                                          errorMessage = 'Please enter a valid duration (greater than 0)';
                                        });
                                        return;
                                      }

                                      if (phoneController.text.isEmpty) {
                                        setState(() {
                                          errorMessage = 'Please enter your phone number';
                                        });
                                        return;
                                      }

                                      final totalAmount = payFullAmount
                                          ? (roomPrice * dur) + platformFee
                                          : bookingFee + platformFee;

                                      Navigator.pop(context, {
                                        'startDate': startDateController.text,
                                        'duration': dur,
                                        'phoneNumber': phoneController.text,
                                        'amount': totalAmount,
                                        'isFullPayment': payFullAmount,
                                        'bookingFee': bookingFee,
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide.none,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Proceed to Payment',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),


                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
                );
              },

            )),
          );
            },
    );

    // no focus nodes to dispose

    return result;
  }

  static Widget _buildFeeRow(String label, double amount, NumberFormat formatter, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF00796B) : null,
            ),
          ),
        ],
      ),
    );
  }
}
