import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCompleteScreen extends StatefulWidget {
  final String postId;

  const PostCompleteScreen({
    required this.postId,
    super.key,
  });

  @override
  PostCompleteScreenState createState() => PostCompleteScreenState();
}

class PostCompleteScreenState extends State<PostCompleteScreen> {
  final TextEditingController tripBuddiesController = TextEditingController();
  final TextEditingController visitedPlacesController = TextEditingController();
  final TextEditingController tripDurationController = TextEditingController();

  final List<String> tripBuddies = [];
  final Map<String, Map<String, String>> userDetails = {};
  final List<String> visitedPlaces = [];
  String? tripFeedback;
  double? tripRating;
  int? tripCompletedDuration;

  bool visitedPlacesDisabled = false;

  bool isLoading = false;

  void _setLoading(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  @override
  void dispose() {
    tripBuddiesController.dispose();
    visitedPlacesController.dispose();
    tripDurationController.dispose();
    super.dispose();
  }

  Future<void> _addTag(
      String tag, TextEditingController controller, List<String> list) async {
    if (tag.isEmpty || list.contains(tag)) {
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Duplicate or empty tag detected!")),
      );
      return;
    }

    _setLoading(true);
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('user')
          .where('username', isEqualTo: tag)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Username exists, add the tag and save the document ID
        String userId = query.docs.first.id;
        String fullName = query.docs.first['fullname'] ?? "Unknown Name";
        String profileImage = query.docs.first['userimage'] ?? "";

        setState(() {
          list.add(tag);
          userDetails[tag] = {
            'userId': userId,
            'fullname': fullName,
            'userimage': profileImage,
          };
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Username does not exist")),
          );
        }
      }
    } catch (e) {
      print(e);
    } finally {
      _setLoading(false);
      controller.clear();
    }
  }

  void _handleTagInput(
      String value, TextEditingController controller, List<String> list) {
    String tag = value.trim().replaceAll(',', '').replaceAll('\n', '').trim();
    if (tag.isNotEmpty) {
      _addTag(tag, controller, list);
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
      userDetails.remove(tag);
    });
  }

  void _checkVisitedPlacesLimit() {
    if (visitedPlaces.length >= 8) {
      setState(() {
        visitedPlacesDisabled = true;
      });
    }
  }

  Future<void> _saveTripDetails() async {
    try {
      List<String> tripBuddiesIds = tripBuddies
          .map((username) {
            return userDetails[username]?['userId'] ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.postId)
          .update({
        'tripCompleted': true,
        'tripFeedback': tripFeedback,
        'tripRating': tripRating?.toInt(),
        'tripBuddies': tripBuddiesIds, // Save only user IDs
        'visitedPlaces': visitedPlaces,
        'tripCompletedDuration': tripCompletedDuration,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip completed')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed')),
        );
      }
    }
  }

  Future<void> _onComplete() async {
    final String remainingBuddyText = tripBuddiesController.text.trim();
    final String remainingPlaceText = visitedPlacesController.text.trim();
    if (remainingPlaceText.isNotEmpty) {
      _addLocTag(remainingPlaceText, visitedPlacesController, visitedPlaces);
    }

    if (remainingBuddyText.isNotEmpty) {
      await _addTag(remainingBuddyText, tripBuddiesController, tripBuddies);
    }

    // Validate that all buddies exist
    final List<String> nonExistentBuddies = tripBuddies.where((buddy) {
      return !userDetails.containsKey(buddy);
    }).toList();

    if (nonExistentBuddies.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Buddy not found: ${nonExistentBuddies.join(", ")}',
          ),
        ),
      );
      return;
    }
    if (tripBuddies.isEmpty ||
        visitedPlaces.isEmpty ||
        tripFeedback == null ||
        tripRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
    } else {
      _saveTripDetails();
    }
  }

  void _addLocTag(
      String tag, TextEditingController controller, List<String> list) {
    if (tag.isNotEmpty && !list.contains(tag)) {
      setState(() {
        list.add(tag);
      });
      controller.clear();
    } else {
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Duplicate tag detected!")),
      );
    }
  }

  void _handleLocTagInput(
      String value, TextEditingController controller, List<String> list) {
    String tag = value.trim().replaceAll(',', '').replaceAll('\n', '').trim();
    if (tag.isNotEmpty) {
      _addLocTag(tag, controller, list);
    }
  }

  void _removeLocTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Trip Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Trip Rating
                RatingBar.builder(
                  initialRating: tripRating ?? 0,
                  minRating: 1,
                  itemSize: 30,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.yellow),
                  onRatingUpdate: (rating) =>
                      setState(() => tripRating = rating),
                ),
                const SizedBox(height: 10),

                // Trip Buddies Input
                TextField(
                  controller: tripBuddiesController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Buddies (comma separated)',
                  ),
                  onChanged: (value) {
                    if (value.endsWith(",") || value.endsWith("\n")) {
                      _handleTagInput(
                          value, tripBuddiesController, tripBuddies);
                    }
                  },
                  onSubmitted: (value) {
                    _handleTagInput(value, tripBuddiesController, tripBuddies);
                  },
                ),
                Wrap(
                  children: tripBuddies.map((tag) {
                    final userDetail = userDetails[tag];
                    final fullName = userDetail?['fullname'] ?? "Unknown";
                    final profileImage = userDetail?['userimage'] ?? "";

                    return Chip(
                      labelPadding: const EdgeInsets.all(4.0),
                      avatar: profileImage.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(profileImage),
                              radius: 12, // Small user image size
                            )
                          : const CircleAvatar(
                              backgroundColor: Colors.grey,
                              radius: 12, // Small default avatar size
                              child: Icon(Icons.person, size: 14),
                            ),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Username (with reduced text size)
                          Flexible(
                            child: Text(
                              tag,
                              style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight
                                      .bold), // Smaller font for username
                              overflow: TextOverflow
                                  .ellipsis, // Ensure long text is truncated
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Full Name (smaller font size)
                          Flexible(
                            child: Text(
                              fullName,
                              style: const TextStyle(
                                  fontSize: 5,
                                  color:
                                      Colors.grey), // Smaller font for fullname
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag, tripBuddies),
                    );
                  }).toList(),
                ),

                // Visited Places Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: visitedPlacesController,
                        decoration: const InputDecoration(
                          labelText: 'Visited Places (comma separated)',
                        ),
                        enabled: !visitedPlacesDisabled,
                        onChanged: (value) {
                          if (value.endsWith(",") || value.endsWith("\n")) {
                            _handleLocTagInput(
                                value, visitedPlacesController, visitedPlaces);
                            _checkVisitedPlacesLimit();
                          }
                        },
                        onSubmitted: (value) {
                          if (!visitedPlacesDisabled) {
                            _handleLocTagInput(
                                value, visitedPlacesController, visitedPlaces);
                            _checkVisitedPlacesLimit();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        _setLoading(true);
                        try {
                          DocumentSnapshot postSnapshot =
                              await FirebaseFirestore.instance
                                  .collection('post')
                                  .doc(widget.postId)
                                  .get();

                          if (postSnapshot.exists) {
                            List<dynamic> planToVisitPlaces =
                                postSnapshot['planToVisitPlaces']
                                    as List<dynamic>;

                            setState(() {
                              visitedPlaces.addAll(
                                planToVisitPlaces
                                    .map((place) => place.toString())
                                    .where((place) =>
                                        !visitedPlaces.contains(place)),
                              );
                            });
                            _checkVisitedPlacesLimit();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Post not found")),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Error fetching planned places")),
                            );
                          }
                        } finally {
                          _setLoading(false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text(
                        'Same as \n Planned',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  children: visitedPlaces.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => _removeLocTag(tag, visitedPlaces),
                    );
                  }).toList(),
                ),

                TextField(
                  decoration: const InputDecoration(labelText: 'Trip Feedback'),
                  onChanged: (value) => tripFeedback = value,
                ),

                TextField(
                  controller: tripDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Trip Duration (in Days)',
                  ),
                  onChanged: (value) {
                    setState(() {
                      tripCompletedDuration = int.tryParse(value);
                    });
                  },
                ),

                ElevatedButton(
                  onPressed: isLoading ? null : _onComplete,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Complete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
