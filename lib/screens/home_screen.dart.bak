import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/note_card.dart';
import '../widgets/loading_indicator.dart';
import 'note_editor_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Note> _displayedNotes = [];
  bool _isSearchActive = false;
  bool _isSyncing = false;
  bool _onlyShowFavorites = false;
  String? _activeTag;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  
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
    
    // Start animations after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAnimationController.forward();
      _initializeData();
    });
    
    // Listen for search changes
    _searchController.addListener(_onSearchTextChanged);
    
    // Add app lock event listener
    WidgetsBinding.instance.addObserver(AppLifecycleObserver(
      onResume: _checkAppLock,
      onPause: _onAppPause,
    ));
  }
  
  Future<void> _initializeData() async {
    // Set the user ID in the NoteService
    final authService = Provider.of<AuthService>(context, listen: false);
    final noteService = Provider.of<NoteService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    if (authService.currentUser != null) {
      noteService.setUserId(authService.currentUser!.uid);
    }
    
    // Load notes from local storage
    await storageService.loadNotes();
    
    // Set local notes in the note service
    noteService.setLocalNotes(storageService.notes);
    
    // Update displayed notes
    _updateDisplayedNotes();
    
    // Try to sync notes if connected to the internet
    _tryAutoSync();
  }
  
  void _updateDisplayedNotes() {
    final noteService = Provider.of<NoteService>(context, listen: false);
    List<Note> notes = noteService.allNotes;
    
    // Apply filters
    if (_onlyShowFavorites) {
      notes = noteService.getFavoriteNotes();
    } else if (_activeTag != null) {
      notes = noteService.getNotesByTag(_activeTag!);
    }
    
    // Apply search
    if (_isSearchActive && _searchController.text.isNotEmpty) {
      notes = noteService.searchNotes(_searchController.text);
    }
    
    setState(() {
      _displayedNotes = notes;
    });
  }
  
  Future<void> _tryAutoSync() async {
    // Check if auto sync is enabled
    final prefs = await Provider.of<StorageService>(context, listen: false).getAppSettings();
    final autoSyncEnabled = prefs[AppConstants.keyAutoSyncEnabled] ?? true;
    
    if (!autoSyncEnabled) return;
    
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;
    
    // Sync notes
    await _syncNotes();
  }
  
  Future<void> _syncNotes() async {
    final noteService = Provider.of<NoteService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      // Sync notes with cloud
      final success = await noteService.syncNotes();
      
      if (success) {
        // Mark all notes as synced in local storage
        for (final note in storageService.notes) {
          await storageService.markNoteAsSynced(note.id);
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.successCloudSync),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
      
      // Update displayed notes
      _updateDisplayedNotes();
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
  
  void _onSearchTextChanged() {
    _updateDisplayedNotes();
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _updateDisplayedNotes();
      }
    });
  }
  
  void _toggleFavorites() {
    setState(() {
      _onlyShowFavorites = !_onlyShowFavorites;
      _activeTag = null;
      _updateDisplayedNotes();
    });
  }
  
  void _selectTag(String tag) {
    setState(() {
      if (_activeTag == tag) {
        _activeTag = null;
      } else {
        _activeTag = tag;
      }
      _onlyShowFavorites = false;
      _updateDisplayedNotes();
    });
  }
  
  void _addNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditorScreen(),
      ),
    ).then((value) {
      // Refresh notes list when returning
      _updateDisplayedNotes();
    });
  }
  
  void _editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    ).then((value) {
      // Refresh notes list when returning
      _updateDisplayedNotes();
    });
  }
  
  Future<void> _deleteNote(Note note) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final noteService = Provider.of<NoteService>(context, listen: false);
    final notificationService = NotificationService();
    
    // Delete note locally
    await storageService.deleteNote(note.id);
    
    // Delete from cloud if user is authenticated
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated && !authService.isAnonymous) {
      await noteService.deleteNoteFromCloud(note.id);
    }
    
    // Cancel any reminders for this note
    if (note.reminderTime != null) {
      await notificationService.cancelReminder(note.id);
    }
    
    // Update displayed notes
    _updateDisplayedNotes();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Restore the note
              await storageService.saveNote(note);
              
              // Restore to cloud if authenticated
              if (authService.isAuthenticated && !authService.isAnonymous) {
                await noteService.saveNoteToCloud(note);
              }
              
              // Restore reminder if needed
              if (note.reminderTime != null) {
                final reminderTime = DateTime.parse(note.reminderTime!);
                if (reminderTime.isAfter(DateTime.now())) {
                  await notificationService.scheduleReminder(
                    note.id,
                    note.title.isEmpty ? 'Reminder' : note.title,
                    note.getContentPreview(),
                    reminderTime,
                  );
                }
              }
              
              _updateDisplayedNotes();
            },
          ),
        ),
      );
    }
  }
  
  void _toggleNoteFavorite(Note note) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final noteService = Provider.of<NoteService>(context, listen: false);
    
    // Toggle favorite status
    final updatedNote = note.copy();
    updatedNote.update(isFavorite: !note.isFavorite);
    
    // Save locally
    await storageService.saveNote(updatedNote);
    
    // Save to cloud if authenticated
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated && !authService.isAnonymous) {
      await noteService.saveNoteToCloud(updatedNote);
    }
    
    // Update displayed notes
    _updateDisplayedNotes();
  }
  
  Future<void> _checkAppLock() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final prefs = await Provider.of<StorageService>(context, listen: false).getAppSettings();
    final appLockEnabled = prefs[AppConstants.keyAppLockEnabled] ?? false;
    
    if (appLockEnabled) {
      // Lock the app
      authService.lockApp();
      
      // Navigate to lock screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LockScreen()),
      );
    }
  }
  
  void _onAppPause() {
    // This method is called when the app is sent to the background
    // We'll use it to check app lock when the app is resumed
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);
    final storageService = Provider.of<StorageService>(context);
    final isLoading = noteService.isLoading || storageService.isLoading;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: _isSearchActive ? null : 'Notes',
        actions: [
          // Search button or search field
          if (_isSearchActive)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search notes...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                  autofocus: true,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              tooltip: 'Search',
            ),
            
          // Favorites filter
          IconButton(
            icon: Icon(
              _onlyShowFavorites ? Icons.favorite : Icons.favorite_border,
              color: _onlyShowFavorites ? AppTheme.primaryColor : null,
            ),
            onPressed: _toggleFavorites,
            tooltip: 'Favorites',
          ),
          
          // Sync button
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncNotes,
            tooltip: 'Sync',
          ),
        ],
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Tags horizontal list
          if (_activeTag != null || noteService.getAllTags().isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...noteService.getAllTags().map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text('#$tag'),
                      selected: _activeTag == tag,
                      onSelected: (_) => _selectTag(tag),
                      backgroundColor: AppTheme.cardColor,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _activeTag == tag
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                      ),
                      checkmarkColor: AppTheme.primaryColor,
                    ),
                  )),
                ],
              ),
            ),
            
          // Notes list
          Expanded(
            child: isLoading
                ? const Center(child: LoadingIndicator())
                : _displayedNotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _syncNotes,
                        color: AppTheme.primaryColor,
                        backgroundColor: AppTheme.cardColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _displayedNotes.length,
                          itemBuilder: (context, index) {
                            final note = _displayedNotes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: NoteCard(
                                note: note,
                                onTap: () => _editNote(note),
                                onDelete: () => _deleteNote(note),
                                onToggleFavorite: () => _toggleNoteFavorite(note),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: _addNewNote,
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
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
                : _onlyShowFavorites
                    ? 'No favorite notes yet'
                    : _activeTag != null
                        ? 'No notes with tag #$_activeTag'
                        : 'No notes yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearchActive
                ? 'Try a different search term'
                : 'Tap + to create a new note',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AppLifecycleObserver with WidgetsBindingObserver {
  final Function onResume;
  final Function onPause;
  
  AppLifecycleObserver({
    required this.onResume,
    required this.onPause,
  });
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    } else if (state == AppLifecycleState.paused) {
      onPause();
    }
  }
}
