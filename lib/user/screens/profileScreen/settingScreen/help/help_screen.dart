import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MainHelpPage extends StatelessWidget {
  const MainHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Login Help'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginHelpPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Recover a Removed Account'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecoverAccountHelpPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Using Explore Together'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UsingAppHelpPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LoginHelpPage extends StatelessWidget {
  const LoginHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Help'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'Login Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '1. Enter your username, email, phone, or Aadhaar in the first field.\n'
              '2. Enter your password in the second field.\n'
              '3. If you forgot your password, click on "Forgot Password?".\n'
              '4. New users can click "Signup" to register.\n',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class RecoverAccountHelpPage extends StatelessWidget {
  const RecoverAccountHelpPage({super.key});

  // Fetch the email from Firestore
  Future<String> fetchEmail() async {
    try {
      // Get the app management data from Firestore
      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection('Manage')
          .doc('appData') 
          .get();
      if (document.exists && document['appEmail'] != null) {
        return document['appEmail'];
      } else {
        return 'travellbuddyfinder@gmail.com@gmail.com'; 
      }
    } catch (e) {
      return 'travellbuddyfinder@gmail.com@gmail.com'; 
    }
  }

  void _launchEmail(String email) {
    launchUrl(Uri(
      scheme: 'mailto',
      path: email,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Account'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Recover a Removed Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Accounts may be temporarily removed due to the following reasons:\n'
              '- Violation of community guidelines or policies.\n'
              '- Inactivity for a prolonged period.\n'
              '- Fraudulent or suspicious activity.\n'
              '- Incorrect or incomplete account information.\n\n'
              'If your account was removed and you believe this was a mistake, you can contact our support team to recover it. Provide all the necessary details, such as your full name, email, and username.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // FutureBuilder to fetch and display the email
            FutureBuilder<String>(
              future: fetchEmail(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text('Error fetching email',
                      style: TextStyle(fontSize: 16, color: Colors.red));
                } else if (snapshot.hasData) {
                  // Get the email from the snapshot
                  String email = snapshot.data ?? 'timeload@gmail.com';
                  return Center(
                    child: ElevatedButton(
                      onPressed: () => _launchEmail(email),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Contact Us',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UsingAppHelpPage extends StatelessWidget {
  const UsingAppHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Using Explore Together'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'Using Explore Together',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Explore Together is designed to connect solo travelers with others who share similar destinations and interests. Here’s how you can use it:\n\n'
              '- Create a profile with your travel preferences.\n'
              '- Search for fellow travelers heading to your destination.\n'
              '- Use the in-app chat feature to connect and plan trips together.\n'
              '- Review safety tips and guidelines before meeting new people.\n\n'
              'Enjoy a secure and seamless travel experience with Explore Together.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
