import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String address;
  final String? imageBase64;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onAddressChanged;
  final ValueChanged<String> onImageChanged;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.imageBase64,
    required this.onNameChanged,
    required this.onPhoneChanged,
    required this.onAddressChanged,
    required this.onImageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProfile();
  }

  Future<void> _loadTokenAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? 'dc8e45dfcaca89fcdf2da05ed33a09f24f071aaa4468456f44e8b16429cb7fc7';
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/customers/get_profile.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': _token}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == 'true' || responseData['success'] == true) {
          if (responseData['name'] != null && responseData['name'].toString().isNotEmpty) {
            widget.onNameChanged(responseData['name']);
          }
          if (responseData['mobileno'] != null && responseData['mobileno'].toString().isNotEmpty) {
            widget.onPhoneChanged(responseData['mobileno']);
          }
          if (responseData['address'] != null && responseData['address'].toString().isNotEmpty) {
            widget.onAddressChanged(responseData['address']);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _updateProfileApi({String? name, String? phone, String? address}) async {
    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/customers/edit_profile.php');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _token,
          'name': name ?? widget.name,
          'mobileno': phone ?? widget.phoneNumber,
          'address': address ?? widget.address,
          'profile_img': widget.imageBase64 ?? '',
        }),
      );
    } catch (_) {}
  }

  Future<void> _showTermsConditions() async {
    String content = 'Loading Terms & Conditions...';
    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/settings/terms_conditions.php');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        content = response.body.isNotEmpty ? response.body : 'Standard TrivKart Terms & Conditions applied.';
      }
    } catch (_) {
      content = 'Standard TrivKart Terms & Conditions applied.';
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacyPolicy() async {
    String content = 'Loading Privacy Policy...';
    try {
      final url = Uri.parse('https://ttbilling.in/trivkart/api/settings/privacy_policy.php');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        content = response.body.isNotEmpty ? response.body : 'Standard TrivKart Privacy Policy applied.';
      }
    } catch (_) {
      content = 'Standard TrivKart Privacy Policy applied.';
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  Future<void> _selectPresetAvatar(String assetPath) async {
    try {
      final byteData = await DefaultAssetBundle.of(context).load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      final base64String = base64Encode(bytes);
      widget.onImageChanged(base64String);
      if (mounted) {
        Navigator.pop(context); // Close selector dialog
      }
    } catch (e) {
      debugPrint("Error loading preset: $e");
    }
  }

  void _showPresetAvatarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Preset Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildPresetOption('assets/images/logo.png'),
              _buildPresetOption('assets/images/paneer_gravy.png'),
              _buildPresetOption('assets/images/pizza.png'),
              _buildPresetOption('assets/images/pista_ice_cream.png'),
              _buildPresetOption('assets/images/grocery_collage.png'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetOption(String assetPath) {
    return GestureDetector(
      onTap: () => _selectPresetAvatar(assetPath),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(assetPath, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        widget.onImageChanged(base64String);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Gallery Error', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'Unable to access device gallery. Please stop the app in your IDE or terminal, and run "flutter run" again to compile the new native code.\n\n'
              'In the meantime, would you like to select one of our preloaded avatars?',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close error dialog
                  _showPresetAvatarDialog(); // Show presets picker
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA5A00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Select Preset'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _editName() {
    final controller = TextEditingController(text: widget.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onNameChanged(controller.text);
              _updateProfileApi(name: controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA5A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPhone() {
    final controller = TextEditingController(text: widget.phoneNumber);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter phone number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onPhoneChanged(controller.text);
              _updateProfileApi(phone: controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA5A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editAddress() {
    final controller = TextEditingController(text: widget.address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onAddressChanged(controller.text);
              _updateProfileApi(address: controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA5A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoItem(IconData icon, String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0C2440), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0C2440), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Orange Profile Icon
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBE9E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFFA5A00),
                  size: 24,
                ),
              ),
              // Title
              const Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 32), // spacer balance
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // 2. Avatar with drop shadow and border + click action
                Center(
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: widget.imageBase64 != null && widget.imageBase64!.isNotEmpty
                                ? Image.memory(
                                    base64Decode(widget.imageBase64!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        // Orange Camera Edit Badge
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFA5A00),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Basic Info Section
                const Text(
                  'Basic Info',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                _buildBasicInfoItem(Icons.account_circle, widget.name, _editName),
                _buildBasicInfoItem(Icons.phone, '+91 ${widget.phoneNumber}', _editPhone),
                _buildBasicInfoItem(Icons.location_on, widget.address, _editAddress),
                
                const SizedBox(height: 24),

                // 4. Others Section
                const Text(
                  'Others',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildOtherItem(Icons.shopping_bag_rounded, 'My Orders'),
                      Divider(color: Colors.grey.shade100, height: 1),
                      _buildOtherItem(Icons.assignment_rounded, 'Terms & Conditions', onTap: _showTermsConditions),
                      Divider(color: Colors.grey.shade100, height: 1),
                      _buildOtherItem(Icons.shield_rounded, 'Privacy & Policy', onTap: _showPrivacyPolicy),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
