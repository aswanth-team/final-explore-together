import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../feedback_popup.dart';
import 'faq.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  Future<String> fetchEmail() async {
    try {
      // Get the app management data from Firestore
      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection('Manage')
          .doc('appData')
          .get();

      // Check if the document exists and if appEmail is available
      if (document.exists &&
          document['appEmail'] != null &&
          document['appEmail'].isNotEmpty) {
        return document['appEmail'];
      } else {
        return 'travellbuddyfinder@gmail.com';
      }
    } catch (e) {
      return 'travellbuddyfinder@gmail.com';
    }
  }

  void _launchEmail(String email) {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    launchUrl(emailLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contact Us'),
            subtitle: const Text('Email support or chat with us directly.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              String email = await fetchEmail();
              _launchEmail(email);
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('FAQs'),
            subtitle: const Text('Find answers to common questions.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FAQPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Feedback'),
            subtitle: const Text('Share suggestions or feature requests.'),
            trailing: const Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return FeedbackPopup();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
