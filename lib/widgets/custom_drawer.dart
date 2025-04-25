import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../screens/settings_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final storageService = Provider.of<StorageService>(context);
    final isLoggedIn = authService.isAuthenticated && !authService.isAnonymous;
    
    return Drawer(
      backgroundColor: AppTheme.cardColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // App logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // App name and user info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dark Notepad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        if (isLoggedIn && authService.currentUser != null)
                          Text(
                            authService.currentUser!.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          const Text(
                            'Not signed in',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.note,
                    size: 20,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${storageService.notes.length} Notes',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Divider(),
            
            // Drawer items
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            
            _buildDrawerItem(
              context,
              icon: Icons.favorite,
              title: 'Favorites',
              onTap: () {
                Navigator.pop(context); // Close drawer
                // TODO: Implement favorites filter
              },
            ),
            
            _buildDrawerItem(
              context,
              icon: Icons.alarm,
              title: 'Reminders',
              onTap: () {
                Navigator.pop(context); // Close drawer
                // TODO: Implement reminders screen
              },
            ),
            
            _buildDrawerItem(
              context,
              icon: Icons.sync,
              title: 'Sync',
              onTap: () {
                Navigator.pop(context); // Close drawer
                // TODO: Implement manual sync
              },
            ),
            
            const Divider(),
            
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            
            if (isLoggedIn)
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                title: 'Sign Out',
                onTap: () async {
                  Navigator.pop(context); // Close drawer
                  
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await authService.signOut();
                  }
                },
              )
            else
              _buildDrawerItem(
                context,
                icon: Icons.login,
                title: 'Sign In',
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  // Navigate to auth screen
                  // TODO: Implement navigation to auth screen
                },
              ),
              
            const Spacer(),
            
            // App version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
