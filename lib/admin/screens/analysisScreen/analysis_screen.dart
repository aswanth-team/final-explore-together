
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/loading.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => AnalysisPageState();
}

class AnalysisPageState extends State<AnalysisPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _fetchAnalysisData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingAnimation();
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final data = snapshot.data as Map<String, dynamic>;
            return _buildAnalysisContent(context, data);
          } else {
            return const Center(child: Text("No data available."));
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchAnalysisData() async {
    final usersSnapshot = await _firestore.collection('user').get();
    final postsSnapshot = await _firestore.collection('post').get();

    // Fetch user statistics
    final users = usersSnapshot.docs.map((doc) => doc.data()).toList();
    final totalUsers = users.length;
    final totalRemovedUsers =
        users.where((user) => user['isRemoved'] == true).length;
    final totalActiveUsers = totalUsers - totalRemovedUsers;

    final maleCount = users
        .where((user) =>
            user['gender'].toLowerCase() == 'male' &&
            user['isRemoved'] == false)
        .length;
    final femaleCount = users
        .where((user) =>
            user['gender'].toLowerCase() == 'female' &&
            user['isRemoved'] == false)
        .length;
    final otherCount = users
        .where((user) =>
            user['gender'].toLowerCase() == 'other' &&
            user['isRemoved'] == false)
        .length;

    final removedMaleCount = users
        .where((user) =>
            user['gender'].toLowerCase() == 'male' && user['isRemoved'] == true)
        .length;
    final removedFemaleCount = users
        .where((user) =>
            user['gender'].toLowerCase() == 'female' &&
            user['isRemoved'] == true)
        .length;
    final removedOtherCount = users
        .where((user) =>
            user['gender'].toLowerCase() == 'other' &&
            user['isRemoved'] == true)
        .length;

    // Fetch post statistics
    final posts = postsSnapshot.docs.map((doc) => doc.data()).toList();
    final totalPosts = posts.length;
    final completedPosts =
        posts.where((post) => post['tripCompleted'] == true).length;
    final incompletedPosts = totalPosts - completedPosts;

    return {
      'totalUsers': totalUsers,
      'totalRemovedUsers': totalRemovedUsers,
      'totalActiveUsers': totalActiveUsers,
      'maleCount': maleCount,
      'femaleCount': femaleCount,
      'otherCount': otherCount,
      'totalPosts': totalPosts,
      'completedPosts': completedPosts,
      'incompletedPosts': incompletedPosts,
      'removedMaleCount': removedMaleCount,
      'removedFemaleCount': removedFemaleCount,
      'removedOtherCount': removedOtherCount,
    };
  }

  Widget _buildAnalysisContent(
      BuildContext context, Map<String, dynamic> data) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 40,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildStatColumn(data['totalUsers'], "Total Users"),
                  // const SizedBox(width: 50),
                  //_buildStatColumn(data['totalPosts'], "Total Posts"),
                ],
              ),
            ),
            const Divider(color: Colors.grey, thickness: 1, height: 20),
            const SizedBox(height: 30),
            // Removed Users Pie Chart
            _buildPieChartWithHeading(
              context,
              'Users Status',
              [
                PieChartSectionData(
                  value: data['totalRemovedUsers'].toDouble(),
                  color: Colors.red,
                  title: ' ',
                  radius: 50,
                ),
                PieChartSectionData(
                  value: data['totalActiveUsers'].toDouble(),
                  color: Colors.green,
                  title: ' ',
                  radius: 50,
                ),
              ],
              [
                "Active : ${data['totalActiveUsers']}",
                "Removed : ${data['totalRemovedUsers']}"
              ],
            ),

            // Gender Distribution Pie Chart
            _buildPieChartWithHeading(
              context,
              'Gender Status',
              [
                PieChartSectionData(
                  value: data['maleCount'].toDouble(),
                  color: Colors.lightBlue,
                  title: ' ',
                  radius: 50,
                ),
                PieChartSectionData(
                  value: data['femaleCount'].toDouble(),
                  color: Colors.pink,
                  title: ' ',
                  radius: 50,
                ),
                PieChartSectionData(
                  value: data['otherCount'].toDouble(),
                  color: Colors.yellow,
                  title: ' ',
                  radius: 50,
                ),
              ],
              [
                "Male: ${data['maleCount']}",
                "Female: ${data['femaleCount']}",
                "Other: ${data['otherCount']}"
              ],
            ),

            _buildPieChartWithHeading(
              context,
              'Removed Gender Status',
              [
                PieChartSectionData(
                  value: data['removedMaleCount'].toDouble(),
                  color: Colors.lightBlue,
                  title: ' ',
                  radius: 50,
                ),
                PieChartSectionData(
                  value: data['removedFemaleCount'].toDouble(),
                  color: Colors.pink,
                  title: ' ',
                  radius: 50,
                ),
                PieChartSectionData(
                  value: data['removedOtherCount'].toDouble(),
                  color: Colors.yellow,
                  title: ' ',
                  radius: 50,
                ),
              ],
              [
                "Male: ${data['removedMaleCount']}",
                "Female: ${data['removedFemaleCount']}",
                "Other: ${data['removedOtherCount']}"
              ],
            ),

            // Post Completion Pie Chart
            _buildPieChartWithHeading(
              context,
              'Post Completion Status',
              [
                PieChartSectionData(
                  value: data['completedPosts'].toDouble(),
                  color: Colors.green,
                  title: ' ',
                  radius: 50,
                ),
                PieChartSectionData(
                  value: data['incompletedPosts'].toDouble(),
                  color: Colors.grey,
                  title: ' ',
                  radius: 50,
                ),
              ],
              [
                "Completed: ${data['completedPosts']}",
                "Incompleted: ${data['incompletedPosts']}"
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPieChartWithHeading(
    BuildContext context,
    String heading,
    List<PieChartSectionData> sections,
    List<String> legends,
  ) {
    return Column(
      children: [
        Text(
          heading,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: isSmallScreen ? 150 : 200,
                      height: isSmallScreen ? 150 : 200,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 1,
                          centerSpaceRadius: 0,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: legends
                            .map((legend) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 15,
                                        height: 15,
                                        color: AppColors.getLegendColor(legend),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          legend,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const Divider(color: Colors.grey, thickness: 1, height: 20),
      ],
    );
  }
}
