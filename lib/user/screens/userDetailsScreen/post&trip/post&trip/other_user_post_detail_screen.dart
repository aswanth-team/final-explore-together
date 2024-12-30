import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../../services/post/firebase_post.dart';
import '../../../../../services/user/user_services.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/counder.dart';
import '../../../../../utils/loading.dart';
import '../../../chat_&_group/chatScreen/chating_screen.dart';
import '../../../commentScreen/comment_screen.dart';
import '../../../../../utils/image_swipe.dart';
import '../../../user_screen.dart';
import '../../others_user_profile.dart';

class OtherUserPostDetailScreen extends StatefulWidget {
  final String postId;
  final String userId;

  const OtherUserPostDetailScreen({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  State<OtherUserPostDetailScreen> createState() =>
      _OtherUserPostDetailScreenState();
}

class _OtherUserPostDetailScreenState extends State<OtherUserPostDetailScreen> {
  final UserService _userService = UserService();
  final UserPostServices _userPostServices = UserPostServices();
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLiked = false;
  int likeCount = 0;

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentSheet(postId: widget.postId, postUserId: widget.userId),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.postId)
          .get();

      if (postDoc.exists) {
        final likes = List<String>.from(postDoc.data()?['likes'] ?? []);
        setState(() {
          isLiked = likes.contains(currentUserId);
          likeCount = likes.length;
        });
      }
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('post').doc(widget.postId);

      // Optimistically update UI
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1; // Update like count optimistically
      });

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw Exception('Post does not exist!');
        }

        List<String> likes = List<String>.from(postDoc.data()?['likes'] ?? []);

        if (isLiked) {
          if (!likes.contains(currentUserId)) {
            likes.add(currentUserId);
          }
        } else {
          likes.remove(currentUserId);
        }

        transaction.update(postRef, {'likes': likes});
      });
    } catch (e) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });
      print('Error toggling like: $e');
    }
  }

  void _reloadChats() {}

  Future<String> _getOrCreateChatRoom() async {
    try {
      final chatQuery = await FirebaseFirestore.instance
          .collection('chat')
          .where('user', arrayContains: currentUserId)
          .get();
      for (var doc in chatQuery.docs) {
        final userIds = doc.data()['user'] as List<dynamic>? ?? [];
        if (userIds.contains(widget.userId)) {
          return doc.id;
        }
      }
      final newChatDoc =
          await FirebaseFirestore.instance.collection('chat').add({
        'user': [currentUserId, widget.userId],
        'latestMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return newChatDoc.id;
    } catch (error) {
      throw Exception('Error creating or retrieving chat room: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          _userService.fetchUserDetails(userId: widget.userId),
          _userPostServices.fetchPostDetails(postId: widget.postId),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingAnimation();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final userData = snapshot.data![0] as Map<String, dynamic>;
            final postData = snapshot.data![1] as Map<String, dynamic>;
            final username = userData['username'];
            final userimage = userData['userimage'] ??
                [
                  'https://res.cloudinary.com/dakew8wni/image/upload/v1733819145/public/userImage/fvv6lbzdjhyrc1fhemaj.jpg'
                ];
            final gender = userData['gender'];

            final locationDescription =
                postData['locationDescription'] ?? 'unKnown';
            final locationName = postData['locationName'] ?? 'unKnown';
            final tripDuration = postData['tripDuration'] ?? 0;
            final isTripCompleted = postData['tripCompleted'];
            final tripRating = (postData['tripRating'] ?? 0).toDouble();

            final tripFeedback = postData['tripFeedback'];
            final tripBuddies = postData['tripBuddies'] ?? ['user1', 'user2'];
            final locationImages = postData['locationImages'] ??
                [
                  'https://res.cloudinary.com/dakew8wni/image/upload/v1734019072/public/postimages/mwtjtugc4ppu02vwiv49.png'
                ];
            final visitedPalaces = postData['visitedPlaces'] ?? [];
            final planToVisitPlaces = postData['planToVisitPlaces'];
            final tripCompletedDuration = postData['tripCompletedDuration'];

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtherProfilePage(
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 30.0,
                                backgroundImage:
                                    CachedNetworkImageProvider(userimage),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text('Gender: $gender'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        ImageCarousel(locationImages: locationImages),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.favorite,
                                color: isLiked ? Colors.red : Colors.grey,
                                size: 30,
                              ),
                              onPressed: _toggleLike,
                            ),
                            Text(
                              formatCount(likeCount),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(
                                Icons.comment_outlined,
                                color: Colors.grey,
                                size: 30,
                              ),
                              onPressed: () => _showCommentSheet(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Trip to $locationName ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Text(
                                    locationDescription,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                              ],
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.black,
                          thickness: 2.0,
                          indent: 20.0,
                          endIndent: 20.0,
                        ),
                        const SizedBox(height: 10.0),
                        if (!isTripCompleted) ...[
                          Center(
                            child: Text(
                              'Trip Duration Plan : $tripDuration days',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          if (planToVisitPlaces.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: Text(
                                      'Visiting Places Plan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromARGB(255, 255, 200, 118),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final crossAxisCount =
                                          (constraints.maxWidth / 100).floor();
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount > 0
                                              ? crossAxisCount
                                              : 1,
                                          crossAxisSpacing: 8.0,
                                          mainAxisSpacing: 8.0,
                                          childAspectRatio: 2,
                                        ),
                                        itemCount: planToVisitPlaces.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 244, 255, 215),
                                              border: Border.all(
                                                  color: Colors.grey),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: Center(
                                              child: Text(
                                                planToVisitPlaces[index],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8.0),
                        ],
                        if (isTripCompleted) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Trip Completed',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                const SizedBox(height: 8.0),
                                if (tripBuddies.isNotEmpty) ...[
                                  GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10.0,
                                      mainAxisSpacing: 10.0,
                                    ),
                                    itemCount: tripBuddies.length,
                                    itemBuilder: (context, index) {
                                      final buddyUserId = tripBuddies[index];
                                      return FutureBuilder<
                                          Map<String, dynamic>>(
                                        future: _userService.fetchUserDetails(
                                            userId: buddyUserId),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            final buddy = snapshot.data!;
                                            String gender =
                                                buddy['gender'].toLowerCase();

                                            Color gridColor =
                                                AppColors.genderBorderColor(
                                                    gender);

                                            return GestureDetector(
                                              onTap: () {
                                                if (buddyUserId !=
                                                    currentUserId) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OtherProfilePage(
                                                        userId: buddyUserId,
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const UserScreen(
                                                              initialIndex: 4),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Card(
                                                elevation: 5.0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                ),
                                                color: gridColor,
                                                child: Column(
                                                  children: [
                                                    const SizedBox(
                                                        height: 20.0),
                                                    CircleAvatar(
                                                      radius: 25.0,
                                                      backgroundImage:
                                                          CachedNetworkImageProvider(
                                                              buddy[
                                                                  'userimage']),
                                                    ),
                                                    const SizedBox(width: 10.0),
                                                    Expanded(
                                                      child: Text(
                                                        buddy['username'],
                                                        style: const TextStyle(
                                                            fontSize: 10),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else if (snapshot.hasError) {
                                            return Center(
                                                child: Text(
                                                    'Error: ${snapshot.error}'));
                                          }
                                          return const SizedBox();
                                        },
                                      );
                                    },
                                  )
                                ],
                                const SizedBox(height: 15.0),
                                if (visitedPalaces.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Center(
                                          child: Text(
                                            'Visited Places',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 255, 104, 16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final crossAxisCount =
                                                (constraints.maxWidth / 100)
                                                    .floor();
                                            return GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount:
                                                    crossAxisCount > 0
                                                        ? crossAxisCount
                                                        : 1,
                                                crossAxisSpacing: 8.0,
                                                mainAxisSpacing: 8.0,
                                                childAspectRatio: 2,
                                              ),
                                              itemCount: visitedPalaces.length,
                                              itemBuilder: (context, index) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                        255, 179, 255, 251),
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      visitedPalaces[index],
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 8.0),
                                if (tripRating != null)
                                  RatingBar.builder(
                                    initialRating: tripRating,
                                    minRating: 0,
                                    itemSize: 20,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.yellow,
                                    ),
                                    onRatingUpdate: (rating) {
                                      print(rating);
                                    },
                                  ),
                                const SizedBox(height: 20.0),
                                if (tripFeedback != null)
                                  Text(
                                    'Feedback : $tripFeedback',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                const SizedBox(height: 8.0),
                                if (tripCompletedDuration != null)
                                  Text(
                                    'Trip Duration : $tripCompletedDuration',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isTripCompleted)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton.extended(
                        onPressed: () async {
                          try {
                            final chatRoomId = await _getOrCreateChatRoom();
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  currentUserId: currentUserId,
                                  chatUserId: widget.userId,
                                  chatRoomId: chatRoomId,
                                  onMessageSent: _reloadChats,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        backgroundColor: Colors.greenAccent,
                        label: const Text('Contact',
                            style: TextStyle(fontSize: 16.0)),
                        icon: const Icon(Icons.chat),
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}