import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../../utils/counder.dart';

class AdminViewCommentSheet extends StatefulWidget {
  final String postId;

  const AdminViewCommentSheet({
    super.key,
    required this.postId,
  });

  @override
  AdminViewCommentSheetState createState() => AdminViewCommentSheetState();
}

class AdminViewCommentSheetState extends State<AdminViewCommentSheet> {
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.postId)
          .get();

      final commentsMap =
          postDoc.data()?['comments'] as Map<String, dynamic>? ?? {};

      final List<Map<String, dynamic>> loadedComments = [];
      for (var entry in commentsMap.entries) {
        final commentData = entry.value as Map<String, dynamic>;
        final userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(commentData['commentBy'])
            .get();

        loadedComments.add({
          'id': entry.key,
          ...commentData,
          'username': userDoc.data()?['username'],
          'userimage': userDoc.data()?['userimage'],
        });
      }

      final allComments = loadedComments.toList();
      allComments.shuffle();

      setState(() {
        comments = [...allComments];
      });
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.postId)
          .update({
        'comments.$commentId': FieldValue.delete(),
      });
      _loadComments();
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  void _showCommentOptions(Map<String, dynamic> comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Comment'),
            onTap: () {
              Navigator.pop(context);
              _deleteComment(comment['id']);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(comment['userimage']),
                      ),
                      title: Text(comment['username']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['comment'],
                            style: const TextStyle(fontSize: 14),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatTimestamp(
                              (comment['commentedTime'] as Timestamp).toDate(),
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showCommentOptions(comment),
                          ),
                        ],
                      ),
                    ),
                    if (index != comments.length - 1) const Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
