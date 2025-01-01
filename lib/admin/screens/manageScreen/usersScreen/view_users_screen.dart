import 'package:flutter/material.dart';
import '../../../../services/one_signal.dart';
import '../../../../services/user/user_services.dart';
import '../../../../utils/dialogues.dart';
import '../../../../utils/loading.dart';
import 'user_profile_view_screen.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  UserSearchPageState createState() => UserSearchPageState();
}

class UserSearchPageState extends State<UserSearchPage> {
  String query = "";
  String selectedCategory = "All";
  final List<String> categories = ["All", "Active", "Removed"];
  final UserService userService = UserService();

  Future<List<Map<String, dynamic>>> getFilteredUsers() async {
    final allUsers = await userService.fetchUsers();
    List<Map<String, dynamic>> filteredUsers = [];

    if (selectedCategory == "All") {
      filteredUsers = allUsers;
    } else if (selectedCategory == "Active") {
      filteredUsers = allUsers.where((user) => !user['isRemoved']).toList();
    } else if (selectedCategory == "Removed") {
      filteredUsers = allUsers.where((user) => user['isRemoved']).toList();
    }
    if (query.isNotEmpty) {
      filteredUsers = filteredUsers
          .where((user) =>
              user['userName'].toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    }

    return filteredUsers;
  }

  void _showConfirmationDialog(String userId, bool isRemoved, String username) {
    showConfirmationDialog(
      context: context,
      title: isRemoved ? 'Restrict User' : 'Reinstate User',
      message: isRemoved
          ? 'Are you sure you want to restrict this $username?'
          : 'Are you sure you want to reinstate this  $username?',
      cancelButtonText: 'Cancel',
      confirmButtonText: isRemoved ? 'Remove' : 'Add',
      onConfirm: () {
        updateUserStatus(userId, isRemoved);
      },
      titleIcon: isRemoved
          ? const Icon(Icons.delete_forever, color: Colors.red)
          : const Icon(Icons.add, color: Colors.green),
      titleColor: isRemoved ? Colors.redAccent : Colors.greenAccent,
      messageColor: Colors.black87,
      cancelButtonColor: Colors.blue,
      confirmButtonColor: isRemoved ? Colors.red : Colors.green,
      backgroundColor: Colors.white,
    );
  }

  Future<void> updateUserStatus(String userId, bool isRemoved) async {
    try {
      userService.updateUserRemovalStatus(userId: userId, isRemoved: isRemoved);
      final user = await UserService().fetchUserDetails(userId: userId);
      final List<String> playerIds = List<String>.from(user['onId'] ?? []);

      if (playerIds.isNotEmpty) {
        final title = isRemoved ? "Account Restricted" : "Account Reinstated";
        final description = isRemoved
            ? "Your account has been restricted. Please contact support for more details."
            : "Your account has been reinstated. You can now access all features.";
        await NotificationService().sentNotificationtoUser(
          title: title,
          description: description,
          onIds: playerIds,
        );
      }
      setState(() {});
    } catch (e) {
      print("Error updating user status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController(text: query),
              decoration: InputDecoration(
                hintText: "Search by username...",
                prefixIcon: const Icon(Icons.search),
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
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            query = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getFilteredUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingAnimation());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                final filteredUsers = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherProfilePageForAdmin(
                                userId: user['userId']),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 5,
                        color: user['isRemoved']
                            ? Colors.red.shade100
                            : Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(user['userImage']),
                                radius: 20,
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
                            ElevatedButton(
                              onPressed: () {
                                _showConfirmationDialog(
                                  user['userId'],
                                  !user['isRemoved'],
                                  user['userName'],
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: user['isRemoved']
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(4),
                              ),
                              child: Text(
                                user['isRemoved'] ? "+" : "-",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
