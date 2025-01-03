import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/counder.dart';
import '../../../utils/floating_button.dart';
import '../../../utils/image_swipe.dart';
import '../../../utils/loading.dart';
import '../aiChat/ai_chat_screen.dart';
import '../commentScreen/comment_screen.dart';
import '../profileScreen/post&trip/post_detail_screen.dart';
import '../uploadScreen/upload_bottom_sheet.dart';
import '../userDetailsScreen/others_user_profile.dart';
import '../userDetailsScreen/post&trip/post&trip/other_user_post_detail_screen.dart';
import '../user_screen.dart';
import 'notification_sceen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _searchQuery = "";
  List<String> suggestions = [];
  bool isSearchTriggered = false;
  bool isLoading = false;
  List<DocumentSnapshot> posts = [];
  Map<String, Map<String, dynamic>> users = {};
  Map<String, bool> likedPosts = {};
  Map<String, int> commentCounts = {};
  Map<String, int> likeCounts = {};
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  Future<void> _fetchCommentCounts(String postId) async {
    try {
      final postDoc =
          await FirebaseFirestore.instance.collection('post').doc(postId).get();
      final comments =
          postDoc.data()?['comments'] as Map<String, dynamic>? ?? {};
      setState(() {
        commentCounts[postId] = comments.length;
      });
    } catch (e) {
      print('Error fetching comment count: $e');
    }
  }

  void _showCommentSheet(
      BuildContext context, String postId, String postUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentSheet(postId: postId, postUserId: postUserId),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchSuggestions();
    _fetchPosts();
  }

  Future<void> toggleLike(String postId) async {
    setState(() {
      bool newLikeStatus = !(likedPosts[postId] ?? false);
      likedPosts[postId] = newLikeStatus;
      likeCounts[postId] = (likeCounts[postId] ?? 0) + (newLikeStatus ? 1 : -1);
    });

    try {
      DocumentReference postRef =
          FirebaseFirestore.instance.collection('post').doc(postId);

      if (likedPosts[postId] ?? false) {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId])
        });
      }
    } catch (e) {
      setState(() {
        bool revertedLikeStatus = !(likedPosts[postId] ?? false);
        likedPosts[postId] = revertedLikeStatus;
        likeCounts[postId] =
            (likeCounts[postId] ?? 0) + (revertedLikeStatus ? 1 : -1);
      });
      print('Error toggling like: $e');
    }
  }

  void _showSuggestions() {
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, kToolbarHeight + 10.0),
          child: Material(
            elevation: 4.0,
            child: Container(
              height: 200, // Fixed height for suggestions
              color: Colors.white,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  if (!suggestion
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    title: Text(
                      suggestion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    trailing: const Icon(Icons.search, color: Colors.grey),
                    onTap: () {
                      setState(() {
                        _searchController.text = suggestion;
                        _searchQuery = suggestion;
                        isSearchTriggered = true;
                      });
                      _removeOverlay();
                      _searchPosts();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> fetchSuggestions() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('post').get();

    if (!mounted) return;

    final suggestionSet = <String>{};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      suggestionSet.add(data['locationName'] ?? '');
      suggestionSet.addAll(List<String>.from(data['visitedPlaces'] ?? []));
      suggestionSet.addAll(List<String>.from(data['planToVisitPlaces'] ?? []));
    }

    if (mounted) {
      setState(() {
        suggestions = suggestionSet.toList();
      });
    }
  }

  Future<void> _fetchPosts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('post')
          .where('userid', isNotEqualTo: currentUserId)
          .get();

      await _fetchUsersForPosts(querySnapshot.docs);

      if (mounted) {
        setState(() {
          posts = querySnapshot.docs;
          posts.shuffle();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUsersForPosts(List<DocumentSnapshot> newPosts) async {
    final userIds = newPosts.map((post) => post['userid']).toSet();

    if (userIds.isEmpty) return;

    try {
      final userSnapshots = await FirebaseFirestore.instance
          .collection('user')
          .where(FieldPath.documentId, whereIn: userIds.toList())
          .get();

      final newUsers = {for (var doc in userSnapshots.docs) doc.id: doc.data()};

      for (var post in newPosts) {
        final likes = List<String>.from(post['likes'] ?? []);
        likedPosts[post.id] = likes.contains(currentUserId);
        likeCounts[post.id] = likes.length;
      }

      for (var post in newPosts) {
        _fetchCommentCounts(post.id);
      }

      if (mounted) {
        setState(() {
          users.addAll(newUsers);
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _searchPosts() async {
    setState(() {
      isLoading = true;
      posts.clear();
    });

    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('post').get();

      final filteredPosts = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final locationName =
            data['locationName']?.toString().toLowerCase() ?? "";
        final visitedPlaces = List<String>.from(data['visitedPlaces'] ?? [])
            .map((e) => e.toLowerCase())
            .toList();
        final planToVisitPlaces =
            List<String>.from(data['planToVisitPlaces'] ?? [])
                .map((e) => e.toLowerCase())
                .toList();

        final allSearchableFields = [
          locationName,
          ...visitedPlaces,
          ...planToVisitPlaces
        ];
        return allSearchableFields.any(
            (field) => field.similarityTo(_searchQuery.toLowerCase()) > 0.6);
      }).toList();

      await _fetchUsersForPosts(filteredPosts);

      if (mounted) {
        setState(() {
          posts = filteredPosts;
          posts.shuffle();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching posts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      posts.clear();
    });
    await _fetchPosts();
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _scrollController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10.0),
        child: AppBar(
          toolbarHeight: kToolbarHeight + 10.0,
          title: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                isSearchTriggered = false;
                if (value.isNotEmpty) {
                  _showSuggestions();
                } else {
                  _removeOverlay();
                }
              });
            },
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
                isSearchTriggered = true;
              });
              _removeOverlay();
              _searchPosts();
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = "";
                          isSearchTriggered = false;
                          _fetchPosts();
                        });
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
            ),
          ),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user')
                  .doc(currentUserId)
                  .collection('notifications')
                  .where('isSeen', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unseenCount = 0;
                if (snapshot.hasData) {
                  unseenCount = snapshot.data!.docs.length;
                }

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        size: 30.0,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                    ),
                    if (unseenCount > 0)
                      Positioned(
                        right: 14,
                        top: 13,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 10,
                            minHeight: 10,
                          ),
                          child: Text(
                            '$unseenCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_searchQuery.isNotEmpty && !isSearchTriggered)
                Expanded(
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      if (!suggestion
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(suggestion),
                        onTap: () {
                          setState(() {
                            _searchController.text = suggestion;
                            _searchQuery = suggestion;
                            isSearchTriggered = true;
                            _searchPosts();
                          });
                        },
                      );
                    },
                  ),
                ),
              Expanded(
                child: posts.isEmpty && !isLoading
                    ? const Center(
                        child: Text(
                          'No posts available',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshPosts,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: posts.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == posts.length) {
                              return Center(
                                child: const LoadingAnimation(),
                              );
                            }

                            var post =
                                posts[index].data() as Map<String, dynamic>;
                            String postId = posts[index].id;
                            String userId = post['userid'];
                            if (!users.containsKey(userId)) return Container();

                            var user = users[userId]!;
                            if (user['isRemoved'] == true) return Container();

                            String locationName = post['locationName'];
                            String locationDescription =
                                post['locationDescription'];
                            List locationImages = post['locationImages'];
                            bool tripCompleted = post['tripCompleted'];
                            bool isLiked = likedPosts[postId] ?? false;
                            int likeCount = likeCounts[postId] ?? 0;

                            return GestureDetector(
                              onTap: () {
                                if (userId == currentUserId) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CurrentUserPostDetailScreen(
                                        postId: postId,
                                        userId: userId,
                                        commentCount:
                                            commentCounts[postId] ?? 0,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OtherUserPostDetailScreen(
                                        postId: postId,
                                        userId: userId,
                                        commentCount:
                                            commentCounts[postId] ?? 0,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                color: tripCompleted
                                    ? Colors.green[50]
                                    : Colors.white,
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  if (userId == currentUserId) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const UserScreen(
                                                                  initialIndex:
                                                                      4)),
                                                    );
                                                  } else {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              OtherProfilePage(
                                                                  userId:
                                                                      userId)),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: AppColors
                                                          .genderBorderColor(
                                                              user['gender']),
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 20,
                                                    backgroundImage:
                                                        CachedNetworkImageProvider(
                                                            user['userimage']),
                                                    backgroundColor:
                                                        Colors.transparent,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                onTap: () {
                                                  if (userId == currentUserId) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const UserScreen(
                                                                  initialIndex:
                                                                      4)),
                                                    );
                                                  } else {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              OtherProfilePage(
                                                                  userId:
                                                                      userId)),
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  user['username'],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          ImageCarousel(
                                              locationImages: locationImages),
                                          const SizedBox(height: 16.0),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Text(
                                              locationName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0, horizontal: 30),
                                            child: Text(
                                              locationDescription,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isLiked
                                                  ? Colors.red
                                                  : Colors.grey,
                                              size: 28,
                                            ),
                                            onPressed: () => toggleLike(postId),
                                          ),
                                          Text(
                                            formatCount(likeCount),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Row(
                                        children: [
                                          Text(
                                            formatCount(
                                                commentCounts[postId] ?? 0),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.comment_outlined,
                                              color: Colors.grey,
                                              size: 24,
                                            ),
                                            onPressed: () => _showCommentSheet(
                                                context, postId, userId),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    width: 35,
                    height: 35,
                    child: FloatingChatButton(
                      heroTag: 'Home_AI_Chat',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AiChatPage()),
                        );
                      },
                      imageIcon: const AssetImage(
                          "assets/system/iconImage/blueaiIcon.png"),
                      buttonColor: Colors.white,
                      iconColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: FloatingActionButton(
                      heroTag: 'Home_Upload_Button',
                      onPressed: () {
                        BottomSheetModal.showModal(context);
                      },
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
