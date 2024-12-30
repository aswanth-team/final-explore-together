import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../utils/loading.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _markNotificationsAsSeen();
  }

  Future<void> _markNotificationsAsSeen() async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return;

    final userCollection =
        FirebaseFirestore.instance.collection('user').doc(currentUserId);

    try {
      // Fetch unseen notifications
      final querySnapshot = await userCollection
          .collection('notifications')
          .where('isSeen', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Batch update unseen notifications
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {'isSeen': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking notifications as seen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    final userCollection =
        FirebaseFirestore.instance.collection('user').doc(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userCollection
            .collection('notifications')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingAnimation(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No notifications available'),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final title = notification['title'] ?? 'No Title';
              final message = notification['message'] ?? 'No Message';
              final date = notification['date'] != null
                  ? DateTime.parse(notification['date']).toLocal()
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
