import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/counder.dart';
import '../../../utils/loading.dart';
import '../BuddyScreen/buddies_screen.dart';
import '../BuddyScreen/buddying_screen.dart';
import '../homeScreen/notification_sceen.dart';
import '../uploadScreen/upload_bottom_sheet.dart';
import 'edit_profile_screen.dart';
import 'post&trip/current_user_posts.dart';
import 'post&trip/current_user_tripimage.dart';
import 'settingScreen/settings_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool showPosts = true;
  int totalPosts = 0;
  int completedPosts = 0;
  int buddiesCount = 0;
  int buddyingCount = 0;

  Future<void> _getBuddyingCount() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserId)
          .get();

      final buddingList = userDoc.data()?['buddying'] ?? [];
      setState(() {
        buddyingCount = buddingList.length;
      });
    } catch (e) {
      print('Error fetching buddies count: $e');
    }
  }

  Future<void> _getBuddiesCount() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserId)
          .get();

      final buddiesList = userDoc.data()?['buddies'] ?? [];
      setState(() {
        buddiesCount = buddiesList.length;
      });
    } catch (e) {
      print('Error fetching buddies count: $e');
    }
  }

  Future<void> _getUserProfilePosts() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      QuerySnapshot userPostsSnapshot = await FirebaseFirestore.instance
          .collection('post')
          .where('userid', isEqualTo: currentUserId)
          .get();

      List<QueryDocumentSnapshot> userPosts = userPostsSnapshot.docs;

      setState(() {
        totalPosts = userPosts.length;
        completedPosts =
            userPosts.where((doc) => doc['tripCompleted'] == true).length;
      });
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserProfilePosts();
    _getBuddiesCount();
    _getBuddyingCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      size: 27.0,
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
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Stack(
              children: [
                Positioned(
                  left: 0.0,
                  top: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  child: Center(child: LoadingAnimation()),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile data"));
          } else if (snapshot.hasData) {
            final profileData = snapshot.data?.data();
            var userImage = profileData!['userimage'];
            print(profileData);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: InteractiveViewer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.genderBorderColor(
                                                profileData['gender'] ?? ''),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image(
                                            image: CachedNetworkImageProvider(
                                                userImage),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.genderBorderColor(
                                    profileData['gender'] ?? ''),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  CachedNetworkImageProvider(userImage),
                              backgroundColor: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BuddiesPage(
                                              userId: currentUserId),
                                        ),
                                      );
                                    },
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            formatCount(buddiesCount),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'Buddies',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BuddyingUserPage(
                                                  userId: currentUserId),
                                        ),
                                      );
                                    },
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            formatCount(buddyingCount),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'Buddying',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatCount(totalPosts),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Posts',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 30),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatCount(completedPosts),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileData['fullname'],
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        //Text('DOB: ${profileData['dob']}'),
                        // const SizedBox(height: 8),
                        // Text('Gender: ${profileData['gender']}'),
                        // const SizedBox(height: 16),
                        Text(profileData['userbio'] ?? '',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if ((profileData['instagram']?.isNotEmpty ?? false))
                        IconButton(
                          onPressed: () {
                            final instagramLink = profileData['instagram'];
                            launchUrl(Uri.parse(instagramLink));
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.instagram,
                            color: Colors.purple,
                            size: 15,
                          ),
                          tooltip: 'Instagram',
                        ),
                      if ((profileData['instagram']?.isNotEmpty ?? false))
                        const SizedBox(width: 6),

                      // Twitter (X) Icon
                      if ((profileData['x']?.isNotEmpty ?? false))
                        IconButton(
                          onPressed: () {
                            final twitterLink = profileData['x'];
                            launchUrl(Uri.parse(twitterLink));
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.x,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 15,
                          ),
                          tooltip: 'X',
                        ),
                      if ((profileData['x']?.isNotEmpty ?? false))
                        const SizedBox(width: 6),

                      // Facebook Icon
                      if ((profileData['facebook']?.isNotEmpty ?? false))
                        IconButton(
                          onPressed: () {
                            final facebookLink = profileData['facebook'];
                            launchUrl(Uri.parse(facebookLink));
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.facebook,
                            color: Colors.blue,
                            size: 15,
                          ),
                          tooltip: 'Facebook',
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.95,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final userId =
                                        FirebaseAuth.instance.currentUser?.uid;

                                    if (userId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EditProfileScreen(
                                                    uuid: userId)),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 0.3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: const Text("Edit Profile"),
                                ),
                              ),
                              const SizedBox(width: 5),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SettingsPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 0.3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: const Text("Settings"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showPosts = true;
                                });
                              },
                              icon: const Icon(
                                Icons.grid_on,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Posts',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            if (showPosts)
                              Container(
                                height: 2,
                                width: 50,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showPosts = false;
                                });
                              },
                              icon: const Icon(
                                Icons.photo_album,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Trip Images',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            if (!showPosts)
                              Container(
                                height: 2,
                                width: 50,
                                color: Colors.black,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showPosts)
                    UserPostsWidget(
                        userId: FirebaseAuth.instance.currentUser!.uid),
                  if (!showPosts)
                    UserTripImagesWidget(
                        userId: FirebaseAuth.instance.currentUser!.uid),
                  const SizedBox(height: 10),
                ],
              ),
            );
          } else {
            return const Text("No data available");
          }
        },
      ),
      floatingActionButton: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 50,
          height: 50,
          child: FloatingActionButton(
            heroTag: 'Profile_Upload_Button',
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
    );
  }
}
