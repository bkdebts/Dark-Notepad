import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import 'note_editor_screen.dart';
import 'package:flutter_note_pro/screens/home_screen.dart';
import 'time_capsule_editor_screen.dart';
import 'time_capsule_view_screen.dart';
import 'expenses_diary_screen.dart';
import 'slam_book_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  List<Note> _quickNotes = [];
  List<Note> _deletedNotes = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _preloadQuickNotes()
      .then((_) => _addSlamBookQuickNote())
      .then((_) => _loadNotes());
  }
  
  Future<void> _preloadQuickNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final quickNotesKey = 'quick_notes_preloaded';
    if (!(prefs.getBool(quickNotesKey) ?? false)) {
      final quickNotes = [
        Note(title: 'Grocery', content: '''Grocery List

Rice
  Weight: 5 kg
  Price: ₹300

Wheat flour (Atta)
  Weight: 5 kg
  Price: ₹250

Lentils (Dal)
  Weight: 1 kg
  Price: ₹150

Cooking oil (Mustard or Sunflower)
  Weight: 1 liter
  Price: ₹180

Sugar
  Weight: 1 kg
  Price: ₹45

Salt
  Weight: 1 kg
  Price: ₹20

Spices (Turmeric, Red chili powder, etc.)
  Weight: 100 g each (4 varieties)
  Price: ₹100

Tea or Coffee
  Weight: 250 g
  Price: ₹200

Milk
  Weight: 1 liter
  Price: ₹60

Yogurt (Dahi)
  Weight: 1 kg
  Price: ₹80

Vegetables (Potatoes, Onions, Tomatoes)
  Weight: 1 kg each (3 varieties)
  Price: ₹120

Fruits (Bananas, Apples, Oranges)
  Weight: 1 kg each (3 varieties)
  Price: ₹150

Pulses (Chana, Moong)
  Weight: 1 kg each (2 varieties)
  Price: ₹200

Bread
  Weight: 400 g
  Price: ₹40

Eggs
  Pack: 6 eggs
  Price: ₹50

Chicken or Fish
  Weight: 1 kg
  Price: ₹300

Snacks (Namkeen or Chips)
  Weight: 200 g
  Price: ₹60

Pickles
  Weight: 500 g
  Price: ₹80

Cereals or Oats
  Weight: 500 g
  Price: ₹150

Soap or Detergent
  Weight: 1 kg
  Price: ₹200
''', isSynced: false),
        Note(title: 'To-Do', content: '''Family
  - Call Mom
  - Schedule family dinner

Work/Projects
  - Finish Project
  - Attend team meeting
  - Submit report

Personal Development
  - Read Book
  - Take an online course

Health & Fitness
  - Go for a run
  - Meal prep for the week
  - Schedule doctor's appointment

Household Tasks
  - Clean the house
  - Grocery shopping
  - Pay bills

Social
  - Catch up with friends
  - Plan weekend outing

Hobbies
  - Practice a musical instrument
  - Work on craft project

Finance
  - Review budget
  - Save for vacation

Travel
  - Plan next trip
  - Book accommodations

Self-Care
  - Meditate
  - Take a relaxing bath
''', isSynced: false),
        Note(title: 'Ideas', content: '''App Idea
  - A meal planning app with grocery list integration.

Business Plan
  - Start an online store for eco-friendly products.

Blog Topic
  - Write about sustainable living tips.

Side Project
  - Develop a personal finance tracking tool.

Event Planning
  - Organize a community clean-up day.

Podcast Idea
  - Host discussions on mental health and wellness.

YouTube Channel Concept
  - Create tutorials for DIY home improvement projects.

Fitness Program
  - Design a 30-day workout challenge for beginners.

Social Media Campaign
  - Raise awareness about local charities.

Freelance Service
  - Offer graphic design services for small businesses.
''', isSynced: false),
        Note(title: 'Workout', content: '''Push-ups
  - Sets and reps
  - Variations (e.g., incline, decline)

Sit-ups
  - Sets and reps
  - Form tips

Jogging
  - Distance goals
  - Pace tracking

Squats
  - Sets and reps
  - Variations (e.g., sumo, jump squats)

Lunges
  - Sets and reps
  - Forward vs. reverse lunges

Plank
  - Duration goals
  - Variations (e.g., side plank)

Burpees
  - Sets and reps
  - Timing for high-intensity intervals

Mountain Climbers
  - Duration or timed intervals
  - Form tips

Jump Rope
  - Duration goals
  - Tricks to try

Yoga
  - Poses to focus on
  - Duration of sessions
''', isSynced: false),
        Note(title: 'Travel', content: '''Book Tickets
  - Flights and accommodations

Pack Bags
  - Essentials checklist

Create Itinerary
  - Daily activities and sights

Research Destinations
  - Local attractions and restaurants

Arrange Transportation
  - Car rentals or public transport options

Check Travel Documents
  - Passport, visa, and insurance

Plan Budget
  - Daily expenses and activities

Notify Bank
  - Inform about travel plans for card usage

Download Travel Apps
  - Maps, translation, and local guides

Make Packing List
  - Clothing, toiletries, and gear
''', isSynced: false),
        Note(title: 'Time Capsule', content: 'Create a memory with photo/video/text, set a release date, and surprise your future self or a friend!', isSynced: false),
        Note(title: 'Expenses', content: 'Track your expenses easily!', isSynced: false),
      ];
      final notesJson = quickNotes.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList('quick_notes', notesJson);
      await prefs.setBool(quickNotesKey, true);
    }
  }
  
  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('notes') ?? [];
      final quickNotesJson = prefs.getStringList('quick_notes') ?? [];
      final deletedNotesJson = prefs.getStringList('deleted_notes') ?? [];
      
      setState(() {
        _notes = notesJson
            .map((json) => Note.fromJson(jsonDecode(json)))
            .toList();
        _quickNotes = quickNotesJson
            .map((json) => Note.fromJson(jsonDecode(json)))
            .toList();
        _deletedNotes = deletedNotesJson
            .map((json) => Note.fromJson(jsonDecode(json)))
            .toList();
            
        // Sort notes by modified date (most recent first)
        _notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        _isLoading = false;
      });
    } catch (e) {
        setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notes: $e';
      });
    }
  }
  
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = _notes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      final deletedNotesJson = _deletedNotes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      
      await prefs.setStringList('notes', notesJson);
      await prefs.setStringList('deleted_notes', deletedNotesJson);
    } catch (e) {
    setState(() {
        _errorMessage = 'Failed to save notes: $e';
      });
    }
  }
  
  void _saveNote(Note note, {bool showSnackbar = true}) {
    final now = DateTime.now();
    String title = note.title.trim();
    if (title.isEmpty) {
      // Use template name with timestamp if title is empty
      title = 'Note (${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})';
    }
    final updatedNote = note.copyWith(
      title: title,
      modifiedAt: now,
    );
    setState(() {
      final index = _notes.indexWhere((n) => n.id == updatedNote.id);
      if (index >= 0) {
        _notes[index] = updatedNote;
      } else {
        _notes.add(updatedNote);
      }
      _notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    });
    _saveNotes();
    Navigator.pop(context);
    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _deleteNote(String id) {
    setState(() {
      final note = _notes.firstWhere((note) => note.id == id, orElse: () => Note());
      if (note.id != null) {
        _deletedNotes.add(note);
        _notes.removeWhere((note) => note.id == id);
      }
    });
    
    _saveNotes();
    
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note moved to Bin'),
        backgroundColor: Colors.orange,
        ),
      );
    }
  
  Note _duplicateQuickNote(Note note) {
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final newTitle = note.title.isEmpty ? 'Note ($timestamp)' : '${note.title} ($timestamp)';
    final newNote = note.copyWith(
      id: null,
      title: newTitle,
      createdAt: now,
      modifiedAt: now,
    );
    _saveNote(newNote, showSnackbar: false);
    return newNote;
  }
  
  void _shareNote(Note note) {
    // Prepare content for sharing
    final String shareContent = '${note.title}\n\n${note.content}';
    
    // Share the note content
    Share.share(shareContent, subject: note.title);
  }
  
  // Function to manually add Slam Book
  Future<void> _addSlamBookQuickNote() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing quick notes
    final quickNotesJson = prefs.getStringList('quick_notes') ?? [];
    final quickNotes = quickNotesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .toList();
    
    // Add Slam Book if not already there
    if (!quickNotes.any((note) => note.title == 'Slam Book')) {
      quickNotes.add(
        Note(title: 'Slam Book', content: 'Tap to create a Slam Book for a friend!', isSynced: false)
      );
      
      // Save updated list
      final updatedJson = quickNotes.map((note) => jsonEncode(note.toJson())).toList();
      await prefs.setStringList('quick_notes', updatedJson);
      print("Slam Book added successfully!");
    } else {
      print("Slam Book already exists");
    }
  }

  void _restoreNote(String id) {
    setState(() {
      final note = _deletedNotes.firstWhere((note) => note.id == id, orElse: () => Note());
      if (note.id != null) {
        _notes.add(note);
        _deletedNotes.removeWhere((note) => note.id == id);
      }
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note restored'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _permanentlyDeleteNote(String id) {
    setState(() {
      _deletedNotes.removeWhere((note) => note.id == id);
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note permanently deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDeletedNotesModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Deleted Notes', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (_deletedNotes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No deleted notes.'),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _deletedNotes.length,
                  itemBuilder: (context, index) {
                    final note = _deletedNotes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(note.title.isEmpty ? 'Untitled' : note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_from_trash, color: Colors.green),
                              onPressed: () => _restoreNote(note.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _permanentlyDeleteNote(note.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 64) / 4; // 16px padding each side, 4 cards
    final cardHeight = cardWidth * 1.1;
    final filteredNotes = _notes.where((note) {
      final query = _searchQuery.toLowerCase();
      return note.title.toLowerCase().contains(query) ||
        note.content.toLowerCase().contains(query) ||
        (note.createdAt.toString().contains(query)) ||
        (note.modifiedAt.toString().contains(query));
    }).toList();
    filteredNotes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Bin',
            onPressed: _showDeletedNotesModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
                // Search Box
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search notes by name or date...',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: Colors.purpleAccent),
                      filled: true,
                      fillColor: Colors.black87,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.purpleAccent)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.purpleAccent)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                ),
                // Quick Notes Heading
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text('Quick Notes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.purple)),
                ],
              ),
            ),
                // Quick Notes Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1/1.1,
                    ),
                    itemCount: _quickNotes.length,
                          itemBuilder: (context, index) {
                      final note = _quickNotes[index];
                      return GestureDetector(
                        onTap: () {
                          if (note.title == 'Time Capsule') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimeCapsuleEditorScreen(
                                  onSave: (capsule) {
                                    setState(() {
                                      _notes.add(Note(
                                        title: capsule.name,
                                        content: capsule.text,
                                        createdAt: capsule.createdAt,
                                        modifiedAt: capsule.createdAt,
                                        isSynced: false,
                                        releaseAt: capsule.releaseAt,
                                        imageBytes: capsule.imageBytes,
                                        videoBytes: capsule.videoBytes,
                                        isLocked: true,
                                      ));
                                    });
                                    _saveNotes();
                                  },
                                ),
                              ),
                            );
                          } else if (note.title == 'Expenses') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpensesDiaryScreen(),
                              ),
                            );
                          } else if (note.title == 'Slam Book') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SlamBookScreen(
                                  onSave: (slamBookNote) {
                                    setState(() {
                                      _notes.add(slamBookNote);
                                    });
                                    _saveNotes();
                                  },
                                ),
                              ),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text('Use This Note'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        final newNote = _duplicateQuickNote(note);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NoteEditorScreen(
                                              note: newNote,
                                              onSave: _saveNote,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.visibility),
                                      title: const Text('View'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NoteEditorScreen(
                                note: note,
                                              onSave: _saveNote,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.share),
                                      title: const Text('Share'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _shareNote(note);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        child: _quickNoteCard(note, context, cardWidth, cardHeight),
                            );
                          },
                        ),
                      ),
                // User Notes Grid
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? (filteredNotes.isEmpty
                          ? const Center(child: Text('No matching notes found.'))
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1/1.1,
                                ),
                                itemCount: filteredNotes.length,
                                itemBuilder: (context, index) {
                                  final note = filteredNotes[index];
                                  Widget titleWidget;
                                  if (_searchQuery.isNotEmpty) {
                                    final query = _searchQuery.toLowerCase();
                                    final title = note.title.isEmpty ? 'Untitled' : note.title;
                                    final matchIndex = title.toLowerCase().indexOf(query);
                                    if (matchIndex >= 0) {
                                      titleWidget = RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
                                          children: [
                                            TextSpan(text: title.substring(0, matchIndex)),
                                            TextSpan(text: title.substring(matchIndex, matchIndex + query.length), style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.red)),
                                            TextSpan(text: title.substring(matchIndex + query.length)),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    } else {
                                      titleWidget = Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13));
                                    }
                                  } else {
                                    titleWidget = Text(note.title.isEmpty ? 'Untitled' : note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13));
                                  }
                                  if (note.releaseAt != null) {
                                    final now = DateTime.now();
                                    final isLocked = note.isLocked && (note.releaseAt!.isAfter(now));
                                    return Card(
                                      color: isLocked ? Colors.grey[300] : Colors.deepPurple[100],
                                      margin: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: ListTile(
                                        leading: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.deepPurple),
                                        title: titleWidget,
                                        subtitle: Text(isLocked ? 'Opens at: \\${note.releaseAt}' : note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11)),
                                        trailing: isLocked ? null : IconButton(
                                          icon: const Icon(Icons.share),
                                          onPressed: () => _shareNote(note),
                                        ),
                                        onTap: isLocked ? null : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TimeCapsuleViewScreen(note: note),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: ListTile(
                                      title: titleWidget,
                                      subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () => _shareNote(note),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NoteEditorScreen(
                                              note: note,
                                              onSave: _saveNote,
                                              onDelete: (n) => _deleteNote(n.id),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ))
                      : (filteredNotes.isEmpty
                          ? const Center(child: Text('No notes yet. Create your first note!', style: TextStyle(fontSize: 16)))
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1/1.1,
                                ),
                                itemCount: filteredNotes.length,
                                itemBuilder: (context, index) {
                                  final note = filteredNotes[index];
                                  if (note.releaseAt != null) {
                                    final now = DateTime.now();
                                    final isLocked = note.isLocked && (note.releaseAt!.isAfter(now));
                                    return Card(
                                      color: isLocked ? Colors.grey[300] : Colors.deepPurple[100],
                                      margin: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: ListTile(
                                        leading: Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.deepPurple),
                                        title: Text(note.title.isEmpty ? 'Untitled' : note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                                        subtitle: Text(isLocked ? 'Opens at: \\${note.releaseAt}' : note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11)),
                                        trailing: isLocked ? null : IconButton(
                                          icon: const Icon(Icons.share),
                                          onPressed: () => _shareNote(note),
                                        ),
                                        onTap: isLocked ? null : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TimeCapsuleViewScreen(note: note),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: ListTile(
                                      title: Text(note.title.isEmpty ? 'Untitled' : note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                                      subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () => _shareNote(note),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NoteEditorScreen(
                                              note: note,
                                              onSave: _saveNote,
                                              onDelete: (n) => _deleteNote(n.id),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                onSave: _saveNote,
              ),
            ),
          );
        },
          child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _quickNoteCard(Note note, BuildContext context, double width, double height) {
    String? bgAsset;
    if (note.title == 'Grocery') bgAsset = 'assets/icons/grocery-bg.png';
    if (note.title == 'Travel') bgAsset = 'assets/icons/travel-bg.png';
    if (note.title == 'To-Do') bgAsset = 'assets/icons/to-do-bg.png';
    if (note.title == 'Workout') bgAsset = 'assets/icons/workout-bg.png';
    if (note.title == 'Ideas') bgAsset = 'assets/icons/Idea-bg.png';
    if (note.title == 'Slam Book') bgAsset = 'assets/icons/slam-book.jpg';
    if (note.title == 'Time Capsule') bgAsset = 'assets/icons/time_capsule.jpg';
    if (note.title == 'Expenses') bgAsset = 'assets/icons/expences.png';
    final isSmallIcon = note.title == 'Slam Book' || note.title == 'Time Capsule' || note.title == 'Expenses';
    final isExpenses = note.title == 'Expenses';
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: bgAsset != null && !isSmallIcon
              ? DecorationImage(image: AssetImage(bgAsset), fit: BoxFit.cover)
              : null,
          color: bgAsset == null ? Colors.purple[100] : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            if (bgAsset != null && isSmallIcon)
              Center(
                child: Container(
                  width: isExpenses ? width * 0.8 : width * 0.65,
                  height: height * 0.65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      bgAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            // Title at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  note.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}