import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter OTP Sender',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OTPPage(),
    );
  }
}

class OTPService {
  final String apiKey =
      "b53477c2821c1bf0da5d40e57b870d35"; // Use your actual API Key

  Future<String> sendOTP(String phone, String otp) async {
    final url = Uri.parse("https://sms.renflair.in/V1.php");
    final response = await http.get(url.replace(queryParameters: {
      "API": apiKey,
      "PHONE": phone,
      "OTP": otp,
    }));

    if (response.statusCode == 200) {
      // Check if the response contains a success message
      var data = jsonDecode(response.body);
      if (data['status'] == "success") {
        return "OTP sent successfully!";
      } else {
        return "Error: ${data['message']}";
      }
    } else {
      return "Failed to send OTP!";
    }
  }
}

class OTPPage extends StatefulWidget {
  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String message = "";

  final OTPService otpService = OTPService();

  void _sendOTP() async {
    String phone = phoneController.text.trim();
    String otp = otpController.text.trim();

    if (phone.isEmpty || otp.isEmpty) {
      setState(() {
        message = "Phone number and OTP are required!";
      });
      return;
    }

    String result = await otpService.sendOTP(phone, otp);
    setState(() {
      message = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send OTP"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Phone Number"),
            ),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "OTP"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendOTP,
              child: Text("Send OTP"),
            ),
            SizedBox(height: 20),
            Text(message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}


//https://renflair.in/