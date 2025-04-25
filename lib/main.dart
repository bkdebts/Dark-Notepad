import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'utils/theme.dart';

// Demo version with simplified functionality
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Force dark mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Notepad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const DemoSplashScreen(),
    );
  }
}

// Simplified splash screen for demo
class DemoSplashScreen extends StatefulWidget {
  const DemoSplashScreen({Key? key}) : super(key: key);

  @override
  State<DemoSplashScreen> createState() => _DemoSplashScreenState();
}

class _DemoSplashScreenState extends State<DemoSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    // Start animations
    _animationController.forward();
    
    // Navigate to home screen after delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DemoHomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App name
                    Text(
                      'Dark Notepad',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // App tagline
                    Text(
                      'Take notes. Anywhere. Anytime.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Demo note class for simplicity
class DemoNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isFavorite;
  final List<String> tags;
  final String color;

  DemoNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.isFavorite = false,
    this.tags = const [],
    this.color = '#121212',
  });
  
  String getContentPreview({int maxLength = 100}) {
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }
}

// Simplified home screen for demo
class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({Key? key}) : super(key: key);

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  
  final _searchController = TextEditingController();
  bool _isSearchActive = false;
  
  // Demo data
  final List<DemoNote> _demoNotes = [
    DemoNote(
      id: '1',
      title: 'Welcome to Dark Notepad',
      content: 'This is a beautiful cross-platform notepad application built with Flutter/Dart. It features cloud sync, PDF export, and a stunning dark mode UI.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      modifiedAt: DateTime.now().subtract(const Duration(hours: 12)),
      tags: ['welcome', 'info'],
      isFavorite: true,
    ),
    DemoNote(
      id: '2',
      title: 'Project Ideas',
      content: '1. Mobile app for task tracking\n2. Portfolio website\n3. E-commerce dashboard\n4. Recipe manager\n5. Budget planner',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      modifiedAt: DateTime.now().subtract(const Duration(days: 1)),
      tags: ['projects', 'ideas'],
    ),
    DemoNote(
      id: '3',
      title: 'Meeting Notes',
      content: 'Team meeting 04/20:\n- Discussed project timeline\n- Assigned tasks to team members\n- Set next meeting for 04/27\n- Review design mockups',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      modifiedAt: DateTime.now().subtract(const Duration(days: 4)),
      tags: ['work', 'meeting'],
    ),
    DemoNote(
      id: '4',
      title: 'Shopping List',
      content: '- Milk\n- Eggs\n- Bread\n- Cheese\n- Apples\n- Coffee\n- Pasta\n- Tomato sauce',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      modifiedAt: DateTime.now().subtract(const Duration(days: 3)),
      tags: ['shopping', 'personal'],
    ),
    DemoNote(
      id: '5',
      title: 'Flutter Tips',
      content: '1. Use const constructors when possible\n2. Prefer StatelessWidget over StatefulWidget\n3. Use AnimatedBuilder for complex animations\n4. Leverage Provider for state management\n5. Use MediaQuery for responsive design',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      modifiedAt: DateTime.now().subtract(const Duration(days: 6)),
      tags: ['flutter', 'coding'],
      isFavorite: true,
      color: '#845EF7',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _fabAnimationController.forward();
    
    // Listen for search changes
    _searchController.addListener(_onSearchTextChanged);
  }
  
  void _onSearchTextChanged() {
    setState(() {});
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
      }
    });
  }
  
  List<DemoNote> get _filteredNotes {
    if (!_isSearchActive || _searchController.text.isEmpty) {
      return _demoNotes;
    }
    
    final query = _searchController.text.toLowerCase();
    return _demoNotes.where((note) {
      return note.title.toLowerCase().contains(query) ||
             note.content.toLowerCase().contains(query) ||
             note.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: _isSearchActive
          ? TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search notes...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              style: const TextStyle(color: AppTheme.textPrimaryColor),
              autofocus: true,
            )
          : const Text('Notes'),
        actions: [
          // Search button
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearchActive ? 'Clear search' : 'Search',
          ),
          
          // Sort button
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
            tooltip: 'Sort',
          ),
        ],
      ),
      drawer: Drawer(
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
                    
                    // App name
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Notepad',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Demo Version',
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
              
              const SizedBox(height: 8),
              
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
                      '${_demoNotes.length} Notes',
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
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Favorites'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('Tags'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              
              const Spacer(),
              
              // App version
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Demo Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _filteredNotes.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.note_outlined,
                  size: 80,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _isSearchActive
                      ? 'No results found'
                      : 'No notes yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (!_isSearchActive)
                  Text(
                    'Tap the + button to create a note',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredNotes.length,
            itemBuilder: (context, index) {
              final note = _filteredNotes[index];
              return _buildNoteCard(note);
            },
          ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This is a demo view. Note creation is not available.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
  
  Widget _buildNoteCard(DemoNote note) {
    // Parse note color
    final Color noteColor = note.color == '#121212'
        ? AppTheme.cardColor
        : Color(int.parse(note.color.substring(1), radix: 16) + 0xFF000000);
    
    // Format date
    final String formattedDate = DateFormat('MMM dd, yyyy').format(note.modifiedAt);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: noteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a demo view. Note editing is not available.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note header
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Expanded(
                        child: Text(
                          note.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Favorite button
                      IconButton(
                        icon: Icon(
                          note.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: note.isFavorite
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                
                // Note preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    note.getContentPreview(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Tags
                if (note.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: note.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Card footer (date and actions)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 8,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      // Date
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      
                      const Spacer(),
                      
                      // Delete button
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.textSecondaryColor,
                        ),
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
