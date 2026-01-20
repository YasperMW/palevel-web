// lib/screens/landlord/add_payment_method_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingBanks = false;
  String _selectedType = 'bank_transfer';
  String? _selectedBankUuid;
  String? _selectedBankName;
  List<Map<String, dynamic>> _banksAndProviders = [];
  final Map<String, TextEditingController> _controllers = {
    'accountNumber': TextEditingController(),
    'accountName': TextEditingController(),
    'bankName': TextEditingController(),
    'mobileNumber': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() => _isLoadingBanks = true);
    try {
      final banks = await ApiService.getBanksAndProviders();
      setState(() {
        _banksAndProviders = banks;
        _isLoadingBanks = false;
      });
    } catch (e) {
      setState(() => _isLoadingBanks = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load banks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final paymentMethod = {
        'preferred_method': _selectedType,
        'account_number': _controllers['accountNumber']?.text,
        'account_name': _controllers['accountName']?.text,
        'bank_name': _selectedBankName,
        'bank_uuid': _selectedBankUuid,
        // Only include mobile_number if it's a mobile money payment
        if (_selectedType == 'mobile_money')
          'mobile_number': _controllers['mobileNumber']?.text,
      };

      // Remove null values from map
      paymentMethod.removeWhere((key, value) => value == null || value.toString().isEmpty);

      await ApiService.addPaymentMethod(paymentMethod);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add payment method: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Method',
        style: TextStyle(
          color: Color(0xFFFFFFFF)
        ),
        ),
        backgroundColor: const Color(0xFF07746B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading || _isLoadingBanks
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    if (_selectedType == 'bank_transfer') ..._buildBankTransferFields(),
                    if (_selectedType == 'mobile_money') ..._buildMobileMoneyFields(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _savePaymentMethod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF07746B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Payment Method',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: const [
            DropdownMenuItem(
              value: 'bank_transfer',
              child: Text('Bank Transfer'),
            ),
            DropdownMenuItem(
              value: 'mobile_money',
              child: Text('Mobile Money'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
                _selectedBankUuid = null; // Reset selection when type changes
                _selectedBankName = null;
              });
            }
          },
        ),
      ],
    );
  }

  List<Widget> _buildBankTransferFields() {
    return [
      TextFormField(
        controller: _controllers['accountNumber'],
        decoration: const InputDecoration(
          labelText: 'Account Number',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter account number';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _controllers['accountName'],
        decoration: const InputDecoration(
          labelText: 'Account Name',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter account name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildBankDropdown(),
    ];
  }

  Widget _buildBankDropdown() {
    // Filter banks and mobile money providers based on payment type
    List<Map<String, dynamic>> filteredProviders = _banksAndProviders.where((provider) {
      if (_selectedType == 'bank_transfer') {
        // Only show banks (exclude mobile money providers)
        return !provider['name'].toLowerCase().contains('money') && 
               !provider['name'].toLowerCase().contains('mpamba') && 
               !provider['name'].toLowerCase().contains('airtel');
      } else if (_selectedType == 'mobile_money') {
        // Only show mobile money providers
        return provider['name'].toLowerCase().contains('money') || 
               provider['name'].toLowerCase().contains('mpamba') || 
               provider['name'].toLowerCase().contains('airtel');
      }
      return false;
    }).toList();

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: _selectedType == 'mobile_money' ? 'Mobile Money Provider' : 'Bank Name',
        border: const OutlineInputBorder(),
        errorText: _selectedBankUuid == null ? 'Please select a bank or provider' : null,
      ),
      items: filteredProviders.map<DropdownMenuItem<String>>((bank) {
        return DropdownMenuItem<String>(
          value: bank['uuid'] as String,
          child: Text(bank['name']),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedBankUuid = value;
            _selectedBankName = _banksAndProviders.firstWhere((bank) => bank['uuid'] == value)['name'];
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a bank or provider';
        }
        return null;
      },
    );
  }

  List<Widget> _buildMobileMoneyFields() {
    return [
      _buildBankDropdown(),
      const SizedBox(height: 16),
      TextFormField(
        controller: _controllers['mobileNumber'],
        decoration: const InputDecoration(
          labelText: 'Mobile Number',
          border: OutlineInputBorder(),
          prefixText: '+256 ',
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter mobile number';
          }
          if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
            return 'Please enter a valid mobile number';
          }
          return null;
        },
      ),
    ];
  }
}