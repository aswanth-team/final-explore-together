import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_theme.dart';
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
    final themeManager = Provider.of<ThemeManager>(context);
    final appTheme = themeManager.currentTheme;

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
      backgroundColor: appTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: appTheme.secondaryColor,
        title: Text(
          'Notifications',
          style: TextStyle(color: appTheme.textColor),
        ),
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
            return Center(
              child: Text(
                'No notifications available',
                style: TextStyle(color: appTheme.textColor),
              ),
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
                color: appTheme.secondaryColor,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appTheme.textColor)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(color: appTheme.secondaryTextColor),
                      ),
                      if (date != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
                              style: TextStyle(
                                color: appTheme.secondaryTextColor,
                                fontSize: 6,
                              ),
                            ),
                          ],
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
