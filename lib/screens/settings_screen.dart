import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/loading_indicator.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _cloudSyncEnabled = true;
  bool _autoSaveEnabled = true;
  bool _notificationsEnabled = true;
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  
  bool _isLoading = true;
  bool _isBiometricAvailable = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricAvailability();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Load settings from storage
      final storageService = Provider.of<StorageService>(context, listen: false);
      final settings = await storageService.getAppSettings();
      
      // Load user settings from auth service if available
      final authService = Provider.of<AuthService>(context, listen: false);
      final userSettings = authService.currentUser?.settings;
      
      setState(() {
        _appLockEnabled = settings[AppConstants.keyAppLockEnabled] ?? false;
        _cloudSyncEnabled = settings[AppConstants.keyCloudSyncEnabled] ?? true;
        _autoSaveEnabled = settings[AppConstants.keyAutoSyncEnabled] ?? true;
        _notificationsEnabled = settings[AppConstants.keyRemindersEnabled] ?? true;
        _fontSize = settings[AppConstants.keyFontSize] ?? 16.0;
        
        // Biometric enabled is only relevant if app lock is enabled
        _biometricEnabled = _appLockEnabled && 
            (userSettings?['biometricEnabled'] ?? false);
        
        // Font family from user settings
        _fontFamily = userSettings?['fontFamily'] ?? 'Roboto';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settings: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkBiometricAvailability() async {
    try {
      final localAuth = LocalAuthentication();
      final isAvailable = await localAuth.canCheckBiometrics && 
                            await localAuth.isDeviceSupported();
      
      setState(() {
        _isBiometricAvailable = isAvailable;
      });
    } catch (e) {
      setState(() {
        _isBiometricAvailable = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Save to shared preferences
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveAppSettings({
        AppConstants.keyAppLockEnabled: _appLockEnabled,
        AppConstants.keyCloudSyncEnabled: _cloudSyncEnabled,
        AppConstants.keyAutoSyncEnabled: _autoSaveEnabled,
        AppConstants.keyRemindersEnabled: _notificationsEnabled,
        AppConstants.keyFontSize: _fontSize,
      });
      
      // Save user specific settings to Firestore
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthenticated && !authService.isAnonymous) {
        final currentUser = authService.currentUser;
        if (currentUser != null) {
          final updatedSettings = Map<String, dynamic>.from(currentUser.settings);
          updatedSettings['biometricEnabled'] = _biometricEnabled;
          updatedSettings['fontFamily'] = _fontFamily;
          
          await authService.updateUserSettings(updatedSettings);
        }
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save settings: $e';
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _setAppLockPin() async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set PIN'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Set a 4-digit PIN to lock your app',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: pinController,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(4),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a PIN';
                      }
                      if (value.length < 4) {
                        return 'PIN must be 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPinController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(4),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your PIN';
                      }
                      if (value != pinController.text) {
                        return 'PINs do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        
                        setState(() {
                          isLoading = true;
                        });
                        
                        final pin = pinController.text;
                        final authService = Provider.of<AuthService>(
                          context,
                          listen: false,
                        );
                        
                        try {
                          final success = await authService.setAppLockPin(pin);
                          
                          if (success) {
                            // Enable app lock
                            this.setState(() {
                              _appLockEnabled = true;
                            });
                            
                            await _saveSettings();
                            
                            if (mounted) {
                              Navigator.of(context).pop();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('App lock enabled'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          } else {
                            throw Exception('Failed to set PIN');
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to set PIN: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Set PIN'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _disableAppLock() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable App Lock'),
        content: const Text('Are you sure you want to disable app lock? Your PIN will be removed.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await authService.disableAppLock();
      
      if (success) {
        setState(() {
          _appLockEnabled = false;
          _biometricEnabled = false;
        });
        
        await _saveSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App lock disabled'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        throw Exception('Failed to disable app lock');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disable app lock: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _exportAllNotes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final notes = storageService.notes;
      
      if (notes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No notes to export'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }
      
      // Generate PDF
      final pdfService = PdfService();
      final pdf = await pdfService.generateMultipleNotesPdf(notes);
      
      // File name
      final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Show export options dialog
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppTheme.cardColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Export ${notes.length} Notes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.print, color: AppTheme.primaryColor),
                  title: const Text('Print'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await pdfService.printPdf(pdf);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to print: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt, color: AppTheme.primaryColor),
                  title: const Text('Save PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final filePath = await pdfService.savePdfToFile(pdf, fileName);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF saved to: $filePath'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save PDF: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: AppTheme.primaryColor),
                  title: const Text('Share'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await pdfService.sharePdf(pdf, fileName);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to share: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export notes: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedIn = authService.isAuthenticated && !authService.isAnonymous;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account section
                _buildSectionHeader('Account'),
                
                if (isLoggedIn)
                  // User profile
                  _buildSettingItem(
                    icon: Icons.account_circle,
                    title: 'Account',
                    subtitle: authService.currentUser?.email ?? '',
                    onTap: () => _showProfileDialog(),
                  )
                else
                  // Sign in/register
                  _buildSettingItem(
                    icon: Icons.login,
                    title: 'Sign In',
                    subtitle: 'Sign in to enable cloud sync',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      );
                    },
                  ),
                
                if (isLoggedIn)
                  // Sign out
                  _buildSettingItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out from your account',
                    onTap: () => _confirmSignOut(),
                  ),
                
                const Divider(),
                
                // Security section
                _buildSectionHeader('Security'),
                
                // App lock
                _buildSettingSwitch(
                  icon: Icons.lock,
                  title: 'App Lock',
                  subtitle: 'Lock the app with a PIN',
                  value: _appLockEnabled,
                  onChanged: (value) {
                    if (value) {
                      _setAppLockPin();
                    } else {
                      _disableAppLock();
                    }
                  },
                ),
                
                // Biometric auth (only if app lock is enabled)
                if (_appLockEnabled && _isBiometricAvailable)
                  _buildSettingSwitch(
                    icon: Icons.fingerprint,
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face ID',
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                
                const Divider(),
                
                // Sync settings
                _buildSectionHeader('Sync'),
                
                // Cloud sync
                _buildSettingSwitch(
                  icon: Icons.cloud,
                  title: 'Cloud Sync',
                  subtitle: 'Sync notes across devices',
                  value: _cloudSyncEnabled,
                  onChanged: isLoggedIn
                      ? (value) {
                          setState(() {
                            _cloudSyncEnabled = value;
                          });
                          _saveSettings();
                        }
                      : null,
                ),
                
                // Auto save
                _buildSettingSwitch(
                  icon: Icons.save,
                  title: 'Auto Save',
                  subtitle: 'Save notes automatically',
                  value: _autoSaveEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoSaveEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
                
                const Divider(),
                
                // Appearance section
                _buildSectionHeader('Appearance'),
                
                // Font size
                _buildSettingItem(
                  icon: Icons.format_size,
                  title: 'Font Size',
                  subtitle: '${_fontSize.round()} px',
                  onTap: () => _showFontSizeDialog(),
                ),
                
                // Font family
                _buildSettingItem(
                  icon: Icons.font_download,
                  title: 'Font Family',
                  subtitle: _fontFamily,
                  onTap: () => _showFontFamilyDialog(),
                ),
                
                const Divider(),
                
                // Notifications section
                _buildSectionHeader('Notifications'),
                
                // Reminders
                _buildSettingSwitch(
                  icon: Icons.notifications,
                  title: 'Reminders',
                  subtitle: 'Enable note reminders',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSettings();
                    
                    // If disabled, cancel all notifications
                    if (!value) {
                      NotificationService().cancelAllReminders();
                    }
                  },
                ),
                
                const Divider(),
                
                // Data management section
                _buildSectionHeader('Data Management'),
                
                // Export all notes as PDF
                _buildSettingItem(
                  icon: Icons.picture_as_pdf,
                  title: 'Export Notes as PDF',
                  subtitle: 'Save all notes to a PDF file',
                  onTap: _exportAllNotes,
                ),
                
                // Delete all notes
                _buildSettingItem(
                  icon: Icons.delete_forever,
                  iconColor: AppTheme.errorColor,
                  title: 'Delete All Notes',
                  subtitle: 'Remove all notes from device',
                  onTap: () => _confirmDeleteAllNotes(),
                ),
                
                const SizedBox(height: 24),
                
                // App info
                Center(
                  child: Text(
                    'Dark Notepad v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Developer info
                Center(
                  child: GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse('https://example.com'));
                    },
                    child: Text(
                      'Developed with ❤️',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildSettingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  void _showProfileDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) return;
    
    final TextEditingController nameController = TextEditingController(
      text: currentUser.displayName ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Email (readonly)
            TextFormField(
              initialValue: currentUser.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              readOnly: true,
              enabled: false,
            ),
            
            const SizedBox(height: 16),
            
            // Display name
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              
              Navigator.of(context).pop();
              
              if (newName != currentUser.displayName) {
                final success = await authService.updateUserProfile(
                  displayName: newName,
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authService.errorMessage ?? 'Failed to update profile'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? Your notes will remain on this device.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  
  void _showFontSizeDialog() {
    double tempFontSize = _fontSize;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Font Size'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sample Text',
                  style: TextStyle(fontSize: tempFontSize),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('12'),
                    const Text('24'),
                  ],
                ),
                Slider(
                  value: tempFontSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  label: tempFontSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      tempFontSize = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  
                  setState(() {
                    _fontSize = tempFontSize;
                  });
                  
                  _saveSettings();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showFontFamilyDialog() {
    String tempFontFamily = _fontFamily;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Family'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.availableFonts.length,
            itemBuilder: (context, index) {
              final font = AppConstants.availableFonts[index];
              final isSelected = font == tempFontFamily;
              
              return ListTile(
                title: Text(
                  font,
                  style: GoogleFonts.getFont(
                    font.toLowerCase().replaceAll(' ', ''),
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check) : null,
                selected: isSelected,
                onTap: () {
                  tempFontFamily = font;
                  Navigator.of(context).pop();
                  
                  setState(() {
                    _fontFamily = tempFontFamily;
                  });
                  
                  _saveSettings();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDeleteAllNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notes'),
        content: const Text(
          'Are you sure you want to delete all notes? This action cannot be undone.',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final storageService = Provider.of<StorageService>(context, listen: false);
                await storageService.clearAllNotes();
                
                // Also cancel all reminders
                await NotificationService().cancelAllReminders();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notes deleted'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete notes: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
