// lib/screens/landlord/payment_preferences_screen.dart
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/payment_method.dart';

import 'add_payment_method_screen.dart';

class PaymentPreferencesScreen extends StatefulWidget {
  const PaymentPreferencesScreen({super.key});

  @override
  State<PaymentPreferencesScreen> createState() => _PaymentPreferencesScreenState();
}

class _PaymentPreferencesScreenState extends State<PaymentPreferencesScreen> {
  bool _isLoading = true;
  List<PaymentMethod> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

Future<void> _loadPaymentMethods() async {
  setState(() => _isLoading = true);
  try {
    final response = await ApiService.getPaymentPreferences();
    if (mounted) {
      setState(() {
        // The backend now returns a list of payment methods directly
        final paymentMethods = response['paymentMethods'] ?? [];
        _paymentMethods = (paymentMethods is List)
            ? paymentMethods
                .where((item) => item != null)
                .map((item) => PaymentMethod.fromJson(item))
                .toList()
            : <PaymentMethod>[];
        
        // Find the preferred method
        if (_paymentMethods.isNotEmpty) {
          _paymentMethods = _paymentMethods.map((method) {
            // First, find if there's a preferred method
            final hasPreferred = _paymentMethods.any((m) => m.isPreferred);
            // If no preferred method exists, make the first one preferred
            if (!hasPreferred && _paymentMethods.isNotEmpty) {
              if (method == _paymentMethods.first) {
                return method.copyWith(isPreferred: true);
              }
            }
            return method;
          }).toList();
        } else {
          // Preferred method would be reset here
        }
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load payment methods: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

Future<void> _setPreferredPaymentMethod(String methodId) async {
  try {
    await ApiService.setPreferredPaymentMethod(methodId);
    if (mounted) {
      setState(() {
        // Preferred method would be updated here
        _paymentMethods = _paymentMethods.map((method) {
          return method.copyWith(
            isPreferred: method.id == methodId,
          );
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferred payment method updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update preferred method: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _deletePaymentMethod(String methodId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: const Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deletePaymentMethod(methodId);
      if (mounted) {
        await _loadPaymentMethods();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method deleted'),
              backgroundColor: Color(0xFF07746B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete payment method: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods',
        style: TextStyle(
          color: Colors.white
        ),
        ),
        backgroundColor: const Color(0xFF07746B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),
          );
          if (result == true && mounted) {
            await _loadPaymentMethods();
          }
        },
        backgroundColor: const Color(0xFF07746B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_paymentMethods.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No payment methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add a payment method to receive payments',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods[index];
        return _buildPaymentMethodCard(method);
      },
    );
  }

 Widget _buildPaymentMethodCard(PaymentMethod method) {
  final isPreferred = method.isPreferred;
  
  // Get display type and icon based on payment method type
  String displayType;
  IconData displayIcon;
  
  if (method.type == 'bank_transfer') {
    displayType = 'Bank Transfer';
    displayIcon = Icons.account_balance;
  } else if (method.type == 'mobile_money') {
    displayType = 'Mobile Money';
    displayIcon = Icons.phone_android;
  } else {
    displayType = method.type;
    displayIcon = Icons.payment;
  }
  
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: isPreferred 
          ? const BorderSide(color: Color(0xFF07746B), width: 2) 
          : BorderSide.none,
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(
        displayIcon,
        size: 32,
        color: const Color(0xFF07746B),
      ),
      title: Text(
        displayType,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show bank/provider name for both types
          if (method.details['bankName'] != null)
            Text(
              method.details['bankName'],
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF07746B)),
            ),
          // Show account number for bank transfers
          if (method.type == 'bank_transfer' && method.details['accountNumber'] != null) 
            Text(
              method.details['accountNumber'].toString().length > 4
                  ? 'Account: •••• ${method.details['accountNumber'].toString().substring(method.details['accountNumber'].toString().length - 4)}'
                  : 'Account: ${method.details['accountNumber'].toString()}',
            ),
          // Show account name for bank transfers
          if (method.type == 'bank_transfer' && method.details['accountName'] != null)
            Text(
              method.details['accountName'],
              style: TextStyle(color: Colors.grey[600]),
            ),
          // Show mobile number for mobile money
          if (method.type == 'mobile_money' && method.details['mobileNumber'] != null)
            Text(
              'Phone: +256 ${method.details['mobileNumber']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPreferred)
            const Icon(Icons.star, color: Colors.amber),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (!isPreferred)
                const PopupMenuItem(
                  value: 'set_preferred',
                  child: Text('Set as preferred'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) async {
              if (value == 'set_preferred') {
                await _setPreferredPaymentMethod(method.id);
              } else if (value == 'delete') {
                await _deletePaymentMethod(method.id);
              }
            },
          ),
        ],
      ),
    ),
  );
}
}