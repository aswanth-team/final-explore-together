import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SMSPage(),
    );
  }
}

class SMSPage extends StatefulWidget {
  @override
  _SMSPageState createState() => _SMSPageState();
}

class _SMSPageState extends State<SMSPage> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String _statusMessage = '';

  void _sendSMS() async {
    setState(() {
      _isSending = true;
      _statusMessage = '';
    });

    final smsService = SMSService();
    bool success = await smsService.sendSMS(
      _numberController.text,
      _messageController.text,
    );

    setState(() {
      _isSending = false;
      _statusMessage = success ? 'Message Sent!' : 'Failed to send message.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send SMS with Infobip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _numberController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSending ? null : _sendSMS,
              child:
                  _isSending ? CircularProgressIndicator() : Text('Send SMS'),
            ),
            SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}

class SMSService {
  final String apiKey =
      'e7101a56c3d5741b4d5171b062b25328-3c334762-491b-4738-8c64-dcd13a5013ad';
  final String baseUrl = 'wgld2q.api.infobip.com/sms/1/text/single';

  Future<bool> sendSMS(String to, String message) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'App $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'from': 'Explore Togetherr',
        'to': to,
        'text': message,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['messages'][0]['status']['groupId'] ==
          1; // Check if message is delivered
    } else {
      print('Error: ${response.body}');
      return false;
    }
  }
}
