import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  Set<String> shownPostIds = {};
  final Random _random = Random();

  String _searchQuery = "";
  List<String> suggestions = [];
  bool isSearchTriggered = false;
  bool isLoading = false;
  bool hasMorePosts = true;
  bool isOffline = false;

  List<DocumentSnapshot> posts = [];
  Map<String, Map<String, dynamic>> users = {};
  Map<String, bool> likedPosts = {};
  Map<String, int> commentCounts = {};

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

  Map<String, int> likeCounts = {};

  DocumentSnapshot? _lastDocument;
  final int _pageSize = 5;

  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;

  @override
  void initState() {
    super.initState();
    fetchSuggestions();
    _initializeConnectivity();
    _scrollController.addListener(_onScroll);
    _fetchInitialPosts();
  }

  Future<void> toggleLike(String postId) async {
    if (isOffline) return;
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

  Future<void> _initializeConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          isOffline = connectivityResult == ConnectivityResult.none;
        });
      }
      connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        if (mounted) {
          setState(() {
            isOffline = results.contains(ConnectivityResult.none);
          });
        }
      });
    } catch (e) {
      print('Error initializing connectivity: $e');
    }
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

  Future<void> _fetchInitialPosts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final randomQuery = await FirebaseFirestore.instance
          .collection('post')
          .orderBy(FieldPath.documentId)
          .limit(_pageSize)
          .get();
      final filteredDocs = randomQuery.docs
          .where((doc) => !shownPostIds.contains(doc.id))
          .toList();

      if (filteredDocs.isEmpty) {
        if (mounted) {
          setState(() {
            hasMorePosts = false;
            isLoading = false;
          });
        }
        return;
      }
      filteredDocs.shuffle(_random);
      for (var doc in filteredDocs) {
        shownPostIds.add(doc.id);
      }
      _lastDocument = filteredDocs.last;
      await _fetchUsersForPosts(filteredDocs);

      if (mounted) {
        setState(() {
          posts = filteredDocs;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching initial posts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMorePosts() async {
    if (!hasMorePosts || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('post')
          .orderBy(FieldPath.documentId)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();
      final filteredDocs = querySnapshot.docs
          .where((doc) => !shownPostIds.contains(doc.id))
          .toList();

      if (filteredDocs.isEmpty) {
        if (mounted) {
          setState(() {
            hasMorePosts = false;
            isLoading = false;
          });
        }
        return;
      }
      filteredDocs.shuffle(_random);
      for (var doc in filteredDocs) {
        shownPostIds.add(doc.id);
      }
      _lastDocument = filteredDocs.last;
      await _fetchUsersForPosts(filteredDocs);

      if (mounted) {
        setState(() {
          posts.addAll(filteredDocs);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching more posts: $e');
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

      // Check liked status and count for each post
      for (var post in newPosts) {
        final likes = List<String>.from(post['likes'] ?? []);
        likedPosts[post.id] = likes.contains(currentUserId);
        likeCounts[post.id] = likes.length; // Store the count
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
      hasMorePosts = true;
      _lastDocument = null;
    });

    try {
      Query query =
          FirebaseFirestore.instance.collection('post').limit(_pageSize);

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            hasMorePosts = false;
            isLoading = false;
          });
        }
        return;
      }
      final filteredPosts = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
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

      if (filteredPosts.isEmpty) {
        if (mounted) {
          setState(() {
            hasMorePosts = false;
            isLoading = false;
          });
        }
        return;
      }

      _lastDocument = filteredPosts.last;

      await _fetchUsersForPosts(filteredPosts);

      if (mounted) {
        setState(() {
          posts = filteredPosts;
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

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_searchQuery.isNotEmpty) {
        _searchPosts();
      } else {
        _fetchMorePosts();
      }
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      posts.clear();
      shownPostIds.clear();
      _lastDocument = null;
      hasMorePosts = true;
    });
    await _fetchInitialPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    connectivitySubscription.cancel();
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
            enabled: !isOffline,
            controller: _searchController,
            onChanged: isOffline
                ? null
                : (value) {
                    setState(() {
                      _searchQuery = value;
                      isSearchTriggered = false;
                    });
                  },
            onSubmitted: isOffline
                ? null
                : (value) {
                    setState(() {
                      _searchQuery = value;
                      isSearchTriggered = true;
                      _searchPosts();
                    });
                  },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: isOffline ? 'You are offline' : 'Search...',
              hintStyle: isOffline
                  ? TextStyle(color: Colors.red[500], fontSize: 16)
                  : TextStyle(color: Colors.grey[500], fontSize: 16),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[600],
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                      ),
                      onPressed: isOffline
                          ? null // Disable clearing search when offline
                          : () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = "";
                                isSearchTriggered = false;
                                _fetchInitialPosts();
                              });
                            },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                    color: Colors.blue, width: 2), // Add a border here
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                    color: Colors.blue, width: 2), // Border when focused
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(
                    color: Colors.grey, width: 1), // Border when enabled
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
                        onRefresh: isOffline ? () async {} : _refreshPosts,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: posts.length + (isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == posts.length) {
                              return Center(
                                child: isOffline
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'You are offline',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          LoadingAnimation(),
                                        ],
                                      )
                                    : const LoadingAnimation(),
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
                                            )),
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
                                    ? Colors.green[100]
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
                        //showDialog(
                        //    context: context,
                        //    builder: (_) => const ChatPopup(),
                        //   );
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
                      child: const Icon(
                        Icons.add,
                        size: 28,
                      ),
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
