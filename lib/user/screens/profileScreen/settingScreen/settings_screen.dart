import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../login_screen.dart';
import '../../chat_&_group/chatScreen/chat_utils.dart';
import 'accoundManagement/account_management_screen.dart';
import 'feedback_popup.dart';
import 'help/help_screen.dart';
import 'support/support_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> clearFirestoreCache() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
    } catch (e) {
      print('Error clearing Firestore cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Support Section
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainHelpPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Account Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AccountManagementPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return FeedbackPopup();
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  backgroundColor: Colors.white,
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Confirm Logout',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to log out?',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.all(10),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true) {
                try {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId != null) {
                    // Clear OneSignal player ID
                    final playerId = OneSignal.User.pushSubscription.id;
                    final userDocRef = FirebaseFirestore.instance
                        .collection('user')
                        .doc(userId);
                    final userDocSnapshot = await userDocRef.get();

                    // Update OneSignal IDs
                    List<String> existingPlayerIds = [];
                    if (userDocSnapshot.exists) {
                      final userData = userDocSnapshot.data();
                      existingPlayerIds =
                          List<String>.from(userData?['onId'] ?? []);
                      existingPlayerIds.remove(playerId);

                      if (existingPlayerIds.isNotEmpty) {
                        await userDocRef.set({'onId': existingPlayerIds},
                            SetOptions(merge: true));
                      } else {
                        await userDocRef.update({'onId': FieldValue.delete()});
                      }
                    }

                    // Clear group chat data
                    final prefs = await SharedPreferences.getInstance();
                    final keys = prefs.getKeys().toList();

                    for (final key in keys) {
                      if (key.startsWith('cached_messages_') ||
                          key.startsWith('cached_chats') ||
                          key.startsWith('chat_') ||
                          key.startsWith('group_') ||
                          key.startsWith('messages_') ||
                          key == 'groups') {
                        await prefs.remove(key);
                      }
                    }

                    // Clear image caches
                    await OptimizedNetworkImage.clearImageCache();
                    imageCache.clear();
                    imageCache.clearLiveImages();

                    // Clear Firestore cache
                    await clearFirestoreCache();

                    // Clear all app preferences
                    await PreferencesManager.clearPreferences();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Error occurred during logout. Please try again.')),
                    );
                  }
                } finally {
                  // Sign out from Firebase
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
