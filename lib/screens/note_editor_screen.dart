import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../screens/home_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Function(Note, {bool showSnackbar}) onSave;
  final Function(Note)? onDelete;
  
  const NoteEditorScreen({
    Key? key,
    this.note,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Note _note;
  bool _isEdited = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    _note = widget.note ?? Note();
    
    _titleController = TextEditingController(text: _note.title);
    _contentController = TextEditingController(text: _note.content);
    
    _titleController.addListener(_markAsEdited);
    _contentController.addListener(_markAsEdited);
  }
  
  void _markAsEdited() {
    if (!_isEdited) {
      setState(() {
        _isEdited = true;
      });
    }
  }
  
  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final updatedNote = _note.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );
      
      widget.onSave(updatedNote, showSnackbar: false);
      
      setState(() {
        _isEdited = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<bool> _onWillPop() async {
    if (_isEdited) {
      final updatedNote = _note.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );
      widget.onSave(updatedNote, showSnackbar: false);
                }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
    return false;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: _AnimatedBackButton(onBack: () {
            _onWillPop();
          }),
          title: Text(_note.title.isEmpty ? 'New Note' : _note.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final text = '${_titleController.text.trim()}\n\n${_contentController.text.trim()}';
                Share.share(text, subject: _titleController.text.trim());
              },
            ),
            if (widget.note != null && widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () {
                  widget.onDelete!(_note);
                  Navigator.of(context).pop();
                },
            ),
            if (_isEdited)
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: _isSaving ? null : _saveNote,
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_note.imageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.pinkAccent, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_note.imageBytes!, height: 120),
                  ),
                ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackButton extends StatefulWidget {
  final VoidCallback? onBack;
  const _AnimatedBackButton({this.onBack});
  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
  }
  
class _AnimatedBackButtonState extends State<_AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  final List<Color> _colors = [
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _colorAnimation = _controller.drive(
      TweenSequence<Color?>([
        for (int i = 0; i < _colors.length; i++)
          TweenSequenceItem(
            tween: ColorTween(
              begin: _colors[i],
              end: _colors[(i + 1) % _colors.length],
            ),
            weight: 1,
          ),
      ]),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: GestureDetector(
            onTap: widget.onBack ?? () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _colorAnimation.value ?? Colors.purple,
                    (_colorAnimation.value ?? Colors.purple).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? Colors.purple).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
          ),
            ),
      ),
    );
      },
    );
}
} 