import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/loading.dart';

class ReportDialog extends StatefulWidget {
  final String userId;
  final String currentUserId;

  const ReportDialog(
      {super.key, required this.userId, required this.currentUserId});

  @override
  ReportDialogState createState() => ReportDialogState();
}

class ReportDialogState extends State<ReportDialog> {
  final TextEditingController descriptionController = TextEditingController();
  bool _isLoading = false;

  void report(String description) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reportedTime': FieldValue.serverTimestamp(),
        'reportedUser': widget.userId,
        'reportingUser': widget.currentUserId,
        'description': description,
        'isChecked': false,
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit the report. Please try again.'),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Issue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please describe the issue below:',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe the reason...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final description = descriptionController.text.trim();
                        if (description.isNotEmpty) {
                          report(description);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please provide a description before reporting.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) const LoadingAnimationOverLay()
      ],
    );
  }
}
