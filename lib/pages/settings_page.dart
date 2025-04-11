import 'package:chatapp/themes/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (mounted) {
      setState(() {
        fcmToken = token;
      });
    }
  }

  void _showFCMToken() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("FCM Token"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Your FCM Token:"),
                const SizedBox(height: 10),
                SelectableText(fcmToken ?? 'Loading token...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode Toggle
          _buildSettingItem(
            "Dark Mode",
            CupertinoSwitch(
              value:
                  Provider.of<ThemeProvider>(context, listen: true).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).toggleTheme();
              },
            ),
          ),

          // Add FCM Token View option
          _buildSettingItem(
            "View FCM Token",
            IconButton(icon: const Icon(Icons.key), onPressed: _showFCMToken),
          ),

          // Notifications Toggle
          _buildSettingItem(
            "Notifications",
            CupertinoSwitch(
              value: true,
              onChanged: (value) {
                // Handle notifications setting toggle
              },
            ),
          ),

          // Chat Sounds Toggle
          _buildSettingItem(
            "Chat Sounds",
            CupertinoSwitch(
              value: true,
              onChanged: (value) {
                // Handle chat sound setting toggle
              },
            ),
          ),

          // Vibration Toggle
          _buildSettingItem(
            "Vibration",
            CupertinoSwitch(
              value: true,
              onChanged: (value) {
                // Handle vibration setting toggle
              },
            ),
          ),

          // Clear Chat History
          _buildSettingItem(
            "Clear Chat History",
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                // Handle chat history clearing
              },
            ),
          ),

          // Blocked Users
          _buildSettingItem(
            "Blocked Users",
            IconButton(
              icon: const Icon(Icons.block),
              onPressed: () {
                // Navigate to blocked users page or handle blocking users
              },
            ),
          ),

          // Contact
          _buildSettingItem(
            "Contact Us",
            IconButton(
              icon: const Icon(Icons.contact_mail),
              onPressed: () {
                // Navigate to contact page or show contact details
              },
            ),
          ),

          // Privacy Policy
          _buildSettingItem(
            "Privacy Policy",
            IconButton(
              icon: const Icon(Icons.policy),
              onPressed: () {
                // Navigate to privacy policy page or show policy details
              },
            ),
          ),

          // Terms and Conditions
          _buildSettingItem(
            "Terms and Conditions",
            IconButton(
              icon: const Icon(Icons.description),
              onPressed: () {
                // Navigate to terms and conditions page or show terms
              },
            ),
          ),

          // Share App
          _buildSettingItem(
            "Share App",
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Share the app using your sharing method
              },
            ),
          ),

          // Feedback
          _buildSettingItem(
            "Feedback",
            IconButton(
              icon: const Icon(Icons.feedback),
              onPressed: () {
                // Navigate to feedback form or show feedback options
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build each setting item
  Widget _buildSettingItem(String title, Widget trailing) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          trailing,
        ],
      ),
    );
  }
}
