//utils.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatusManager {
  static Future<void> updateUserStatus(bool isOnline) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUser.uid)
            .update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating user status: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> getUserStatus(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      final userData = userDoc.data() ?? {};
      return {
        'isOnline': userData['isOnline'] ?? false,
        'lastSeen': userData['lastSeen'],
      };
    } catch (e) {
      print('Error getting user status: $e');
      return {
        'isOnline': false,
        'lastSeen': null,
      };
    }
  }
}

class PreferencesManager {
  static const String _chatKey = 'previous_chats';
  static const int _maxChatSize = 1000; // Maximum size for each chat entry

  static Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJsonList = chats.map((chat) {
        // Validate and trim chat data if needed
        if (json.encode(chat).length > _maxChatSize) {
          chat = _trimChatData(chat);
        }
        return json.encode(chat);
      }).toList();

      await prefs.setStringList(_chatKey, chatJsonList);
    } catch (e) {
      print('Error saving chats: $e');
      rethrow; // Propagate error for handling
    }
  }

  static Map<String, dynamic> _trimChatData(Map<String, dynamic> chat) {
    // Trim long text fields if present
    if (chat.containsKey('text') && chat['text'] is String) {
      chat['text'] = (chat['text'] as String).substring(0, 500);
    }
    return chat;
  }

  static Future<void> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing preferences: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadChats({int limit = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJsonList = prefs.getStringList(_chatKey) ?? [];

      return chatJsonList
          .take(limit)
          .map((chatJson) => Map<String, dynamic>.from(json.decode(chatJson)))
          .where((chat) => chat.isNotEmpty) // Filter invalid entries
          .toList();
    } catch (e) {
      print('Error loading chats: $e');
      return [];
    }
  }
}

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const OptimizedNetworkImage(
      {super.key,
      required this.imageUrl,
      this.width,
      this.height,
      this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => CircularProgressIndicator(),
      errorWidget: (context, url, error) => Icon(Icons.error),
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 250,
      maxWidthDiskCache: 500,
    );
  }

  static Future<void> clearImageCache() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      print('All cached images cleared.');
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }
}
