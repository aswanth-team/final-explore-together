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

  static Future<bool> getUserOnlineStatus(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      return userDoc.data()?['isOnline'] ?? false;
    } catch (e) {
      print('Error getting user online status: $e');
      return false;
    }
  }
}

class PreferencesManager {
  // Limit the number of saved chats
  static Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Limit to most recent 100 chats
      final limitedChats = chats.take(100).toList();
      final chatJsonList =
          limitedChats.map((chat) => json.encode(chat)).toList();
      await prefs.setStringList('previous_chats', chatJsonList);
    } catch (e) {
      print('Error saving chats: $e');
    }
  }

  static Future<void> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears all saved preferences
    } catch (e) {
      print('Error clearing preferences: $e');
    }
  }

  // Add an option to load a subset of chats
  static Future<List<Map<String, dynamic>>> loadChats({int limit = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJsonList = prefs.getStringList('previous_chats') ?? [];
      return chatJsonList
          .take(limit)
          .map((chatJson) => Map<String, dynamic>.from(json.decode(chatJson)))
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
      {Key? key,
      required this.imageUrl,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => CircularProgressIndicator(),
      errorWidget: (context, url, error) => Icon(Icons.error),
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 250, // Limit memory cache width
      maxWidthDiskCache: 500, // Limit disk cache width
    );
  }

  static Future<void> clearImageCache() async {
    try {
      // Clears the image cache for both live and stored images
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      print('All cached images cleared.');
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }
}
