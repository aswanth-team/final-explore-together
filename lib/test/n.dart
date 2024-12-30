import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Send Notification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SendNotificationPage(),
    );
  }
}

class SendNotificationPage extends StatefulWidget {
  @override
  _SendNotificationPageState createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  // Function to send notification to a specific Player ID
  Future<void> sendNotificationToPlayer(
      String playerId, String title, String message) async {
    const String oneSignalAppId =
        "6ebc33e0-21f7-4380-867f-9a6c8c9220e9"; // Replace with your OneSignal App ID
    const String restApiKey =
        "os_v2_app_n26dhybb65bybbt7tjwizera5fllwdlgaz2eaiec67i7a2tiw74qyhmtuqyhngu572tiwztiw4p6mzggpcbs4cxjrwy7fhfxcaavrpy";
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Basic $restApiKey', // REST API Key for authorization
      },
      body: jsonEncode({
        'app_id': oneSignalAppId,
        'include_player_ids': [playerId], // Target the player's OneSignal ID
        'headings': {'en': title}, // Notification title
        'contents': {'en': message}, // Notification message
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notification sent successfully!'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send notification: ${response.body}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Function to send notification directly to a specific Player ID
  Future<void> sendNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in the title and message!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Hardcoded Player ID for testing
      const playerId = '28148953-7ed4-43e2-8d59-dd1ca976f4b9';

      await sendNotificationToPlayer(playerId, title, message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Notification Message',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : sendNotification,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
