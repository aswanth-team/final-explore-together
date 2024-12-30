
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../utils/counder.dart';
import '../../../../utils/image_swipe.dart';
import '../../../../utils/loading.dart';
import 'admin_package_comment_view_screen.dart';
import 'edit_package_screen.dart';

class AdminPackageDetailsScreen extends StatefulWidget {
  final String documentId;
  final int commentCount;

  const AdminPackageDetailsScreen(
      {super.key, required this.documentId, required this.commentCount});

  @override
  AdminPackageDetailsScreenState createState() =>
      AdminPackageDetailsScreenState();
}

class AdminPackageDetailsScreenState extends State<AdminPackageDetailsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AdminViewPackageCommentSheet(packageId: widget.documentId),
    );
  }

  @override
  void initState() {
    super.initState();
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

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: const Text(
          'Delete Package',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete this package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePackage();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePackage() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: LoadingAnimation(),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.documentId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete package: $e')),
        );
      }
    }
  }

  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageEditScreen(documentId: widget.documentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmationDialog,
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
                      child: Text(
                        locationName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Places to Visit:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
