import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Appearance'),
                _buildSettingItem(
                  icon: Icons.format_size,
                  title: 'Font Size',
                  subtitle: '${_fontSize.round()} px',
                  onTap: () => _showFontSizeDialog(),
                ),
                _buildSettingItem(
                  icon: Icons.font_download,
                  title: 'Font Family',
                  subtitle: _fontFamily,
                  onTap: () => _showFontFamilyDialog(),
                ),
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
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  void _showFontSizeDialog() {
    double tempFontSize = _fontSize;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                },
                child: const Text('Apply'),
              ),
            ],
      ),
    );
  }
  
  void _showFontFamilyDialog() {
    final List<String> fonts = [
      'Roboto',
      'Poppins',
      'Lato',
      'Montserrat',
      'Open Sans',
      'Oswald',
      'Raleway',
    ];
    String tempFontFamily = _fontFamily;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Family'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final font = fonts[index];
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
}
