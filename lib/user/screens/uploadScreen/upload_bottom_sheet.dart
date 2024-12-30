// bottom_sheet_modal.dart
import 'package:flutter/material.dart';

import 'post_upload.dart';
import 'trip_upload.dart';

class BottomSheetModal {
  static void showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.post_add, color: Colors.blue),
                title: const Text(
                  "Post",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PostUploader()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.green),
                title: const Text(
                  "Upload Image",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImageUploader()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
