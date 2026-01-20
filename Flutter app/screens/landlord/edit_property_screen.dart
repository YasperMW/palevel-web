import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config.dart';
import '../../services/hostel_service.dart';
import '../../services/media_service.dart';
import '../../widgets/location_map_dialog.dart';
import 'location_picker_screen.dart';
import '../../services/user_session_service.dart';

class EditPropertyScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const EditPropertyScreen({
    super.key,
    required this.property,
  });

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _bookingFeeController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedUniversity;
  String? _selectedPropertyType;

  final List<String> _propertyTypes = ['Private', 'Shared', 'Other'];

  final List<String> _districts = [
    'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Chitipa', 'Dedza', 'Dowa', 'Karonga', 'Kasungu',
    'Likoma', 'Lilongwe', 'Machinga', 'Mangochi', 'Mchinji', 'Mulanje', 'Mwanza', 'Mzimba', 'Nkhata Bay',
    'Nkhotakota', 'Nsanje', 'Ntcheu', 'Ntchisi', 'Phalombe', 'Rumphi', 'Salima', 'Thyolo', 'Zomba'
  ];

  final List<String> _universities = [
    "University of Malawi (UNIMA)",
    "Malawi University of Science and Technology (MUST)",
    "Lilongwe University of Agriculture and Natural Resources (LUANAR)",
    "Mzuzu University (MZUNI)",
    "Malawi University of Business and Applied Sciences (MUBAS)",
    "Kamuzu University of Health Sciences (KUHeS)",
  ];

  final bool _isLoading = false;
  bool _isSaving = false;

  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  List<Map<String, dynamic>> _existingMedia = [];
  bool _isMediaLoading = false;
  
  // Location data
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedAddress = 'Tap to select location';

  @override
  void initState() {
    super.initState();
    _initializeForm();

    _fetchExistingMedia();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _monthlyRentController.dispose();
    _bookingFeeController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final property = widget.property;
    _nameController.text = property['name'] ?? '';
    _addressController.text = property['address'] ?? '';
    _descriptionController.text = property['description'] ?? '';
    _monthlyRentController.text = property['price_per_month']?.toString() ?? '';
    _bookingFeeController.text = property['booking_fee']?.toString() ?? '0';
    _selectedDistrict = property['district'];
    _selectedUniversity = property['university'];
    _selectedPropertyType = property['type'] ?? 'Private';
    
    // Initialize location data
    final lat = property['latitude'];
    final lng = property['longitude'];
    
    if (lat != null) {
      if (lat is num) {
        _selectedLatitude = lat.toDouble();
      } else if (lat is String) {
        _selectedLatitude = double.tryParse(lat);
      }
    }
    
    if (lng != null) {
      if (lng is num) {
        _selectedLongitude = lng.toDouble();
      } else if (lng is String) {
        _selectedLongitude = double.tryParse(lng);
      }
    }
    
    if (_selectedLatitude != null && _selectedLongitude != null) {
      _selectedAddress = property['address'] ?? 'Location selected';
    }
  }


  Future<void> _fetchExistingMedia() async {
    if (mounted) setState(() => _isMediaLoading = true);
    try {
      final mediaService = MediaService();
      final media = await mediaService.getHostelMedia(widget.property['hostel_id']);
      if (mounted) {
        setState(() {
          _existingMedia = media;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isMediaLoading = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick images')),
        );
      }
    }
  }

  Future<void> _deleteImage(Map<String, dynamic> media, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text(
              'Are you sure you want to delete this image? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final mediaService = MediaService();
      await mediaService.deleteMedia(media['media_id']);
      if (mounted) {
        setState(() {
          _existingMedia.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
        _selectedAddress = result['address'] ?? 'Location selected';
        // Don't automatically update address controller - only update coordinates
        // The address field should remain as typed by the user
        // Only update address if it was empty initially
        if (_addressController.text.trim().isEmpty && 
            result['address'] != null && 
            result['address'].toString().isNotEmpty) {
          _addressController.text = result['address'];
        }
      });
    }
  }

  void _viewLocation() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      LocationMapDialog.show(
        context: context,
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        title: _nameController.text.isNotEmpty ? _nameController.text : 'Property Location',
        address: _addressController.text.isNotEmpty ? _addressController.text : _selectedAddress,
        markerLabel: _nameController.text.isNotEmpty ? _nameController.text : null,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location set. Please select a location first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) setState(() => _isSaving = true);

    try {
      final hostelService = HostelService();
      final userEmail = await UserSessionService.getUserEmail();

      await hostelService.updateHostel(
        hostelId: widget.property['hostel_id'],
        name: _nameController.text,
        address: _addressController.text,
        district: _selectedDistrict!,
        university: _selectedUniversity!,
        description: _descriptionController.text,
        pricePerMonth: double.tryParse(_monthlyRentController.text),
        bookingFee: double.tryParse(_bookingFeeController.text) ?? 0.0,
        type: _selectedPropertyType ?? 'Private',
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      if (_selectedImages.isNotEmpty) {
        final mediaService = MediaService();
        for (var image in _selectedImages) {
          await mediaService.uploadHostelMedia(
            hostelId: widget.property['hostel_id'],
            filePath: image.path,
            fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            mediaType: 'image',
            uploaderEmail: userEmail ?? 'unknown@example.com',
            isCover: _existingMedia.isEmpty && _selectedImages.indexOf(image) == 0,
            displayOrder: _existingMedia.length + _selectedImages.indexOf(image),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF07746B),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update property: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07746B),
              Color(0xFF0DDAC9),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildFormContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Edit Property',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _isSaving ? null : _updateProperty,
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Property Information'),
              _buildDropdownField(
                label: 'Property Type',
                value: _selectedPropertyType,
                items: _propertyTypes,
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyType = value;
                  });
                },
                prefixIcon: Icon(Icons.house_outlined, color: Colors.grey[600]),
              ),
              _buildFormField(
                label: 'Property Name',
                controller: _nameController,
                prefixIcon: Icon(Icons.apartment_outlined, color: Colors.grey[600]),
              ),
              _buildDropdownSearch(
                label: 'District',
                items: _districts,
                selectedItem: _selectedDistrict,
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value;
                  });
                },
                prefixIcon: Icon(Icons.location_city_outlined, color: Colors.grey[600]),
              ),
              _buildDropdownSearch(
                label: 'Nearest University',
                items: _universities,
                selectedItem: _selectedUniversity,
                onChanged: (value) {
                  setState(() {
                    _selectedUniversity = value;
                  });
                },
                prefixIcon: Icon(Icons.school_outlined, color: Colors.grey[600]),
              ),
              _buildFormField(
                label: 'Address',
                controller: _addressController,
                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
              ),
              // Location Picker Section
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property Location',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: _selectedLatitude != null && _selectedLongitude != null
                                        ? const Color(0xFF07746B)
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedLatitude != null && _selectedLongitude != null
                                              ? 'Location Selected'
                                              : 'Tap to select location',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: _selectedLatitude != null && _selectedLongitude != null
                                                ? Colors.black87
                                                : Colors.grey[600],
                                            fontWeight: _selectedLatitude != null && _selectedLongitude != null
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (_selectedLatitude != null && _selectedLongitude != null)
                                          Text(
                                            'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, Lng: ${_selectedLongitude!.toStringAsFixed(6)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit_location_alt,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_selectedLatitude != null && _selectedLongitude != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.map, color: Color(0xFF07746B)),
                            onPressed: _viewLocation,
                            tooltip: 'View on Map',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF07746B).withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildFormField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              _buildSectionTitle('Financials'),
              _buildFormField(
                label: 'Monthly Rent',
                controller: _monthlyRentController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.attach_money_outlined, color: Colors.grey[600]),
              ),
              _buildFormField(
                label: 'Booking Fee',
                controller: _bookingFeeController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.money_outlined, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              _buildSectionTitle('Photos'),
              _buildPhotoGrid(),
              const SizedBox(height: 16),
              _buildAddPhotosButton(),
              _buildNewPhotosPreview(),
              const SizedBox(height: 16),
              _buildSaveChangesButton(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
    Widget? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(prefixIcon),
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    Widget? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: _inputDecoration(prefixIcon),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a value';
              }
              return null;
            },
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 28),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSearch({
    required String label,
    required List<String> items,
    required String? selectedItem,
    required Function(String?) onChanged,
    Widget? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownSearch<String>(
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: "Search...",
                ),
              ),
            ),
            items: (f, cs) => items,
            selectedItem: selectedItem,
            decoratorProps: DropDownDecoratorProps(
              decoration: _inputDecoration(prefixIcon),
            ),
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a value';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(Widget? prefixIcon) {
    return InputDecoration(
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: prefixIcon,
            )
          : null,
      prefixIconConstraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF07746B), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
    );
  }

  Widget _buildPhotoGrid() {
    if (_isMediaLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_existingMedia.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _existingMedia.length,
      itemBuilder: (context, index) {
        final media = _existingMedia[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                media['url'].startsWith('http')
                    ? media['url']
                    : '$kBaseUrl/uploads/${media['url']}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 50);
                },
              ),
            ),
            if (media['is_cover'] == true)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.star, color: Colors.amber, size: 20),
              ),
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () => _deleteImage(media, index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPhotosButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _pickImages,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add More Photos'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF07746B),
          side: const BorderSide(color: Color(0xFF07746B)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPhotosPreview() {
    if (_selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'New Photos to Upload:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveChangesButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateProperty,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF07746B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF07746B).withValues(alpha: 0.3),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'SAVE CHANGES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
