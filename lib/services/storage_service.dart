import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';
import '../utils/constants.dart';

class StorageService extends ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor
  StorageService() {
    loadNotes();
  }

  // Load notes from local storage
  Future<void> loadNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/notes');
      
      // Create directory if it doesn't exist
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
        _notes = [];
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Read all note files
      final noteFiles = await notesDir.list().toList();
      
      // Parse JSON files to Note objects
      _notes = [];
      for (final file in noteFiles) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final noteJson = jsonDecode(content);
            final note = Note.fromJson(noteJson);
            _notes.add(note);
          } catch (e) {
            print('Error parsing note file: ${file.path}');
          }
        }
      }
      
      // Sort notes by modified date (most recent first)
      _notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    } catch (e) {
      _errorMessage = 'Failed to load notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save a note to local storage
  Future<bool> saveNote(Note note) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/notes');
      
      // Create directory if it doesn't exist
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
      }
      
      // Save note to file
      final file = File('${notesDir.path}/${note.id}.json');
      await file.writeAsString(jsonEncode(note.toJson()));
      
      // Update notes list
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = note;
      } else {
        _notes.add(note);
      }
      
      // Sort notes by modified date (most recent first)
      _notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save note: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a note from local storage
  Future<bool> deleteNote(String noteId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/notes/$noteId.json');
      
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from notes list
      _notes.removeWhere((note) => note.id == noteId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete note: $e';
      notifyListeners();
      return false;
    }
  }

  // Get a note by ID
  Note? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get all favorite notes
  List<Note> getFavoriteNotes() {
    return _notes.where((note) => note.isFavorite).toList();
  }

  // Get notes with a specific tag
  List<Note> getNotesByTag(String tag) {
    return _notes.where((note) => note.tags.contains(tag)).toList();
  }

  // Search notes by query
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    
    final lowercaseQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowercaseQuery) ||
             note.content.toLowerCase().contains(lowercaseQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Get all unique tags
  Set<String> getAllTags() {
    final allTags = <String>{};
    for (final note in _notes) {
      allTags.addAll(note.tags);
    }
    return allTags;
  }

  // Import notes from JSON
  Future<bool> importNotes(String jsonString) async {
    try {
      final List<dynamic> notesJson = jsonDecode(jsonString);
      final List<Note> importedNotes = [];
      
      for (final noteJson in notesJson) {
        try {
          final note = Note.fromJson(noteJson);
          importedNotes.add(note);
        } catch (e) {
          print('Error parsing imported note: $e');
        }
      }
      
      // Save all imported notes
      for (final note in importedNotes) {
        await saveNote(note);
      }
      
      await loadNotes(); // Reload all notes
      return true;
    } catch (e) {
      _errorMessage = 'Failed to import notes: $e';
      notifyListeners();
      return false;
    }
  }

  // Export notes to JSON
  Future<String?> exportNotes() async {
    try {
      final jsonList = _notes.map((note) => note.toJson()).toList();
      return jsonEncode(jsonList);
    } catch (e) {
      _errorMessage = 'Failed to export notes: $e';
      notifyListeners();
      return null;
    }
  }

  // Clear all notes (dangerous operation!)
  Future<bool> clearAllNotes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/notes');
      
      if (await notesDir.exists()) {
        await notesDir.delete(recursive: true);
        await notesDir.create();
      }
      
      _notes = [];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to clear notes: $e';
      notifyListeners();
      return false;
    }
  }

  // Get count of unsynchronized notes
  int getUnsyncedNotesCount() {
    return _notes.where((note) => !note.isSynced).length;
  }

  // Mark a note as synchronized
  Future<bool> markNoteAsSynced(String noteId) async {
    try {
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index < 0) return false;
      
      final note = _notes[index];
      note.isSynced = true;
      
      // Save to storage
      await saveNote(note);
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark note as synced: $e';
      notifyListeners();
      return false;
    }
  }

  // Get app settings from SharedPreferences
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{};
      
      settings[AppConstants.keyAppLockEnabled] = 
          prefs.getBool(AppConstants.keyAppLockEnabled) ?? false;
          
      settings[AppConstants.keyAutoSyncEnabled] = 
          prefs.getBool(AppConstants.keyAutoSyncEnabled) ?? true;
          
      settings[AppConstants.keyRemindersEnabled] = 
          prefs.getBool(AppConstants.keyRemindersEnabled) ?? true;
          
      settings[AppConstants.keyCloudSyncEnabled] = 
          prefs.getBool(AppConstants.keyCloudSyncEnabled) ?? true;
          
      settings[AppConstants.keyFontSize] = 
          prefs.getDouble(AppConstants.keyFontSize) ?? 16.0;
          
      return settings;
    } catch (e) {
      _errorMessage = 'Failed to get app settings: $e';
      notifyListeners();
      return {};
    }
  }

  // Save app settings to SharedPreferences
  Future<bool> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        }
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save app settings: $e';
      notifyListeners();
      return false;
    }
  }
}
