import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/note.dart';
import '../utils/constants.dart';

class NoteService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _userId;
  List<Note> _remoteNotes = [];
  List<Note> _localNotes = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  // Getters
  List<Note> get remoteNotes => _remoteNotes;
  List<Note> get localNotes => _localNotes;
  List<Note> get allNotes {
    final Map<String, Note> mergedNotesMap = {};
    
    // Add local notes to map
    for (final note in _localNotes) {
      mergedNotesMap[note.id] = note;
    }
    
    // Add remote notes to map (will overwrite local ones with same ID)
    for (final note in _remoteNotes) {
      // Only override if remote note is newer
      if (mergedNotesMap.containsKey(note.id)) {
        final localNote = mergedNotesMap[note.id]!;
        if (note.modifiedAt.isAfter(localNote.modifiedAt)) {
          mergedNotesMap[note.id] = note;
        }
      } else {
        mergedNotesMap[note.id] = note;
      }
    }
    
    // Convert map back to list and sort by modified date
    final allNotes = mergedNotesMap.values.toList();
    allNotes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    
    return allNotes;
  }
  
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Set user ID for Firebase operations
  void setUserId(String userId) {
    _userId = userId;
    loadRemoteNotes();
  }

  // Load notes from Firestore
  Future<void> loadRemoteNotes() async {
    if (_userId == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .collection(AppConstants.notesCollection)
          .get();
          
      _remoteNotes = snapshot.docs
          .map((doc) => Note.fromFirestore(doc))
          .toList();
          
      _remoteNotes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      
      _lastSyncTime = DateTime.now();
    } catch (e) {
      _errorMessage = 'Failed to load notes from cloud: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set local notes (from storage service)
  void setLocalNotes(List<Note> notes) {
    _localNotes = List.from(notes);
    notifyListeners();
  }

  // Create or update a note in Firestore
  Future<bool> saveNoteToCloud(Note note) async {
    if (_userId == null) return false;
    
    try {
      final noteRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .collection(AppConstants.notesCollection)
          .doc(note.id);
          
      await noteRef.set(note.toFirestore());
      
      // Update or add note to remote notes list
      final index = _remoteNotes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _remoteNotes[index] = note;
      } else {
        _remoteNotes.add(note);
      }
      
      // Sort notes by modified date
      _remoteNotes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      
      _lastSyncTime = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save note to cloud: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a note from Firestore
  Future<bool> deleteNoteFromCloud(String noteId) async {
    if (_userId == null) return false;
    
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_userId)
          .collection(AppConstants.notesCollection)
          .doc(noteId)
          .delete();
          
      // Remove note from remote notes list
      _remoteNotes.removeWhere((note) => note.id == noteId);
      
      _lastSyncTime = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete note from cloud: $e';
      notifyListeners();
      return false;
    }
  }

  // Synchronize local and remote notes
  Future<bool> syncNotes() async {
    if (_userId == null) return false;
    
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check for internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _errorMessage = 'No internet connection. Sync failed.';
        _isSyncing = false;
        notifyListeners();
        return false;
      }
      
      // Fetch latest remote notes
      await loadRemoteNotes();
      
      // Identify notes to upload, update, or delete
      final notesToUpload = <Note>[];
      final notesToUpdate = <Note>[];
      
      for (final localNote in _localNotes) {
        final remoteNote = _remoteNotes.firstWhere(
          (note) => note.id == localNote.id,
          orElse: () => localNote.copy()..isSynced = false,
        );
        
        if (!remoteNote.isSynced) {
          // New note, upload it
          notesToUpload.add(localNote);
        } else if (localNote.modifiedAt.isAfter(remoteNote.modifiedAt)) {
          // Local note is newer, update remote
          notesToUpdate.add(localNote);
        }
      }
      
      // Upload new notes
      for (final note in notesToUpload) {
        await saveNoteToCloud(note);
      }
      
      // Update modified notes
      for (final note in notesToUpdate) {
        await saveNoteToCloud(note);
      }
      
      _lastSyncTime = DateTime.now();
      return true;
    } catch (e) {
      _errorMessage = 'Sync failed: $e';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Get a note by ID (from both local and remote)
  Note? getNoteById(String id) {
    try {
      // First check local notes
      for (final note in _localNotes) {
        if (note.id == id) return note;
      }
      
      // Then check remote notes
      for (final note in _remoteNotes) {
        if (note.id == id) return note;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search notes by query (in both local and remote)
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return allNotes;
    
    final lowercaseQuery = query.toLowerCase();
    return allNotes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
             note.content.toLowerCase().contains(lowercaseQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Filter notes by tag
  List<Note> getNotesByTag(String tag) {
    return allNotes.where((note) => note.tags.contains(tag)).toList();
  }

  // Get favorite notes
  List<Note> getFavoriteNotes() {
    return allNotes.where((note) => note.isFavorite).toList();
  }

  // Get all unique tags from all notes
  Set<String> getAllTags() {
    final allTags = <String>{};
    for (final note in allNotes) {
      allTags.addAll(note.tags);
    }
    return allTags;
  }
}
