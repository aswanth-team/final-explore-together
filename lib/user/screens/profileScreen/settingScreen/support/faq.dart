import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQs'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('What is Explore Together?'),
            subtitle: Text('Explore Together is an app that helps you connect with others for shared activities and experiences.'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _showAnswer(context, 'Explore Together is an app that helps you connect with others for shared activities and experiences.');
            },
          ),
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('How do I create an account?'),
            subtitle: Text('Simply click on the "Sign Up" button and fill in the necessary details to get started.'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _showAnswer(context, 'Simply click on the "Sign Up" button and fill in the necessary details to get started.');
            },
          ),
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('How do I find activities?'),
            subtitle: Text('You can browse through the activity feed or search for specific types of events near you.'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _showAnswer(context, 'You can browse through the activity feed or search for specific types of events near you.');
            },
          ),
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('Can I invite friends to join an activity?'),
            subtitle: Text('Yes, you can easily send invites to friends via the app or through messaging platforms.'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              _showAnswer(context, 'Yes, you can easily send invites to friends via the app or through messaging platforms.');
            },
          ),
        ],
      ),
    );
  }

  void _showAnswer(BuildContext context, String answer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Answer'),
          content: Text(answer),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
