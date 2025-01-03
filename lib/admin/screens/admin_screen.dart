import 'package:flutter/material.dart';
import 'analysisScreen/analysis_screen.dart';
import 'manageScreen/user_packages_agencies.dart';
import 'messageScreen/sent_message_screen.dart';
import 'reportAndFeedBack/report_&_feedback_nav_screen.dart';
import 'settingsScreen/setting_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  AdminScreenState createState() => AdminScreenState();
}

class AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const SentMessagePage(),
    const UserAndAgencyScreen(),
    const SettingsPage(),
    const TopNavigationScreen(),
    const SettingsPage(),
  ];

  // Function to switch between tabs
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 20,
        selectedIconTheme: const IconThemeData(
          size: 32,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Notify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Manage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
