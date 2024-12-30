import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/cloudinary_upload.dart';
import '../../../../utils/loading.dart';

class UploadAgencyPage extends StatefulWidget {
  const UploadAgencyPage({super.key});

  @override
  UploadAgencyPageState createState() => UploadAgencyPageState();
}

class UploadAgencyPageState extends State<UploadAgencyPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _webController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  File? _selectedImage;
  final CloudinaryService _cloudinaryService =
      CloudinaryService(uploadPreset: 'agencyImages');

  List<String> _keywords = [];
  bool _isLoading = false;

  Future<void> _uploadAgency() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl =
          await _cloudinaryService.uploadImage(selectedImage: _selectedImage);
    }

    final newAgency = {
      'agencyName': _nameController.text,
      'agencyWeb': _webController.text,
      'agencyKeywords': _keywords,
      'category': _categoryController.text,
      'agencyImage': imageUrl,
    };

    await FirebaseFirestore.instance.collection('agencies').add(newAgency);

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _onKeywordEntered(String value) {
    if (value.isNotEmpty && !_keywords.contains(value)) {
      setState(() {
        _keywords.add(value);
      });
    }
    _keywordsController.clear();
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Agency')),
      body: _isLoading
          ? Center(child: LoadingAnimationOverLay())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _selectedImage != null
                        ? Image.file(_selectedImage!, height: 150)
                        : Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: Center(
                              child: Text('No image selected'),
                            ),
                          ),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Upload Image'),
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Agency Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    TextFormField(
                      controller: _webController,
                      decoration: InputDecoration(labelText: 'Agency Website'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a valid URL' : null,
                    ),
                    const SizedBox(height: 16),
                    // Displaying existing tags (keywords)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _keywords.map((keyword) {
                        return Chip(
                          label: Text(keyword),
                          deleteIcon: Icon(Icons.clear),
                          onDeleted: () => _removeKeyword(keyword),
                        );
                      }).toList(),
                    ),
                    TextFormField(
                      controller: _keywordsController,
                      decoration: InputDecoration(
                        labelText: 'Add Keywords (Press Enter or Comma to add)',
                      ),
                      onFieldSubmitted: _onKeywordEntered,
                      onChanged: (value) {
                        if (value.endsWith(',')) {
                          _onKeywordEntered(
                              value.substring(0, value.length - 1));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _uploadAgency,
                      child: const Text('Upload Agency'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
