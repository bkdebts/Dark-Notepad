import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class TimeCapsuleEditorScreen extends StatefulWidget {
  final Function(TimeCapsuleNote) onSave;
  const TimeCapsuleEditorScreen({Key? key, required this.onSave}) : super(key: key);

  @override
  State<TimeCapsuleEditorScreen> createState() => _TimeCapsuleEditorScreenState();
}

class TimeCapsuleNote {
  final String id;
  final String name;
  final String text;
  final DateTime createdAt;
  final DateTime releaseAt;
  final String? imagePath;
  final String? videoPath;
  final Uint8List? imageBytes;
  final Uint8List? videoBytes;
  bool isLocked;

  TimeCapsuleNote({
    required this.id,
    required this.name,
    required this.text,
    required this.createdAt,
    required this.releaseAt,
    this.imagePath,
    this.videoPath,
    this.imageBytes,
    this.videoBytes,
    this.isLocked = true,
  });
}

class _TimeCapsuleEditorScreenState extends State<TimeCapsuleEditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  DateTime? _releaseDate;
  File? _imageFile;
  Uint8List? _imageBytes;
  File? _videoFile;
  Uint8List? _videoBytes;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
          _imageBytes = null;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _videoBytes = bytes;
          _videoFile = null;
        });
      } else {
        setState(() {
          _videoFile = File(picked.path);
          _videoBytes = null;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _releaseDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _saveCapsule() {
    if (_releaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a release date!')));
      return;
    }
    final now = DateTime.now();
    final name = _nameController.text.trim().isEmpty
        ? 'Time Capsule (${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})'
        : _nameController.text.trim() + ' (${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})';
    final note = TimeCapsuleNote(
      id: UniqueKey().toString(),
      name: name,
      text: _textController.text.trim(),
      createdAt: now,
      releaseAt: _releaseDate!,
      imagePath: _imageFile?.path,
      videoPath: _videoFile?.path,
      imageBytes: _imageBytes,
      videoBytes: _videoBytes,
      isLocked: true,
    );
    setState(() => _isSaving = true);
    widget.onSave(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Time Capsule'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text('Time Capsule', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent, letterSpacing: 2, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera, color: Colors.pinkAccent),
                  label: const Text('Add Photo'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.pinkAccent, side: BorderSide(width: 2, color: Colors.pinkAccent)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam, color: Colors.cyanAccent),
                  label: const Text('Add Video'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.cyanAccent, side: BorderSide(width: 2, color: Colors.cyanAccent)),
                ),
              ],
            ),
            if (_imageFile != null && !kIsWeb)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [Colors.purple, Colors.blue, Colors.cyan]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: Colors.black,
                  ),
                  child: Image.file(_imageFile!, height: 120),
                ),
              ),
            if (_imageBytes != null && kIsWeb)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [Colors.pink, Colors.purple, Colors.blue]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: Colors.black,
                  ),
                  child: Image.memory(_imageBytes!, height: 120),
                ),
              ),
            if (_videoFile != null && !kIsWeb)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [Colors.cyan, Colors.blue, Colors.purple]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: Colors.black,
                  ),
                  child: Icon(Icons.videocam, size: 48, color: Colors.cyanAccent),
                ),
              ),
            if (_videoBytes != null && kIsWeb)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [Colors.cyan, Colors.purple, Colors.pink]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: Colors.black,
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.videocam, size: 48, color: Colors.cyanAccent),
                      Text('Video selected (preview not supported on web)', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 5,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write your message or memory here... 🎉',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black87,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.purpleAccent)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.purpleAccent)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Friend's Name (optional)",
                labelStyle: TextStyle(color: Colors.greenAccent),
                prefixIcon: Icon(Icons.person, color: Colors.greenAccent),
                filled: true,
                fillColor: Colors.black87,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.greenAccent)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.greenAccent)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.pinkAccent)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [Colors.purple, Colors.blue, Colors.cyan]),
              ),
              child: ListTile(
                leading: Icon(Icons.lock_clock, color: Colors.deepPurpleAccent),
                title: Text(_releaseDate == null ? 'Select Release Date & Time' : 'Release: \\${_releaseDate!.toLocal()}', style: TextStyle(color: Colors.white)),
                onTap: _pickDateTime,
                tileColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCapsule,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(width: 2, color: Colors.purpleAccent),
                elevation: 8,
              ),
              child: const Text('Save Time Capsule', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
} 