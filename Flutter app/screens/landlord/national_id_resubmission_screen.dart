import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class NationalIdResubmissionScreen extends StatefulWidget {
  const NationalIdResubmissionScreen({super.key});

  @override
  State<NationalIdResubmissionScreen> createState() => _NationalIdResubmissionScreenState();
}

class _NationalIdResubmissionScreenState extends State<NationalIdResubmissionScreen> {
  File? _idImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB
        
        if (fileSize > maxSize) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size must be less than 5MB')),
          );
          return;
        }
        
        // Check file type
        final ext = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only JPG and PNG images are allowed')),
          );
          return;
        }
        
        setState(() {
          _idImage = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image. Please try again.')),
      );
    }
  }

  Future<void> _submitResubmission() async {
    if (_idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a national ID image')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.resubmitNationalId(_idImage!);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('National ID resubmitted successfully! We will review it within 1-2 business days.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to profile
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resubmit ID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final cardBorderRadius = (screenWidth * 0.08).clamp(24.0, 32.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Resubmit National ID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF07746B), Color(0xFF0DDAC9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: (screenWidth * 0.04).clamp(12.0, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Header
                Text(
                  'Resubmit Your National ID',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.06).clamp(20.0, 28.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Anta',
                  ),
                ),
                const SizedBox(height: 6),
                
                Text(
                  'Please upload a clear, recent image of your national ID document for verification.',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
                    color: Colors.white.withValues(alpha:0.9),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Main Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all((screenWidth * 0.04).clamp(12.0, 20.0)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(cardBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructions
                      const Text(
                        'Requirements:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF07746B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildRequirementItem('• Clear and readable image'),
                      _buildRequirementItem('• All four corners visible'),
                      _buildRequirementItem('• No glare or shadows'),
                      _buildRequirementItem('• File size less than 5MB'),
                      _buildRequirementItem('• Format: JPG or PNG'),
                      
                      const SizedBox(height: 16),
                      
                      // Upload Area
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _idImage == null 
                                  ? const Color(0xFF07746B).withValues(alpha:0.3)
                                  : const Color(0xFF07746B),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF07746B).withValues(alpha:0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _idImage == null
                              ? _buildUploadPlaceholder(screenWidth)
                              : _buildUploadedPreview(screenWidth),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitResubmission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF07746B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(cardBorderRadius),
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Submitting...'),
                                  ],
                                )
                              : const Text(
                                  'Resubmit for Verification',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(double screenWidth) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF07746B).withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            color: Color(0xFF07746B),
            size: 40,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload National ID',
          style: TextStyle(
            color: const Color(0xFF07746B),
            fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'JPG or PNG, max 5MB',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: (screenWidth * 0.032).clamp(12.0, 14.0),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedPreview(double screenWidth) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF07746B).withValues(alpha:0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _idImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade400,
                      size: 32,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID document selected',
                    style: TextStyle(
                      color: const Color(0xFF07746B),
                      fontSize: (screenWidth * 0.038).clamp(14.0, 16.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to change image',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: (screenWidth * 0.032).clamp(12.0, 14.0),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ],
        ),
      ],
    );
  }
}
