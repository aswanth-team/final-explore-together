import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer';

const apiKey = 'AIzaSyAwjcN3Aei78CJ6YP2Ok-W47i-Z_5k_5EE';

void main() {
  Gemini.init(apiKey: apiKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gemini Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Chat Popup Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Show the chat screen as a popup
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const ChatPopup();
              },
            );
          },
          child: const Text('Open Chat'),
        ),
      ),
    );
  }
}

class ChatPopup extends StatefulWidget {
  const ChatPopup({super.key});

  @override
  _ChatPopupState createState() => _ChatPopupState();
}

class _ChatPopupState extends State<ChatPopup> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  final String system_prrompt = 'Your name is Explore Ai';
  bool _isLoading = false;

  void _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': userMessage});
      _isLoading = true;
    });

    try {
      // Use multi-turn conversation (gemini.chat)
      final gemini = Gemini.instance;

      // Define the system prompt and the user details more clearly
      final systemPrompt = 'Your name is Explore Ai';
      final userDetails = {
        'username': 'Ajmal'
      }; // Adjust this based on your use case

      // Define the conversation context
      final conversation = [
        Content(parts: [
          Part.text(
              'system_prompt: $systemPrompt, userDetails: $userDetails, user_input: $userMessage')
        ], role: 'user'),
        ..._chatHistory
            .where((msg) => msg['role'] == 'model') // Include model responses
            .map((msg) => Content(parts: [
                  Part.text(msg['message']!),
                ], role: 'model'))
      ];

      final response = await gemini.chat(conversation);

      // Add the model's response to the chat history
      setState(() {
        _chatHistory.add({
          'role': 'model',
          'message': response?.output ?? 'No response received'
        });
      });
    } catch (e) {
      log('Error in chat: $e');
      setState(() {
        _chatHistory.add({
          'role': 'error',
          'message': 'An error occurred. Please try again.'
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
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          message,
          style: TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final message = _chatHistory[index];
        return _buildMessageBubble(message['message']!, message['role']!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: _chatHistory.isEmpty
                  ? const Center(
                      child: Text('No messages yet. Start the conversation!'))
                  : _buildChatList(),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final message = _controller.text;
                      _controller.clear();
                      _sendMessage(message);
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
