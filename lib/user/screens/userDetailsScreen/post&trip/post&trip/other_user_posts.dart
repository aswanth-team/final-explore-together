import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../services/post/firebase_post.dart';
import '../../../../../utils/loading.dart';
import 'other_user_post_detail_screen.dart';

class UserPostsWidget extends StatefulWidget {
  final String userId;

  const UserPostsWidget({
    super.key,
    required this.userId,
  });

  @override
  UserPostsWidgetState createState() => UserPostsWidgetState();
}

class UserPostsWidgetState extends State<UserPostsWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: UserPostServices().fetchUserPosts(userId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingAnimation();
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching posts.'));
        }

        final userPosts = snapshot.data ?? [];

        return userPosts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    Text('🚫', style: TextStyle(fontSize: 50)),
                    Text('No posts available'),
                  ],
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.80,
                ),
                itemCount: userPosts.length,
                itemBuilder: (context, index) {
                  final post = userPosts[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserPostDetailScreen(
                            postId: post['postId'],
                            userId: widget.userId,
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: (post['tripCompleted'] ?? false)
                                ? Colors.green[100]
                                : Colors.white,
                            border: Border.all(color: Colors.grey, width: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 138, 222, 255)
                                    .withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image(
                                  image: CachedNetworkImageProvider(
                                    post['locationImages']?.isNotEmpty == true
                                        ? post['locationImages'][0]
                                        : 'https://res.cloudinary.com/dakew8wni/image/upload/v1734019072/public/postimages/mwtjtugc4ppu02vwiv49.png',
                                  ),
                                  fit: BoxFit.cover,
                                  height: 100,
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    post['locationName'] ?? 'Unknown Location',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.black,
                                      height: 1.2,
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
                },
              );
      },
    );
  }
}
