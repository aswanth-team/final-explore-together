import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chatScreen/chat_screen.dart';
import 'groupScreen/group.dart';

class ChatAndGroup extends StatefulWidget {
  const ChatAndGroup({super.key});

  @override
  ChatAndGroupState createState() => ChatAndGroupState();
}

class ChatAndGroupState extends State<ChatAndGroup> {
  late FirebaseService firebaseService;
  String? currentUserId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserAndService();
  }

  Future<void> _initializeUserAndService() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      currentUserId = user.uid;
      final prefs = await SharedPreferences.getInstance();
      firebaseService = FirebaseService(prefs);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (currentUserId == null) {
      return const Center(
        child: Text('User not logged in'),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Group'),
            ],
          ),
          toolbarHeight: 10,
        ),
        body: TabBarView(
          children: [
            const ChatHomeScreen(),
            GroupHomeScreen(
              currentUserId: currentUserId!,
              firebaseService: firebaseService,
            ),
          ],
        ),
      ),
    );
  }
}
