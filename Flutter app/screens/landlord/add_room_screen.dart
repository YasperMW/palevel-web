import 'dart:convert';
import 'dart:io';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:path/path.dart' as path;

import '../../services/user_session_service.dart';
import '../../config.dart';
import '../../services/hostel_service.dart';

class AddRoomScreen extends StatefulWidget {
  final String hostelId;

  const AddRoomScreen({
    super.key,
    required this.hostelId,
  });

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _roomTypeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile;
  File? _videoFile;
  String? _videoFileName;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _error;
  double? _hostelDefaultPrice;
  bool _isLoading = true;
List<dynamic> _hostelAmenities = [];
String? _hostelDescription;
 final HostelService _hostelService = HostelService();
 static const _maxVideoSize = 50 * 1024 * 1024; // 50MB
final _allowedVideoFormats = {'.mp4', '.mov', '.avi'};

@override
void initState() {
  super.initState();
  _fetchHostelDetails();
} 

Future<void> _fetchHostelDetails() async {
  try {

    final hostel = await _hostelService.getHostel(widget.hostelId);

    
    setState(() {
      // Handle price
      final price = hostel['price_per_month'];
      if (price != null) {
        _hostelDefaultPrice = price is double ? price : double.tryParse(price.toString());
        if (_hostelDefaultPrice != null) {
          _priceController.text = _hostelDefaultPrice!.toStringAsFixed(2);
        }
      }

      // Handle amenities
    final amenities = hostel['amenities'];
    if (amenities == null) {
      _hostelAmenities = [];
    } else if (amenities is List) {
      _hostelAmenities = amenities.where((e) => e != null).map((e) => e.toString()).toList();

    } else if (amenities is String) {
      try {
        final decoded = jsonDecode(amenities);
        if (decoded is Map) {
          // Convert map to list of amenity names where value is true
          _hostelAmenities = (decoded as Map<String, dynamic>)
              .entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();
        } else if (decoded is List) {
          _hostelAmenities = decoded.where((e) => e != null).map((e) => e.toString()).toList();
        } else {
          _hostelAmenities = [decoded.toString()];
        }

      } catch (e) {

        _hostelAmenities = [];
      }
    } else if (amenities is Map) {
      // Handle case where amenities is already a map
      _hostelAmenities = (amenities as Map<String, dynamic>)
          .entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();
    } else {
      _hostelAmenities = [];
    }
    
    // Clean up any empty or invalid entries
    _hostelAmenities = _hostelAmenities
        .where((a) => a != null && a.toString().trim().isNotEmpty)
        .toList();  
      _hostelDescription = hostel['description'];
      _isLoading = false;
    });
  } catch (e) {

    setState(() {
      _error = 'Failed to load hostel details: $e';
      _isLoading = false;
    });
  }
}
Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }


