import 'package:flutter/material.dart';

import 'packages/package_screen.dart';
import 'tripAssistScreen/travel_guide_screen.dart';

class PackageAndTripAssistScreen extends StatelessWidget {
  const PackageAndTripAssistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Packages'),
              Tab(text: 'Trip Assists'),
            ],
          ),
          toolbarHeight: 10,
        ),
        body: const TabBarView(
          children: [
            PackagesScreen(),
            TravelAgencyPage(),
          ],
        ),
      ),
    );
  }
}
