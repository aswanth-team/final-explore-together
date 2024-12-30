import 'package:flutter/material.dart';

import 'feedback.dart';
import 'report.dart';

class TopNavigationScreen extends StatelessWidget {
  const TopNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Reports and Feedback
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(text: 'Reports'),
              Tab(text: 'Feedback'),
            ],
          ),
          toolbarHeight: 10,
        ),
        body: TabBarView(
          children: [
            ReportsPage(), // First tab content
            FeedbackPage(), // Second tab content
          ],
        ),
      ),
    );
  }
}
