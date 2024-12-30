import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/user/user_services.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/loading.dart';
import '../userDetailsScreen/others_user_profile.dart';
import '../user_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  String query = "";
  List<Map<String, dynamic>> users = [];
  final UserService _userService = UserService();
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLoading = true;

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Map<String, dynamic>> fetchedUsers = await _userService.fetchUsers();
      if (mounted) {
        setState(() {
          users =
              fetchedUsers.where((user) => user['isRemoved'] == false).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint('Error fetching users: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredUsers = users
        .where((user) =>
            user['userName'].toLowerCase().startsWith(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 10.0,
        title: TextField(
          decoration: InputDecoration(
            hintText: "Search by username...",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        query = "";
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
          onChanged: (value) {
            setState(() {
              query = value;
            });
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: LoadingAnimation(),
            )
          : Column(
              children: [
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text("No users found"))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return GestureDetector(
                              onTap: () {
                                if (user['userId'] != currentUserId) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OtherProfilePage(
                                          userId: user['userId']),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UserScreen(initialIndex: 4),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 0),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.genderBorderColor(
                                                user['userGender']),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  user['userImage']),
                                          radius: 15,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        user['userName'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
