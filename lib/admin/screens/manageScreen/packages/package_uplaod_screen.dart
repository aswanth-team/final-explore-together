import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../../../../services/cloudinary_upload.dart';
import '../../../../utils/loading.dart';

class PackageUploader extends StatefulWidget {
  const PackageUploader({super.key});

  @override
  PackageUploaderState createState() => PackageUploaderState();
}

class PackageUploaderState extends State<PackageUploader> {
  final _formKey = GlobalKey<FormState>();

  List<File> _selectedImages = [];
  String? _locationName;
  String? _locationDescription;
  int? _tripDuration;
  String? _phoneNumber;
  int? _prize;

  final List<String> _tags = [];
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _tagController = TextEditingController();

  bool _isPosting = false;

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(
            pickedFiles.map((pickedFile) => File(pickedFile.path)).toList(),
          );
          if (_selectedImages.length > 3) {
            _selectedImages = _selectedImages.take(3).toList();
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty) {
      if (_tags.length >= 8) {
        return;
      }
      if (!_tags.contains(tag)) {
        setState(() {
          _tags.add(tag);
        });
        _tagController.clear();
      } else {
        _tagController.clear();
      }
    }
  }

  void _handleTagInput(String value) {
    String tag = value.trim().replaceAll(',', '').replaceAll('\n', '').trim();
    if (tag.isNotEmpty) {
      _addTag(tag);
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one image!")),
      );
      return;
    }

    final String remainingTag = _tagController.text.trim();
    if (remainingTag.isNotEmpty) {
      _addTag(remainingTag);
    }

    setState(() {
      _isPosting = true;
    });

    List<String> uploadedImageUrls = [];

    try {
      for (File image in _selectedImages) {
        final response = await CloudinaryService(uploadPreset: 'packageImages')
            .uploadImage(selectedImage: image);
        if (response != null) {
          uploadedImageUrls.add(response);
        }
      }

      final packageData = {
        'locationName': _locationName,
        'locationDescription': _locationDescription,
        'locationImages': uploadedImageUrls,
        'planToVisitPlaces': _tags,
        'tripDuration': _tripDuration,
        'PostedBy': currentUserId,
        'uploadedDateTime': FieldValue.serverTimestamp(),
        'contact': _phoneNumber,
        'prize': _prize,
        'postedUsers': null
      };
      await FirebaseFirestore.instance.collection('packages').add(packageData);

      setState(() {
        _selectedImages.clear();
        _tags.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Package successfully uploaded!")),
        );
      }
    } catch (e) {
      print('Error uploading Package: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to upload package. Please try again.")),
        );
      }
    } finally {
      setState(() {
        _isPosting = false;
      });

      if (mounted) {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  Widget _imagePickerWidget() {
    return SizedBox(
      height: 200,
      child: _selectedImages.isEmpty
          ? Center(
              child: GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Add Images\n(max 3)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount:
                  _selectedImages.length + (_selectedImages.length < 3 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _selectedImages.length) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Add Images\n(max 3)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Image preview
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _imagePickerWidget(),
                    ),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Location Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter location name'
                            : null,
                        onSaved: (value) => _locationName = value,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter contact number'
                            : null,
                        onSaved: (value) => _phoneNumber = value,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Package Prize',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter package prize';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Enter a valid prize';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _prize = int.tryParse(value!);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Location Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter location description'
                            : null,
                        onSaved: (value) => _locationDescription = value,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Trip Duration (in days)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter trip duration';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Enter a valid positive number';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _tripDuration = int.tryParse(value!);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: 'Plan to Visit (Enter tags)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _tags.length < 8
                                ? () => _addTag(_tagController.text)
                                : null,
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                          ),
                        ),
                        onChanged: (value) {
                          if (_tags.length < 8 &&
                              (value.endsWith(",") || value.endsWith("\n"))) {
                            _handleTagInput(value);
                          }
                        },
                        onFieldSubmitted: (value) =>
                            _tags.length < 8 ? _addTag(value) : null,
                        enabled: _tags.length < 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            backgroundColor: Colors.grey[200],
                            labelStyle: const TextStyle(color: Colors.black),
                            onDeleted: () => _removeTag(tag),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (_isPosting) const LoadingAnimationOverLay()
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200, // Adjust the width as needed
                child: ElevatedButton(
                  onPressed: _isPosting
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            _post();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.25),
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
