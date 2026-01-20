import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/user_session_service.dart';
import 'location_picker_screen.dart';
import '../../services/hostel_service.dart';
import '../../services/media_service.dart';


class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedDistrict;
    String? _selectedUniversity;
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
 
  final _monthlyRentController = TextEditingController();
  final _bookingFeeController = TextEditingController();
  final HostelService _hostelService = HostelService();
  final MediaService _mediaService = MediaService();
  // Location data
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedAddress = 'Optional: Tap to select location';
  
  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  
  // Amenities checkboxes
  final Map<String, bool> _amenities = {
    'WiFi': false,
    'Parking': false,
    'Laundry': false,
    'Security': false,
    'Kitchen': false,
    'Study Room': false,
    'Gym': false,
    'Swimming Pool': false,
  };

  final List<String> _districts = [
    'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Chitipa', 'Dedza', 'Dowa', 'Karonga', 'Kasungu', 
    'Likoma', 'Lilongwe', 'Machinga', 'Mangochi', 'Mchinji', 'Mulanje', 'Mwanza', 'Mzimba', 'Nkhata Bay', 
    'Nkhotakota', 'Nsanje', 'Ntcheu', 'Ntchisi', 'Phalombe', 'Rumphi', 'Salima', 'Thyolo', 'Zomba'
  ];

  final List<String> _propertyTypes = [
    'Private',
    'Shared', 
    'Other'
  ];
  String? _selectedPropertyType;
  final List<String> _universities = [
  "University of Malawi (UNIMA)",
  "Malawi University of Science and Technology (MUST)",
  "Lilongwe University of Agriculture and Natural Resources (LUANAR)",
  "Mzuzu University (MZUNI)",
  "Malawi University of Business and Applied Sciences (MUBAS)",
  "Kamuzu University of Health Sciences (KUHeS)",
  "Malawi College of Accountancy (MCA)",
  "Malawi School of Government (MSG)",
  "Domasi College of Education (DCE)",
  "Nalikule College of Education (NCE)",
  "Malawi College of Health Sciences (MCHS)",
  "Mikolongwe College of Veterinary Sciences (MCVS)",
  "Malawi College of Forestry and Wildlife (MCFW)",
  "Malawi Institute of Tourism (MIT)",
  "Marine College (MC)",
  "Civil Aviation Training Centre (CATC)",
  "Montfort Special Needs Education Centre (MSNEC)",
  "National College of Information Technology (NACIT)",
  "Guidance, Counselling and Youth Development Centre for Africa (GCYDCA)",
  "Catholic University of Malawi (CUNIMA)",
  "DMI St John the Baptist University (DMI)",
  "Nkhoma University (NKHUNI)",
  "Malawi Assemblies of God University (MAGU)",
  "Daeyang University (DU)",
  "Malawi Adventist University (MAU)",
  "Pentecostal Life University (PLU)",
  "African Bible College (ABC)",
  "University of Livingstonia (UNILIA)",
  "Exploits University (EU)",
  "University of Lilongwe (UNILIL)",
  "Millennium University (MU)",
  "Lake Malawi Anglican University (LAMAU)",
  "Unicaf University Malawi (UNICAF)",
  "Blantyre International University (BIU)",
  "ShareWORLD Open University (SWOU)",
  "Skyway University (SU)",
  "University of Blantyre Synod (UBS)",
  "Jubilee University (JU)",
  "Marble Hill University (MHU)",
  "Zomba Theological College (ZTC)",
  "Emmanuel University (EMUNI)",
  "ESAMI (ESAMI)",
  "Evangelical Bible College of Malawi (EBCoM)",
  "University of Hebron (UOH)",
  "Malawi Institute of Journalism (MIJ)",
  "International Open University (IOU)",
  "International College of Business and Management (ICBM)",
  "St John of God College of Health Sciences (SJOG)",
  "PACT College (PACT)",
  "K & M School of Accountancy (KM)"
];

  @override
  void initState() {
    super.initState();

  }


  // Show dialog to add custom amenity
  Future<void> _showAddCustomAmenityDialog() async {
    final TextEditingController customAmenityController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Amenity'),
        content: TextField(
          controller: customAmenityController,
          decoration: const InputDecoration(
            hintText: 'Enter amenity name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amenity = customAmenityController.text.trim();
              if (amenity.isNotEmpty) {
                setState(() {
                  _amenities[amenity] = true;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    setState(() {
      _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
    });
    }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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

    if (result != null) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
        _selectedAddress = result['address'] ?? 'Location selected';
      });
    }
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

  // Build a consistent section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF07746B),
        ),
      ),
    );
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
        child: Column(
          children: [
            // Header with back button and title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Add New Property',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                    child: Text(
                      'List your property for students',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              
              // Main Content
              Expanded(
                child: Container(
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
              const SizedBox(height: 20),
              
              // Property Details Header
              _buildSectionHeader('Property Details'),
              const SizedBox(height: 16),
              
              // Property Name
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'Property Name',
                      labelStyle: TextStyle(color: Colors.grey),
                      hintText: 'e.g., Mzuzu University Hostel A',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter property name';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Property Type Dropdown
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPropertyType,
                    decoration: const InputDecoration(
                      labelText: 'Property Type',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    items: _propertyTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select property type';
                      }
                      return null;
                    },
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // District Dropdown
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!), 
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownSearch<String>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Search for a district",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      menuProps: MenuProps(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    items: (f, cs) => _districts,
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: "District",
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: "Select a district",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                    selectedItem: _selectedDistrict,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a district';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // University Dropdown
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownSearch<String>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Search for a university",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      menuProps: MenuProps(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    items: (f, cs) => _universities,
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: "Nearest University",
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: "Select a university",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedUniversity = value;
                      });
                    },
                    selectedItem: _selectedUniversity,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a university';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Property Address
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _addressController,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'Property Address',
                      labelStyle: TextStyle(color: Colors.grey),
                      hintText: 'e.g., Mzuzu University Campus, Mzuzu',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter property address';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your property...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
             
              
              // Location Fields
              Row(
                children: [
                  // Location picker
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickLocation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF07746B)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Property Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF07746B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    color: _selectedLatitude == null ? Colors.grey : Colors.black87,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              const SizedBox(height: 16),
              
              // Amenities Section
              const Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Existing amenities
                  ..._amenities.entries.where((e) => !e.key.startsWith('custom_')).map((entry) {
                    return FilterChip(
                      label: Text(entry.key),
                      selected: entry.value,
                      onSelected: (bool selected) {
                        setState(() {
                          _amenities[entry.key] = selected;
                        });
                      },
                    );
                  }),
                  
                  // Custom amenities with different style
                  ..._amenities.entries.where((e) => e.key.startsWith('custom_')).map((entry) {
                    return FilterChip(
                      label: Text(entry.key.replaceFirst('custom_', '')),
                      selected: entry.value,
                      onSelected: (bool selected) {
                        setState(() {
                          _amenities[entry.key] = selected;
                        });
                      },
                      backgroundColor: Colors.blue[50],
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue,
                    );
                  }),
                  
                  // Add Custom button
                  InputChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Add Custom', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                    onPressed: _showAddCustomAmenityDialog,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Image Upload Section
              const Text(
                'Property Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Images'),
              ),
              const SizedBox(height: 8),
              
              // Selected Images Preview
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Monthly Rent
              TextFormField(
                controller: _monthlyRentController,
                decoration: InputDecoration(
                  labelText: 'Monthly Rent (MWK)',
                  hintText: 'e.g., 45000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter monthly rent';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Booking Fee
              TextFormField(
                controller: _bookingFeeController,
                decoration: InputDecoration(
                  labelText: 'Booking Fee (MWK) - Optional',
                  hintText: 'e.g., 5000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.payment),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitProperty,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Adding Property...'),
                          ],
                        )
                      : const Text(
                          'Add Property',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
              )
            ]
          )
        )
      );
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Store context and messenger at the start
    final currentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Get actual landlord email from session storage
      final landlordEmail = await UserSessionService.getUserEmail();
      
      if (landlordEmail == null || landlordEmail.isEmpty) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
        
        // Prepare amenities - include both predefined and custom amenities
        final selectedAmenities = <String>[];
        for (var entry in _amenities.entries) {
          if (entry.value) {  // If the amenity is selected
            if (entry.key.startsWith('custom_')) {
              // For custom amenities, remove the 'custom_' prefix
              selectedAmenities.add(entry.key.replaceFirst('custom_', ''));
            } else {
              // For predefined amenities, add as is
              selectedAmenities.add(entry.key);
            }
          }
        }
        

        
        // Location is optional - use default coordinates if not selected
        final latitude = _selectedLatitude ?? 0.0;
        final longitude = _selectedLongitude ?? 0.0;
        

        
        // Create hostel
        // Parse booking fee, default to 0 if not provided
        final bookingFee = _bookingFeeController.text.isNotEmpty 
            ? double.parse(_bookingFeeController.text) 
            : 0.0;
            
        final hostelData = await _hostelService.createHostel(
          landlordEmail: landlordEmail,
          name: _nameController.text,
          district: _selectedDistrict!,
          university: _selectedUniversity!,
          address: _addressController.text,
          description: _descriptionController.text,
          amenities: selectedAmenities,
          latitude: latitude,
          longitude: longitude,
          pricePerMonth: double.parse(_monthlyRentController.text),
          bookingFee: bookingFee,
          type: _selectedPropertyType ?? 'Private',
        );
        
        final hostelId = hostelData['hostel_id'];
        
        // Upload images if any
        if (_selectedImages.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _isUploading = true;
          });
          
          int successCount = 0;
          int failCount = 0;
          
          for (int i = 0; i < _selectedImages.length; i++) {
            final image = _selectedImages[i];
            try {
              await _mediaService.uploadHostelMedia(
                hostelId: hostelId,
                filePath: image.path,
                fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
                mediaType: 'image',
                uploaderEmail: landlordEmail,
                isCover: i == 0, // First image as cover
                displayOrder: i,
              );
              successCount++;
            } catch (e) {
              failCount++;
              // Continue with other images even if one fails
            }
          }
          
          if (!mounted) return;
          setState(() {
            _isUploading = false;
          });
          
          // Show upload summary
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Property created! $successCount image(s) uploaded successfully${failCount > 0 ? ', $failCount failed' : ''}',
                ),
                backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
              ),
            );
          }
        } else {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Property created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        
        // Clear form
        if (mounted) {
          _nameController.clear();
          _selectedDistrict = null;
          _selectedUniversity = null;
          _addressController.clear();
          _descriptionController.clear();
          _monthlyRentController.clear();
          _bookingFeeController.clear();
          _selectedLatitude = null;
          _selectedLongitude = null;
          _selectedAddress = 'Optional: Tap to select location';
          _selectedImages.clear();
          
          // Clear all amenities except the predefined ones
          final predefinedAmenities = [
            'WiFi', 'Parking', 'Laundry', 'Security', 
            'Kitchen', 'Study Room', 'Gym', 'Swimming Pool',
          ];
          _amenities.clear();
          for (var amenity in predefinedAmenities) {
            _amenities[amenity] = false;
          }
          
          // Navigate back using the current context
          if (mounted) {
            Navigator.of(context).pop(true); // true = property added successfully

          }
        }
        
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error adding property: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

