import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/cloudinary_upload.dart';
import '../../../../utils/loading.dart';

class EditAgencyPage extends StatefulWidget {
  final Map<String, dynamic> agency;

  const EditAgencyPage({super.key, required this.agency});

  @override
  EditAgencyPageState createState() => EditAgencyPageState();
}

class EditAgencyPageState extends State<EditAgencyPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _webController;
  late TextEditingController _keywordsController;
  late TextEditingController _categoryController;
  File? _selectedImage;
  final CloudinaryService _cloudinaryService =
      CloudinaryService(uploadPreset: 'agencyImages');

  List<String> _keywords = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.agency['agencyName']);
    _webController = TextEditingController(text: widget.agency['agencyWeb']);
    _keywordsController = TextEditingController();
    _categoryController =
        TextEditingController(text: widget.agency['category']);
    _keywords = List<String>.from(widget.agency['agencyKeywords'] ?? []);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? imageUrl = widget.agency['agencyImage'];
    if (_selectedImage != null) {
      imageUrl =
          await _cloudinaryService.uploadImage(selectedImage: _selectedImage);
    }

    final updatedData = {
      'agencyName': _nameController.text,
      'agencyWeb': _webController.text,
      'agencyKeywords': _keywords,
      'category': _categoryController.text,
      'agencyImage': imageUrl,
    };

    await FirebaseFirestore.instance
        .collection('agencies')
        .doc(widget.agency['id'])
        .update(updatedData);

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
      appBar: AppBar(title: Text('Edit Agency')),
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
                        : Image.network(widget.agency['agencyImage'],
                            height: 150),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Change Image'),
                    ),
                    SizedBox(height: 16),
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
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
