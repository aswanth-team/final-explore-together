import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/loading.dart';
import '../manageScreen/usersScreen/user_profile_view_screen.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  ReportsPageState createState() => ReportsPageState();
}

class ReportsPageState extends State<ReportsPage> {
  String selectedCategory = "Unchecked";
  List<String> categories = ["Unchecked", "Checked"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 10,
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('isChecked', isEqualTo: selectedCategory == "Checked")
                  .snapshots(),
              builder: (context, snapshot) {
                // Show loading spinner while data is being fetched
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final reports = snapshot.data!.docs;

                // If no reports are found, show a message
                if (reports.isEmpty) {
                  return const Center(child: Text("No reports found."));
                }

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final reportingUserId = report['reportingUser'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('user')
                          .doc(reportingUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return SizedBox();
                        }

                        final userData = userSnapshot.data!;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userData['userimage'] != null
                                ? NetworkImage(userData['userimage'])
                                : AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                          title: Text(userData['username']),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailsPage(
                                  reportId: report.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
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

class ReportDetailsPage extends StatefulWidget {
  final String reportId;

  ReportDetailsPage({required this.reportId});

  @override
  _ReportDetailsPageState createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  bool _isLoading = false;
  bool _isChecked = false; // Track the checked state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report Details"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.reportId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final reportData = snapshot.data!;
          final reportingUserId = reportData['reportingUser'];
          final reportedUserId = reportData['reportedUser'];
          final reportedTime = reportData['reportedTime'].toDate();
          final formattedReportedTime =
              DateFormat.yMMMd().add_jm().format(reportedTime);

          // Set initial checked state from Firestore
          if (!_isChecked && reportData['isChecked'] != null) {
            _isChecked = reportData['isChecked'];
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Reported Time:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  formattedReportedTime,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  reportData['description'],
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            FutureBuilder<List<DocumentSnapshot>>(
                              future: Future.wait([
                                FirebaseFirestore.instance
                                    .collection('user')
                                    .doc(reportingUserId)
                                    .get(),
                                FirebaseFirestore.instance
                                    .collection('user')
                                    .doc(reportedUserId)
                                    .get(),
                              ]),
                              builder: (context, usersSnapshot) {
                                if (!usersSnapshot.hasData) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }

                                final reportingUser = usersSnapshot.data![0];
                                final reportedUser = usersSnapshot.data![1];

                                return GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OtherProfilePageForAdmin(
                                                    userId: reportingUserId),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                reportingUser['userimage']),
                                          ),
                                          SizedBox(height: 8),
                                          Text(reportingUser['username']),
                                          SizedBox(height: 4),
                                          Text(
                                            "Reporting",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OtherProfilePageForAdmin(
                                                    userId: reportedUserId),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                reportedUser['userimage']),
                                          ),
                                          SizedBox(height: 8),
                                          Text(reportedUser['username']),
                                          SizedBox(height: 4),
                                          Text(
                                            "Reported",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5), // Overlay effect
                    child: Center(child: LoadingAnimationOverLay()),
                  ),
                ),
              // Floating action button at the center bottom
              Positioned(
                bottom: 16, // Distance from the bottom
                left: MediaQuery.of(context).size.width / 2 -
                    30, // Center horizontally
                child: FloatingActionButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });

                          await FirebaseFirestore.instance
                              .collection('reports')
                              .doc(widget.reportId)
                              .update({'isChecked': !_isChecked});

                          setState(() {
                            _isChecked = !_isChecked; // Toggle the state
                            _isLoading = false;
                          });
                        },
                  backgroundColor: _isChecked ? Colors.red : Colors.blue,
                  child: Icon(
                    _isChecked ? Icons.close : Icons.check,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
