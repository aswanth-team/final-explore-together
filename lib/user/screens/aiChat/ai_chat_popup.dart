import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer';

const apiKey = 'AIzaSyAwjcN3Aei78CJ6YP2Ok-W47i-Z_5k_5EE';

class ChatPopup extends StatefulWidget {
  const ChatPopup({super.key});

  @override
  ChatPopupState createState() => ChatPopupState();
}

class ChatPopupState extends State<ChatPopup> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  Map<String, dynamic>? _currentUserDetails;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  int? userAge;
  String? userName;
  String? fullName;
  String? userDOB;
  String? userLocation;
  String? userEmail;
  String? userBio;
  String? instruction;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _systemPromptMaker() {
    setState(() {
      instruction = '''
      instruction = [
      {
        "system_instruction": "You are Explore AI, an intelligent assistant for the Explore Together application. Your primary role is to assist users who interact with this app. The application's main goal is to connect solo travelers with groups. In the user_details, where i provide the details of current chating user. So mention the username or user full name in response. Provide simple and clear responses to 'user_input'. Now i am explaining the app usage in detail. In this app in the Home Page user Can see the Posts of All users (current user can also uplaod post based on their interest), when in the post there if the current user is arracted then the user can chat with that user. in that case of post there many user will chat with that post uploaded user. at that time in the app there is option of creating chat group and disscuss about there plan. And make trip. Also in this App that provide many trip packages. user can also considerr that in their trip. In my App  then main Feature is the user can follow another user and make their budddy.",
        "user_details": {
            "User Name : $userName",
            "User Fullname : $fullName",
            "User Age : $userAge",
            "User Location : $userLocation",
            "User Date of Birth : $userDOB",
            "User Email : $userEmail",
            "User Bio : $userBio"
        },
        "application_details": {
          "features": [
            "Find Travel Buddies: Match with users heading to similar destinations.",
            "Chat Feature: Communicate with travel companions in-app."
          ]
        },
        "navigation_instructions": [
          {
            "feature": "Find Travel Buddies",
            "steps": [
              "Open the app.",
              "Search for your desired location in the Home section.",
              "Browse potential matches and start chatting."
            ]
          },
          {
            "feature": "Edit Profile",
            "steps": [
              "Go to your profile.",
              "Tap 'Edit Profile' or navigate to 'Settings > Account Management > Edit Profile'."
            ]
          },
          {
            "feature": "Change Password",
            "steps": [
              "Go to your profile.",
              "Navigate to 'Settings > Account Management > Change Password'."
            ]
          }
        ]
      }
      ]
      ''';
    });
    print(instruction);
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _currentUserDetails = userDoc.data();
          userAge = _currentUserDetails != null
              ? _calculateAge(_currentUserDetails!['dob'])
              : null;
          userName = _currentUserDetails?['username'];
          fullName = _currentUserDetails?['fullname'];
          userDOB = _currentUserDetails?['dob'];
          userLocation = _currentUserDetails?['location'];
          userEmail = _currentUserDetails?['email'];
          userBio = _currentUserDetails?['userbio'];
        });
      }
    } catch (e) {
      log('Error fetching user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    _systemPromptMaker();
  }

  int _calculateAge(String dob) {
    final birthDate = DateTime.parse(dob);
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': userMessage});
      _isLoading = true;
    });

    String modifiedUserInput = '''
$instruction,
"user_input": "$userMessage"
''';

    try {
      final gemini = Gemini.instance;

      final conversation = [
        ..._chatHistory.map(
          (msg) => Content(
            parts: [Part.text(msg['message']!)],
            role: msg['role'],
          ),
        ),
        Content(
          parts: [Part.text(modifiedUserInput)],
          role: 'user',
        ),
      ];

      // Call the Gemini API
      final response = await gemini.chat(conversation);

      // Add the model's response to the chat history
      setState(() {
        _chatHistory.add({
          'role': 'model',
          'message': response?.output ?? 'No response received',
        });
      });
    } catch (e) {
      // Log error for debugging
      log('Error in chat: $e');

      setState(() {
        _chatHistory.add({
          'role': 'error',
          'message': 'An error occurred. Please try again.',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessageBubble(String message, String role) {
    bool isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 16.0,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatHistory.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final message = _chatHistory[index];
        return _buildMessageBubble(message['message']!, message['role']!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            AppBar(
              title: const Text('Chat Popup'),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.blueAccent,
            ),
            Expanded(
              child: _chatHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'Start a conversation with AI',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : _buildChatList(),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final message = _controller.text;
                        _controller.clear();
                        _sendMessage(message);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
