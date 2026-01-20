import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config.dart';
import '../../services/room_service.dart';
import '../../services/media_service.dart';
import '../../services/user_session_service.dart';

class EditRoomScreen extends StatefulWidget {
  final Map<String, dynamic> room;
  final String hostelId;

  const EditRoomScreen({
    super.key,
    required this.room,
    required this.hostelId,
  });

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedRoomType;
  bool _isOccupied = false;
  final bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _roomTypes = [
    'single-male',
    'double-male',
    'triple-male',
    'dormitory-male',
    'single-female',
    'double-female',
    'triple-female',
    'dormitory-female',
    'single-male/female',
    'double-male/female',
    'triple-male/female',
    'dormitory-male/female',
    'studio',
    'apartment',
  ];

  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  List<Map<String, dynamic>> _existingMedia = [];
  bool _isMediaLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _fetchExistingMedia();
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final room = widget.room;
    _roomNumberController.text = room['room_number'] ?? '';
    _capacityController.text = room['capacity']?.toString() ?? '';
    _priceController.text = room['price_per_month']?.toString() ?? '';
    _selectedRoomType = room['type']?.toString() ?? _roomTypes.first;
    _isOccupied = room['is_occupied'] as bool? ?? false;
  }

  Future<void> _fetchExistingMedia() async {
    if (mounted) setState(() => _isMediaLoading = true);
    try {
      final mediaService = MediaService();
      final media = await mediaService.getRoomMedia(widget.room['room_id']);
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
      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick images')),
        );
      }
    }
  }

  Future<void> _updateRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) setState(() => _isSaving = true);

    try {
      final roomService = RoomService();

      await roomService.updateRoom(
        roomId: widget.room['room_id'],
        roomNumber: _roomNumberController.text,
        roomType: _selectedRoomType,
        capacity: int.tryParse(_capacityController.text),
        pricePerMonth: double.tryParse(_priceController.text),
        isOccupied: _isOccupied,
      );

      if (_selectedImages.isNotEmpty) {
        final userEmail = await UserSessionService.getUserEmail();
        if (userEmail != null) {
          final mediaService = MediaService();
          for (var imageFile in _selectedImages) {
            await mediaService.uploadHostelMedia(
              hostelId: widget.hostelId,
              filePath: imageFile.path,
              fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              mediaType: 'image',
              uploaderEmail: userEmail,
              isCover: _existingMedia.isEmpty && _selectedImages.first == imageFile,
              displayOrder: _existingMedia.length + _selectedImages.indexOf(imageFile),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF07746B),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update room: ${e.toString()}'),
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
          Text(
            'Edit Room ${widget.room['room_number']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _isSaving ? null : _updateRoom,
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
              _buildSectionTitle('Room Details'),
              _buildFormField(
                label: 'Room Number',
                controller: _roomNumberController,
                prefixIcon: Icon(Icons.tag, color: Colors.grey[600]),
              ),
              _buildDropdownField(
                label: 'Room Type',
                value: _selectedRoomType,
                items: _roomTypes,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRoomType = value);
                  }
                },
                prefixIcon: Icon(Icons.king_bed_outlined, color: Colors.grey[600]),
              ),
              _buildFormField(
                label: 'Capacity',
                controller: _capacityController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.people_outline, color: Colors.grey[600]),
              ),
              _buildFormField(
                label: 'Monthly Rent',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.attach_money_outlined, color: Colors.grey[600]),
              ),
              SwitchListTile(
                title: const Text('Room Occupied'),
                value: _isOccupied,
                onChanged: (val) => setState(() => _isOccupied = val),
                activeThumbColor: const Color(0xFF07746B),
                contentPadding: EdgeInsets.zero,
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
                  if (value == null || value.isEmpty) return 'Required';
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
    // Map lowercase values to display text
    final Map<String, String> displayMap = {
      'single-male': 'Single Room - Males only',
      'double-male': 'Double Room - Males only',
      'triple-male': 'Triple Room - Males only',
      'dormitory-male': 'Dormitory - Males only',
      'single-female': 'Single Room - Females only',
      'double-female': 'Double Room - Females only',
      'triple-female': 'Triple Room - Females only',
      'dormitory-female': 'Dormitory - Females only',
      'single-male/female': 'Single Room - Male/Females',
      'double-male/female': 'Double Room - Male/Females',
      'triple-male/female': 'Triple Room - Male/Females',
      'dormitory-male/female': 'Dormitory - Male/Females',
      'studio': 'Studio',
      'apartment': 'Apartment',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(displayMap[item] ?? item, style: const TextStyle(fontSize: 15)),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: _inputDecoration(prefixIcon),
            validator: (value) => (value == null || value.isEmpty) ? 'Please select a value' : null,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 28),
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(Widget? prefixIcon) {
    return InputDecoration(
      prefixIcon: prefixIcon != null ? Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: prefixIcon) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF07746B), width: 1.5)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
    );
  }

  Widget _buildPhotoGrid() {
    if (_isMediaLoading) return const Center(child: CircularProgressIndicator());
    if (_existingMedia.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: _existingMedia.length,
      itemBuilder: (context, index) {
        final media = _existingMedia[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                media['url'].startsWith('http') ? media['url'] : '$kBaseUrl/uploads/${media['url']}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50),
              ),
            ),
            // Add delete button if needed
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
        label: const Text('Add Photos'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF07746B),
          side: const BorderSide(color: Color(0xFF07746B)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildNewPhotosPreview() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('New Photos:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
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
                  child: Image.file(_selectedImages[index], width: 100, height: 100, fit: BoxFit.cover),
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
        onPressed: _isSaving ? null : _updateRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF07746B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          shadowColor: const Color(0xFF07746B).withValues(alpha:0.3),
        ),
        child: _isSaving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('SAVE CHANGES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ),
    );
  }
}
