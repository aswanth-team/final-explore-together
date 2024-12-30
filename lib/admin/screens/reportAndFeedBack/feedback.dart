import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/loading.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: LoadingAnimation());
          }

          final feedbacks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              return FeedbackTile(
                feedback: feedback,
              );
            },
          );
        },
      ),
    );
  }
}

class FeedbackTile extends StatelessWidget {
  final QueryDocumentSnapshot feedback;

  const FeedbackTile({
    super.key,
    required this.feedback,
  });

  Future<Map<String, dynamic>?> _fetchUserData(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data();
    }
    return null;
  }

  void _showFeedbackPopup(
      BuildContext context, String description, dynamic rating) {
    final int ratingValue = (rating is double) ? rating.round() : (rating ?? 0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Feedback Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rating:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < ratingValue ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(description),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchUserData(feedback['sender']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: LoadingAnimation());
        }

        final userData = snapshot.data as Map<String, dynamic>;

        return ListTile(
          leading: userData['userimage'] != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(userData['userimage']),
                )
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Text(userData['username'] ?? 'Unknown User'),
          subtitle: Text(
            feedback['description'].toString().length > 30
                ? '${feedback['description'].toString().substring(0, 30)}...'
                : feedback['description'].toString(),
          ),
          onTap: () {
            _showFeedbackPopup(
              context,
              feedback['description'],
              feedback['rating'] ?? 0,
            );
          },
        );
      },
    );
  }
}
