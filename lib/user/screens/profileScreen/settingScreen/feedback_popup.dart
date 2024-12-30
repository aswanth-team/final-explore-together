import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class FeedbackPopup extends StatefulWidget {
  @override
  _FeedbackPopupState createState() => _FeedbackPopupState();
}

class _FeedbackPopupState extends State<FeedbackPopup> {
  final _descriptionController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false; // Track loading state

  // Save the feedback to Firebase Firestore
  Future<void> _submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true; // Show loading animation
      });

      try {
        // Get current timestamp
        final timestamp = FieldValue.serverTimestamp();

        // Save data in the 'feedback' collection
        await FirebaseFirestore.instance.collection('feedback').add({
          'rating': _rating,
          'description': _descriptionController.text,
          'sender': user.uid,
          'sent_at': timestamp,
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Feedback submitted successfully!')));

        // Close the feedback popup
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error submitting feedback')));
      } finally {
        setState(() {
          _isLoading = false; // Hide loading animation
        });
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No user logged in')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Submit Feedback'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rating bar
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            allowHalfRating: true,
            itemSize: 40.0,
            itemCount: 5,
            itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          SizedBox(height: 20),
          // Description text field
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Write your feedback here...',
              border: OutlineInputBorder(),
            ),
          ),
          if (_isLoading) // Show loading animation when submitting
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the pop-up
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : _submitFeedback, // Disable button while loading
          child: Text('Submit'),
        ),
      ],
    );
  }
}
