import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';

class SlamBookScreen extends StatefulWidget {
  final Function(Note) onSave;
  const SlamBookScreen({Key? key, required this.onSave}) : super(key: key);

  @override
  State<SlamBookScreen> createState() => _SlamBookScreenState();
}

class _SlamBookScreenState extends State<SlamBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _favQuoteController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  Uint8List? _imageBytes;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _saveSlamBook() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final note = Note(
      title: 'Slam Book: ' + _nameController.text.trim(),
      content: 'Favorite Quote: ' + _favQuoteController.text.trim() + '\n\nAbout: ' + _aboutController.text.trim(),
      imageBytes: _imageBytes,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      isSynced: false,
    );
    widget.onSave(note);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slam Book Entry'),
        backgroundColor: Colors.pinkAccent,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
            onPressed: _isSaving ? null : _saveSlamBook,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/slam-book.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.85), BlendMode.lighten),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              color: Colors.white.withOpacity(0.92),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.pink[100],
                          backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                          child: _imageBytes == null
                              ? const Icon(Icons.add_a_photo, size: 36, color: Colors.pink)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person, color: Colors.pink),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _favQuoteController,
                        decoration: const InputDecoration(
                          labelText: 'Favorite Quote',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.format_quote, color: Colors.purple),
                        ),
                        maxLines: 2,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter a quote' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _aboutController,
                        decoration: const InputDecoration(
                          labelText: 'About You (fun fact, hobby, etc.)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.favorite, color: Colors.red),
                        ),
                        maxLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Tell us something!' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 