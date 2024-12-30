import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/cloudinary_upload.dart';
import '../../../services/one_signal.dart';

class SentMessagePage extends StatefulWidget {
  final String? userNameFromPreviousPage;
  final bool disableSendToAll;
  const SentMessagePage(
      {super.key,
      this.userNameFromPreviousPage,
      this.disableSendToAll = false});

  @override
  SentMessagePageState createState() => SentMessagePageState();
}

class SentMessagePageState extends State<SentMessagePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String selectedUserName = '';
  bool sendToAll = true;
  bool isLoading = false;
  File? _selectedImage;

  final CloudinaryService cloudinaryService = CloudinaryService(
    uploadPreset: 'notificationImages',
  );

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage != null) {
      return await cloudinaryService.uploadImage(selectedImage: _selectedImage);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.userNameFromPreviousPage != null) {
      selectedUserName = widget.userNameFromPreviousPage!;
    }
    if (widget.disableSendToAll) {
      sendToAll = false;
    }
  }

  bool validateInput() {
    String message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty')),
      );
      return false;
    }
    if (!sendToAll && selectedUserName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('enter the userName')),
      );
      return false;
    }

    return true;
  }

  // Function to send a notification
  Future<void> sendNotification() async {
    if (!validateInput()) {
      return;
    }
    String title = _titleController.text;
    String message = _messageController.text;

    setState(() {
      isLoading = true;
    });

    _titleController.clear();
    _messageController.clear();

    String? imageUrl;

    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    try {
      if (sendToAll) {
        await NotificationService().sendNotificationToAllUsers(
          title,
          message,
          imageUrl,
        );
        final userCollection = FirebaseFirestore.instance.collection('user');
        final querySnapshot = await userCollection.get();

        if (querySnapshot.docs.isNotEmpty) {
          for (var userDoc in querySnapshot.docs) {
            final userDocId = userDoc.id;
            final notificationData = {
              'title': title,
              'message': message,
              'time': FieldValue.serverTimestamp(),
              'date': DateTime.now().toIso8601String(),
              'isSeen': false,
            };

            await userCollection
                .doc(userDocId)
                .collection('notifications')
                .add(notificationData);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification sent to all users')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No users found')),
          );
        }
      } else {
        final userCollection = FirebaseFirestore.instance.collection('user');
        final querySnapshot = await userCollection
            .where('username', isEqualTo: selectedUserName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Access the first document in the result (assuming 'username' is unique)
          final userDoc = querySnapshot.docs.first;

          // Extract the 'onId' field
          final onId = userDoc.data()['onId'];

          print('onId: $onId');
        } else {
          print('No user found with username: $selectedUserName');
        }

        if (querySnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username does not exist')),
          );
          return;
        }

        final userDoc = querySnapshot.docs.first;
        final userDocId = userDoc.id;
        final userData = userDoc.data();
        List<String> onIds = [];
        if (userData.containsKey('onId') && userData['onId'] is List) {
          onIds = List<String>.from(userData['onId']);
        }
        final notificationData = {
          'title': title,
          'message': message,
          'time': FieldValue.serverTimestamp(),
          'date': DateTime.now().toIso8601String(),
          'isSeen': false,
        };

        await userCollection
            .doc(userDocId)
            .collection('notifications')
            .add(notificationData);

        await NotificationService().sentNotificationtoUser(
            title: title, description: message, onIds: onIds);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent to user')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send notification')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            // Switch for sending to all users
            SwitchListTile(
              title: const Text(
                'Send to all users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              value: sendToAll,
              onChanged: widget.disableSendToAll
                  ? null // Disable switch if `disableSendToAll` is true
                  : (bool value) {
                      setState(() {
                        sendToAll = value;
                      });
                    },
            ),

            // Input field for specific user  (visible if sendToAll is false)
            if (!sendToAll)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      selectedUserName = value;
                    });
                  },
                  initialValue: selectedUserName,
                  decoration: InputDecoration(
                    labelText: 'Enter Username',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _titleController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Enter title',
                labelStyle: const TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(
                  Icons.message,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // Message input field
            TextFormField(
              controller: _messageController,
              maxLines: null, // This makes the TextField multi-line
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Enter message',
                labelStyle: const TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(
                  Icons.message,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Send notification button
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : sendNotification, // Disable button when loading
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Send Notification'),
            ),
            const SizedBox(height: 20),
            if (sendToAll)
              Column(
                children: [
                  if (_selectedImage != null)
                    Image.file(
                      _selectedImage!,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Upload Image"),
                  ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