Future<void> _pickVideo() async {
  try {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    
    if (pickedFile != null) {
      // Validate the video file
      await _validateVideo(File(pickedFile.path));

      setState(() {
        _videoFile = File(pickedFile.path);
        // Video thumbnail generation would go here
        _videoFileName = path.basename(pickedFile.path);
      });
    }
  } catch (e) {

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }
}
Future<void> _validateVideo(File file) async {
  // Check file size
  final fileSize = await file.length();
  if (fileSize > _maxVideoSize) {
    throw Exception('Video file is too large. Maximum size is 50MB');
  }

  // Check file extension
  final ext = path.extension(file.path).toLowerCase();
  if (!_allowedVideoFormats.contains(ext)) {
    throw Exception('Unsupported video format. Please use MP4, MOV, or AVI');
  }

  // You can add more validations here if needed
  // For example, checking video duration would require a video player plugin
}

  @override
  void dispose() {
    _roomNumberController.dispose();
    _roomTypeController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Room'),
        backgroundColor: const Color(0xFF07746B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Room Number
              const Text(
                'Room Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF07746B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _roomNumberController,
                decoration: InputDecoration(
                  hintText: 'e.g., A101, B205, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a room number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Room Image
              const Text(
                'Room Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF07746B),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                    color: Colors.grey[50],
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a photo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Room Video
              const Text(
                'Room Video (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF07746B),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                    color: Colors.grey[50],
                  ),
                  child: _videoFile != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_collection_rounded,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                _videoFile!.path.split('/').last,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_call_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add a video',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Room Type
              const Text(
                'Room Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF07746B),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _roomTypeController.text.isEmpty ? null : _roomTypeController.text,
                decoration: InputDecoration(
                  hintText: 'Select room type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(value: 'single-male', child: Text('Single Room - Males only')),
                  DropdownMenuItem(value: 'double-male', child: Text('Double Room - Males only')),
                  DropdownMenuItem(value: 'triple-male', child: Text('Triple Room - Males only')),
                  DropdownMenuItem(value: 'dormitory-male', child: Text('Dormitory - Males only')),
                  DropdownMenuItem(value: 'single-female', child: Text('Single Room - Females only')),
                  DropdownMenuItem(value: 'double-female', child: Text('Double Room - Females only')),
                  DropdownMenuItem(value: 'triple-female', child: Text('Triple Room - Females only')),
                  DropdownMenuItem(value: 'dormitory-female', child: Text('Dormitory - Females only')),
                  DropdownMenuItem(value: 'single-male/female', child: Text('Single Room - Male/Females')),
                  DropdownMenuItem(value: 'double-male/female', child: Text('Double Room - Male/Females')),
                  DropdownMenuItem(value: 'triple-male/female', child: Text('Triple Room - Male/Females')),
                  DropdownMenuItem(value: 'dormitory-male/female', child: Text('Dormitory - Male/Females')),
                  DropdownMenuItem(value: 'studio', child: Text('Studio')),
                  DropdownMenuItem(value: 'apartment', child: Text('Apartment')),
                ],
                onChanged: (value) {
                  setState(() {
                    _roomTypeController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a room type';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Capacity
              const Text(
                'Capacity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF07746B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Number of occupants',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixText: 'people',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid capacity';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Update the price field in the build method
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Price per Month',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF07746B),
      ),
    ),
    if (_hostelDefaultPrice != null) ...[
      const SizedBox(height: 4),
      Text(
        'Default price: MK ${_hostelDefaultPrice!.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
    const SizedBox(height: 4),
    TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: _isLoading ? 'Loading...' : 'Enter monthly rent amount',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixText: 'MK ',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter price';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Please enter a valid price';
        }
        return null;
      },
    ),
  ],
),
// Add this after the price field
const SizedBox(height: 20),

// Hostel Amenities Section
if (_hostelAmenities.isNotEmpty) ...[
  const Text(
    'Hostel Amenities',
    style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF07746B),
    ),
  ),
  const SizedBox(height: 16),
  Wrap(
    spacing: 12,
    runSpacing: 12,
    children: _hostelAmenities.map<Widget>((amenity) {
      final amenityStr = amenity.toString().trim();
      if (amenityStr.isEmpty) return const SizedBox.shrink();
      
      // Map common amenity names to icons for better visual representation
      IconData? iconData;
      switch (amenityStr.toLowerCase()) {
        case 'wifi':
          iconData = Icons.wifi_rounded;
          break;
        case 'security':
          iconData = Icons.security_rounded;
          break;
        case 'parking':
          iconData = Icons.local_parking_rounded;
          break;
        case 'laundry':
          iconData = Icons.local_laundry_service_rounded;
          break;
        case 'kitchen':
          iconData = Icons.kitchen_rounded;
          break;
        case 'gym':
          iconData = Icons.fitness_center_rounded;
          break;
        case 'swimming pool':
          iconData = Icons.pool_rounded;
          break;
        default:
          iconData = Icons.check_circle_rounded;
      }
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF07746B).withValues(alpha:0.1),
              const Color(0xFF0DDAC9).withValues(alpha:0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF07746B).withValues(alpha:0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 18,
              color: const Color(0xFF07746B),
            ),
            const SizedBox(width: 8),
            Text(
              amenityStr.splitMapJoin(
                RegExp(r'[A-Z]'),
                onMatch: (m) => ' ${m.group(0)}',
                onNonMatch: (n) => n,
              ).trim(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF07746B),
              ),
            ),
          ],
        ),
      );
    }).toList(),
  ),
  const SizedBox(height: 24),
],
// Show description if available
if (_hostelDescription != null && _hostelDescription!.isNotEmpty) ...[
  const Text(
    'Hostel Description',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xFF07746B),
    ),
  ),
  const SizedBox(height: 8),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Text(
      _hostelDescription!,
      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
    ),
  ),
  const SizedBox(height: 8),
],
              
              
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF07746B), Color(0xFF0DDAC9)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Adding Room...'),
                      ],
                    )
                        : const Text(
                      'Add Room',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

Future<void> _submitForm() async {
   if (!_formKey.currentState!.validate()) {
    return;
  }

  if (_imageFile == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for the room'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  setState(() {
    _isSubmitting = true;
    _error = null;
  });

  try {
    final userEmail = await UserSessionService.getUserEmail();
    if (userEmail == null) {
      throw Exception('User not logged in');
    }

    // 1. First, create the room
    final roomResponse = await _createRoom(userEmail);
    if (roomResponse == null) {
      throw Exception('Failed to create room');
    }

    // 2. If video exists, upload it separately
    if (_videoFile != null) {
      await _uploadVideo(roomResponse['room_id'], userEmail);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  } catch (e) {

    
    String errorMessage = 'Error adding room';
    if (e is http.ClientException) {
      errorMessage = 'Network error: ${e.message}';
    } else if (e is FormatException) {
      errorMessage = 'Error parsing server response';
    } else if (e is SocketException) {
      errorMessage = 'Network connection error';
    } else {
      errorMessage = 'Error: ${e.toString()}';
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    
    setState(() {
      _error = errorMessage;
    });
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

// Helper method to create room
Future<Map<String, dynamic>?> _createRoom(String userEmail) async {

  
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          '$kBaseUrl/rooms/'), // Note the trailing slash to match the backend endpoint
    );

    // Add text fields
    request.fields.addAll({
      'hostel_id': widget.hostelId,
      'room_number': _roomNumberController.text.trim(),
      'room_type': _roomTypeController.text.trim(),
      'capacity': _capacityController.text.trim(),
      'price_per_month': _priceController.text.trim(),
      'landlord_email': userEmail,
    });

    // Add image file
    final image = await http.MultipartFile.fromPath(
      'image', // Changed from 'file' to 'image' to match backend parameter name
      _imageFile!.path,
      filename: 'room_${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg',
    );
    request.files.add(image);


    final response = await request.send();
    final responseData = await response.stream.bytesToString();



    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseJson = jsonDecode(responseData);

      return responseJson;
    } else {
      final errorMsg = 'Failed to create room: ${response
          .statusCode} - $responseData';

      throw Exception(errorMsg);
    }
  } catch (e) {

    rethrow; // Re-throw to be caught by the parent's try-catch
  }
}

// Helper method to upload video
Future<void> _uploadVideo(String roomId, String userEmail) async {
  try {

    final uploadUrl = Uri.parse('$kBaseUrl/rooms/$roomId/media/');

    
    var request = http.MultipartRequest(
      'POST',
      uploadUrl,
    );

    // Add all required fields for media upload
    request.fields.addAll({
      'media_type': 'video',
      'uploader_email': userEmail,
      'is_cover': 'false',  // Set to true if this should be the cover media
      'display_order': '0',  // Set the display order
    });
    

    
    var video = await http.MultipartFile.fromPath(
      'file',
      _videoFile!.path,
      filename: _videoFileName ?? 'room_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      contentType: MediaType('video', 'mp4'),
    );
    
    request.files.add(video);

    

    final response = await request.send();

    
    final responseData = await response.stream.bytesToString();
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload video: ${response.statusCode} - $responseData');
    }
  } catch (e) {

    // You might want to show a warning but not fail the entire operation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room created, but video upload failed: $e')),
      );
    }
  }
}
}
