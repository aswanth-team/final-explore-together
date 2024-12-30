import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../services/user/firebase_user_auth.dart';
import '../../../../../utils/confirm_dialogue.dart';
import '../../edit_profile_screen.dart';

class AccountManagementPage extends StatelessWidget {
  AccountManagementPage({super.key});

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final UserAuthServices _authServices = UserAuthServices();

  void _showConfirmationDialog(BuildContext context) {
    showConfirmationDialog(
      context: context,
      title: 'Change Password',
      message: 'Are you sure you want to change password?',
      cancelButtonText: 'Cancel',
      confirmButtonText: 'Yes',
      onConfirm: () async {
        try {
          final userEmail = await _authServices.getUserEmailById(currentUserId);

          if (userEmail != null) {
            await FirebaseAuth.instance
                .sendPasswordResetEmail(email: userEmail);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Reset link sent. Check your email to reset your password.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Could not retrieve user email.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      titleIcon: const Icon(Icons.lock_reset, color: Colors.red),
      titleColor: Colors.redAccent,
      messageColor: Colors.black87,
      cancelButtonColor: Colors.blue,
      confirmButtonColor: Colors.red,
      backgroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Management')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(uuid: currentUserId)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
