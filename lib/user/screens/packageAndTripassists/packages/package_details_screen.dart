
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../utils/confirm_dialogue.dart';
import '../../../../utils/counder.dart';
import '../../../../utils/image_swipe.dart';
import '../../../../utils/loading.dart';
import '../../commentScreen/package_comment_screen.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String documentId;
  final int commentCount;

  const PackageDetailsScreen(
      {super.key, required this.documentId, required this.commentCount});

  @override
  PackageDetailsScreenState createState() => PackageDetailsScreenState();
}

class PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _hasPosted = false;

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PackageCommentSheet(packageId: widget.documentId),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkIfPosted();
  }

  Future<void> _checkIfPosted() async {
    final packageDoc = await FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.documentId)
        .get();

    final packageData = packageDoc.data()!;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('post')
        .where('userid', isEqualTo: currentUserId)
        .where('locationName', isEqualTo: packageData['locationName'])
        .get();

    final isPosted = querySnapshot.docs.any((doc) {
      final postData = doc.data();
      return postData['locationDescription'] ==
              packageData['locationDescription'] &&
          postData['planToVisitPlaces'].toString() ==
              packageData['planToVisitPlaces'].toString() &&
          postData['locationImages'].toString() ==
              packageData['locationImages'].toString() &&
          postData['tripDuration'] == packageData['tripDuration'];
    });

    if (mounted) {
      setState(() {
        _hasPosted = isPosted;
      });
    }
  }

  void _showPostConfirmationDialog(Map<String, dynamic> packageData) {
    showConfirmationDialog(
      context: context,
      title: 'Post',
      message: 'Would you like to post this package?',
      cancelButtonText: 'Cancel',
      confirmButtonText: 'Post',
      onConfirm: () {
        uploadPost(packageData);
      },
      titleIcon: const Icon(Icons.post_add, color: Colors.blue),
      titleColor: Colors.blueAccent,
      messageColor: Colors.black87,
      cancelButtonColor: Colors.red,
      confirmButtonColor: Colors.blue,
      backgroundColor: Colors.white,
    );
  }

  Future<void> uploadPost(Map<String, dynamic> packageData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: LoadingAnimation(),
      ),
    );

    try {
      final postData = {
        'locationName': packageData['locationName'],
        'locationDescription': packageData['locationDescription'],
        'locationImages': packageData['locationImages'],
        'planToVisitPlaces': packageData['planToVisitPlaces'],
        'tripDuration': packageData['tripDuration'],
        'tripCompleted': false,
        'userid': currentUserId,
        'tripRating': null,
        'tripBuddies': null,
        'tripFeedback': null,
        'visitedPlaces': null,
        'uploadedDateTime': FieldValue.serverTimestamp(),
        'likes': null,
        'tripCompletedDuration': null,
      };
      await FirebaseFirestore.instance.collection('post').add(postData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload post: $e')),
        );
      }
    }
  }

  void _showPlaceDialog(String placeName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                placeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch phone dialer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Details..'),
        actions: [
          if (!_hasPosted)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('packages')
                  .doc(widget.documentId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final packageData =
                    snapshot.data!.data() as Map<String, dynamic>;

                return IconButton(
                  icon: const Icon(Icons.post_add),
                  onPressed: () {
                    _showPostConfirmationDialog(packageData);
                  },
                );
              },
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('packages')
            .doc(widget.documentId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: LoadingAnimation());
          }

          final package = snapshot.data!;
          final locationName = package['locationName'];
          final planToVisitPlaces = package['planToVisitPlaces'] as List;
          final images = package['locationImages'] as List;
          final prize = package['prize'];
          final description = package['locationDescription'];
          final packageData = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            children: [
              ImageCarousel(locationImages: images),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.comment_outlined,
                      color: Colors.grey,
                      size: 30,
                    ),
                    onPressed: () => _showCommentSheet(context),
                  ),
                  Text(
                    formatCount(widget.commentCount),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            locationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _hasPosted
                              ? const Text(
                                  'Already Posted',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    _showPostConfirmationDialog(packageData);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add in Your Post',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 16),
                          const Text(
                            'Places to Visit:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            (constraints.maxWidth / 100).floor();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                crossAxisCount > 0 ? crossAxisCount : 1,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 2,
                          ),
                          itemCount: planToVisitPlaces.length,
                          itemBuilder: (context, index) {
                            final placeName = planToVisitPlaces[index];

                            return GestureDetector(
                              onTap: () {
                                _showPlaceDialog(placeName);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: Center(
                                  child: Text(
                                    placeName.length > 15
                                        ? '${placeName.substring(0, 12)}...'
                                        : placeName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Prize: ₹$prize',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$description',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: null,
                            overflow: TextOverflow.visible,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 79),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 49,
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('packages')
            .doc(widget.documentId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final package = snapshot.data!;
          final contact = package['contact'];

          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 180,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: FloatingActionButton(
                onPressed: () => _launchPhoneDialer(contact),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Contact',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
