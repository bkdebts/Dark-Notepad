import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
          children: [
          DrawerHeader(
                    decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
                      ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Icon(Icons.note, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text('Flutter Note Pro', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
              onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.lightbulb),
            title: Text('Quick Notes'),
              onTap: () {
              Navigator.pop(context);
              // Optionally scroll to quick notes section
              },
            ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
              onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
              onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Flutter Note Pro',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.note),
                children: [Text('A simple, local note-taking app.')],
                );
              },
            ),
        ],
      ),
    );
  }
}
