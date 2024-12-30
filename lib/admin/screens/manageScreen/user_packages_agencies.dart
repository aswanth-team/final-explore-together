import 'package:flutter/material.dart';
import 'packages/admin_package_screen.dart';
import 'tripAssistScreen/agency_screen.dart';
import 'usersScreen/view_users_screen.dart';

class UserAndAgencyScreen extends StatelessWidget {
  const UserAndAgencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Packages'),
              Tab(text: 'Trip Assists'),
            ],
          ),
          toolbarHeight: 10,
        ),
        body: const TabBarView(
          children: [
            UserSearchPage(),
            AdminPackagesScreen(),
            TravelAgencyPage(),
          ],
        ),
      ),
    );
  }
}
