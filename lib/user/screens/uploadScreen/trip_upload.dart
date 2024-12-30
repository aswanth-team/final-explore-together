import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/cloudinary_upload.dart';
import '../../../utils/loading.dart';

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (!mounted) return; // Ensure widget is still in the tree
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await CloudinaryService(uploadPreset: 'tripimages')
          .uploadImage(selectedImage: _selectedImage);

      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = response;
      });
      if (_uploadedImageUrl != null) {
        await _saveImageUrlToFirestore(_uploadedImageUrl!);
      }
    } catch (e) {
      print('Error uploading image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _saveImageUrlToFirestore(String imageUrl) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final userRef =
          FirebaseFirestore.instance.collection('user').doc(currentUserId);
      final userDoc = await userRef.get();

      List<String> tripImages = [];

      if (userDoc.exists) {
        tripImages = List<String>.from(userDoc['tripimages'] ?? []);
        tripImages.insert(0, imageUrl);
      }

      await userRef.update({
        'tripimages': tripImages,
      });
    } catch (e) {
      print('Error saving to Firestore: $e');
    } finally {
      Navigator.pop(context); // Close the bottom sheet
      Future.delayed(Duration(milliseconds: 300), () {
        Navigator.pop(context); // Go back to the previous screen
      });
    }
  }

  Widget _buildLoadingOverlay() {
    return _isUploading
        ? LoadingAnimationOverLay()
        : SizedBox.shrink(); // If not uploading, return an empty widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 300,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.grey[300],
                        ),
                        child: _selectedImage != null
                            ? FittedBox(
                                fit: BoxFit.contain,
                                child: Image.file(_selectedImage!),
                              )
                            : Center(
                                child: Text(
                                  'Tap to select an image',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectedImage == null || _isUploading
                      ? null
                      : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green, // Text color
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12), // Padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    elevation: 4, // Shadow elevation
                    disabledBackgroundColor:
                        Colors.grey, // Disabled state background
                    disabledForegroundColor:
                        Colors.white, // Disabled state text color
                  ),
                  child: Text(
                    'Upload',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }
}

void main() => runApp(const MaterialApp(
      home: ImageUploader(),
    ));
