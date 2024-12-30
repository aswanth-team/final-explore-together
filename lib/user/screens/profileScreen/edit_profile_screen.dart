import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../services/cloudinary_upload.dart';
import '../../../utils/loading.dart';

class EditProfileScreen extends StatefulWidget {
  final String uuid;
  const EditProfileScreen({super.key, required this.uuid});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isChanged = false;
  bool _isSaving = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _xController = TextEditingController();
  String? _gender;
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.uuid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _currentImageUrl = data['userimage'] ?? '';
        _fullNameController.text = data['fullname'] ?? '';
        _gender = data['gender'] ?? '';
        _dob = DateTime.parse(data['dob'] ?? '');
        _locationController.text = data['location'] ?? '';
        _bioController.text = data['userbio'] ?? '';
        _instagramController.text = data['instagram'] ?? '';
        _facebookController.text = data['facebook'] ?? '';
        _xController.text = data['x'] ?? "";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isChanged = true;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    String? newImageUrl;

    if (_selectedImage != null) {
      if (_currentImageUrl !=
          "https://res.cloudinary.com/dakew8wni/image/upload/v1733819145/public/userImage/fvv6lbzdjhyrc1fhemaj.jpg") {}

      newImageUrl = await CloudinaryService(uploadPreset: 'userimages')
          .uploadImage(selectedImage: _selectedImage);
    }

    String? formattedDob;
    if (_dob != null) {
      formattedDob = DateFormat('yyyy-MM-dd').format(_dob!);
    }

    final updatedData = {
      'fullname': _fullNameController.text,
      'gender': _gender,
      'dob': formattedDob,
      'location': _locationController.text,
      'userbio': _bioController.text,
      'instagram': _instagramController.text,
      'facebook': _facebookController.text,
      'x': _xController.text,
      if (newImageUrl != null) 'userimage': newImageUrl,
    };

    await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.uuid)
        .update(updatedData);

    setState(() {
      _isSaving = false;
      _isChanged = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fullNameController.text.isNotEmpty
            ? _fullNameController.text
            : 'Edit Profile'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      _currentImageUrl != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : NetworkImage(_currentImageUrl!)
                                      as ImageProvider,
                            )
                          : const CircularProgressIndicator(),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text('Edit Image'),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  onChanged: (_) => setState(() => _isChanged = true),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                            _isChanged = true;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _dob ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              _dob = pickedDate;
                              _isChanged = true;
                            });
                          }
                        },
                        child: Text(
                          _dob != null
                              ? '${_dob!.year}-${_dob!.month}-${_dob!.day}'
                              : 'Select DOB',
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (_) => setState(() => _isChanged = true),
                ),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  onChanged: (_) => setState(() => _isChanged = true),
                ),
                TextField(
                  controller: _instagramController,
                  decoration: const InputDecoration(labelText: 'Instagram'),
                  onChanged: (_) => setState(() => _isChanged = true),
                ),
                TextField(
                  controller: _facebookController,
                  decoration: const InputDecoration(labelText: 'Facebook'),
                  onChanged: (_) => setState(() => _isChanged = true),
                ),
                TextField(
                  controller: _xController,
                  decoration: const InputDecoration(labelText: 'X (Twitter)'),
                  onChanged: (_) => setState(() => _isChanged = true),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isChanged ? _saveChanges : null,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: LoadingAnimation(),
              ),
            ),
        ],
      ),
    );
  }
}
