import 'package:flutter/material.dart';

Future<void> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelButtonText,
  required String confirmButtonText,
  required Function onConfirm,
  required Icon titleIcon,
  Color titleColor = Colors.redAccent,
  Color messageColor = Colors.black87,
  Color cancelButtonColor = Colors.blue,
  Color confirmButtonColor = Colors.redAccent,
  Color backgroundColor = Colors.white,
  String? subMessage,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: Row(
          children: [
            titleIcon,
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: messageColor,
              ),
            ),
            const SizedBox(height: 10),
            if (subMessage != null) ...[
              Text(
                subMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              cancelButtonText,
              style: TextStyle(
                color: cancelButtonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmButtonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              confirmButtonText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}


/*showConfirmationDialog(
  context: context,
  title: 'Delete Image',
  message: 'Are you sure you want to delete this image?',
  cancelButtonText: 'Cancel',
  confirmButtonText: 'Delete',
  onConfirm: () {
    deleteTripPhoto(tripImages[index], index); // Perform the delete action
  },
  titleIcon: Icon(Icons.delete_forever, color: Colors.red), // Custom icon
  titleColor: Colors.redAccent,
  messageColor: Colors.black87,
  cancelButtonColor: Colors.blue,
  confirmButtonColor: Colors.red,
  backgroundColor: Colors.white,
  subMessage: 'This action cannot be undone.', // Custom sub message
);
 */