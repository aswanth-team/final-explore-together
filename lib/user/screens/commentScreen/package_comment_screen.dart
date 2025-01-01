import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../utils/counder.dart';

class PackageCommentSheet extends StatefulWidget {
  final String packageId;

  const PackageCommentSheet({
    super.key,
    required this.packageId,
  });

  @override
  PackageCommentSheetState createState() => PackageCommentSheetState();
}

class PackageCommentSheetState extends State<PackageCommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> comments = [];
  bool isEditing = false;
  String? editingCommentId;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
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
      final currentUserComments =
          loadedComments.where((c) => c['commentBy'] == currentUserId).toList();
      final otherComments =
          loadedComments.where((c) => c['commentBy'] != currentUserId).toList();
      otherComments.shuffle();

      setState(() {
        comments = [...currentUserComments, ...otherComments];
      });
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();
      final commentData = {
        'commentBy': currentUserId,
        'comment': _commentController.text.trim(),
        'commentedTime': FieldValue.serverTimestamp(),
      };
      _commentController.clear();
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .update({
        'comments.$commentId': commentData,
      });
      _loadComments();
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<void> _editComment(String commentId, String newComment) async {
    try {
      _commentController.clear();
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .update({
        'comments.$commentId.comment': newComment,
      });

      setState(() {
        isEditing = false;
        editingCommentId = null;
      });
      _loadComments();
    } catch (e) {
      print('Error editing comment: $e');
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
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
          if (comment['commentBy'] == currentUserId) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Comment'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  isEditing = true;
                  editingCommentId = comment['id'];
                  _commentController.text = comment['comment'];
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Comment'),
              onTap: () {
                Navigator.pop(context);
                _deleteComment(comment['id']);
              },
            ),
          ]
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
                Row(
                  children: [
                    const Text(
                      'Comments:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      formatCount(comments.length),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
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
                      trailing: (comment['commentBy'] == currentUserId)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showCommentOptions(comment),
                                ),
                              ],
                            )
                          : null,
                    ),
                    if (index != comments.length - 1) const Divider(),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 8,
              right: 8,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextFormField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: isEditing
                            ? 'Edit your comment...'
                            : 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: IconButton(
                    icon: Icon(isEditing ? Icons.check : Icons.send),
                    onPressed: () {
                      if (isEditing && editingCommentId != null) {
                        _editComment(
                            editingCommentId!, _commentController.text);
                      } else {
                        _addComment();
                      }
                    },
                    splashColor: Colors.blueAccent.withOpacity(0.3),
                    splashRadius: 25,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
