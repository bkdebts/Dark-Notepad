import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/loading_indicator.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  
  const NoteEditorScreen({
    Key? key,
    this.note,
  }) : super(key: key);

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  
  Note? _note;
  bool _isEdited = false;
  bool _isSaving = false;
  bool _isExporting = false;
  DateTime? _reminderTime;
  String _noteColor = '#121212';
  List<String> _tags = [];
  bool _showReminderPicker = false;
  
  final FocusNode _contentFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize note
    _note = widget.note?.copy() ?? Note.empty();
    
    // Set controllers from note
    _titleController.text = _note!.title;
    _contentController.text = _note!.content;
    
    // Set other fields
    if (_note!.reminderTime != null) {
      _reminderTime = DateTime.parse(_note!.reminderTime!);
    }
    _noteColor = _note!.color;
    _tags = List<String>.from(_note!.tags);
    
    // Add listeners to controllers
    _titleController.addListener(_markAsEdited);
    _contentController.addListener(_markAsEdited);
    
    // Set up auto save
    _setupAutoSave();
  }
  
  void _setupAutoSave() {
    // Auto save every 10 seconds if edited
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isEdited && !_isSaving) {
        _saveNote();
      }
      _setupAutoSave();
    });
  }
  
  void _markAsEdited() {
    if (!_isEdited) {
      setState(() {
        _isEdited = true;
      });
    }
  }
  
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Update note data
      _note!.update(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        reminderTime: _reminderTime?.toIso8601String(),
        color: _noteColor,
        tags: _tags,
      );
      
      // Save to local storage
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveNote(_note!);
      
      // Save to cloud if authenticated
      final authService = Provider.of<AuthService>(context, listen: false);
      final noteService = Provider.of<NoteService>(context, listen: false);
      
      if (authService.isAuthenticated && !authService.isAnonymous) {
        await noteService.saveNoteToCloud(_note!);
      }
      
      // Schedule reminder if needed
      if (_reminderTime != null) {
        final notificationService = NotificationService();
        
        // Cancel existing reminder
        await notificationService.cancelReminder(_note!.id);
        
        // Schedule new reminder if it's in the future
        if (_reminderTime!.isAfter(DateTime.now())) {
          await notificationService.scheduleReminder(
            _note!.id,
            _note!.title.isEmpty ? 'Reminder' : _note!.title,
            _note!.getContentPreview(),
            _reminderTime!,
          );
        }
      }
      
      setState(() {
        _isEdited = false;
      });
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save note: $e'),
          backgroundColor: AppTheme.errorColor,
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
      // Save before popping
      await _saveNote();
    }
    return true;
  }
  
  Future<void> _exportAsPdf() async {
    if (_isExporting) return;
    
    setState(() {
      _isExporting = true;
    });
    
    try {
      // Save any unsaved changes
      if (_isEdited) {
        await _saveNote();
      }
      
      // Generate PDF
      final pdfService = PdfService();
      final pdf = await pdfService.generateNotePdf(_note!);
      
      // Get file name
      final title = _note!.title.isEmpty ? 'Untitled Note' : _note!.title;
      final formattedTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();
      final fileName = '${formattedTitle}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      
      // Show export options
      _showExportOptions(pdf, fileName);
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export note: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
  
  void _showExportOptions(dynamic pdf, String fileName) {
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
              'Export Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.print, color: AppTheme.primaryColor),
              title: const Text('Print'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await PdfService().printPdf(pdf);
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
                  final filePath = await PdfService().savePdfToFile(pdf, fileName);
                  
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
                  await PdfService().sharePdf(pdf, fileName);
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
  
  void _addTag() {
    final tag = _tagController.text.trim();
    
    if (tag.isEmpty) return;
    
    // Convert to lowercase and remove spaces
    final formattedTag = tag.toLowerCase().replaceAll(' ', '_');
    
    if (!_tags.contains(formattedTag)) {
      setState(() {
        _tags.add(formattedTag);
        _markAsEdited();
      });
    }
    
    _tagController.clear();
  }
  
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _markAsEdited();
    });
  }
  
  void _selectReminderDate() async {
    final initialDate = _reminderTime ?? DateTime.now().add(const Duration(minutes: 30));
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      // Now select time
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.white,
                surface: AppTheme.cardColor,
                onSurface: AppTheme.textPrimaryColor,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        setState(() {
          _reminderTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _markAsEdited();
        });
      }
    }
  }
  
  void _removeReminder() {
    setState(() {
      _reminderTime = null;
      _markAsEdited();
    });
  }
  
  void _showColorPicker() {
    final colors = [
      '#121212', // Default dark background
      '#845EF7', // Primary color
      '#5C7CFA', // Accent color
      '#FA5252', // Error color
      '#51CF66', // Success color
      '#FFD43B', // Warning color
      '#20C997', // Teal
      '#FF922B', // Orange
      '#F06595', // Pink
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Color',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                final isSelected = _noteColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _noteColor = color;
                      _markAsEdited();
                      Navigator.pop(context);
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: _isSaving
              ? const Text('Saving...')
              : Text(_note!.title.isEmpty ? 'New Note' : _note!.title),
          actions: [
            // Export button
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isExporting ? null : _exportAsPdf,
              tooltip: 'Export as PDF',
            ),
            
            // More options
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    _shareNote();
                    break;
                  case 'duplicate':
                    _duplicateNote();
                    break;
                  case 'delete':
                    _confirmDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.errorColor),
                    title: Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_isEdited) {
                await _saveNote();
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            // Main content
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  
                  // Note metadata (date, reminder)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Date
                        Text(
                          'Edited: ${DateFormat('MMM dd, yyyy').format(_note!.modifiedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        
                        const Spacer(),
                        
                        // Reminder
                        if (_reminderTime != null)
                          GestureDetector(
                            onTap: _showReminderPicker
                                ? null
                                : () {
                                    setState(() {
                                      _showReminderPicker = true;
                                    });
                                  },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.alarm,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM dd, HH:mm').format(_reminderTime!),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _showReminderPicker
                                ? null
                                : () {
                                    setState(() {
                                      _showReminderPicker = true;
                                    });
                                  },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.alarm_add,
                                  size: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Add reminder',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Tags
                  if (_tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) => Chip(
                          label: Text('#$tag'),
                          backgroundColor: AppTheme.cardColor,
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          onDeleted: () => _removeTag(tag),
                        )).toList(),
                      ),
                    ),
                  
                  // Divider
                  const Divider(),
                  
                  // Content field
                  TextFormField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Start typing your note...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: null,
                    minLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            
            // Saving indicator
            if (_isSaving)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Saving...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Reminder picker
            if (_showReminderPicker)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Set Reminder',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _showReminderPicker = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _selectReminderDate,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  _reminderTime == null
                                      ? 'Select Date & Time'
                                      : DateFormat('MMM dd, yyyy - HH:mm').format(_reminderTime!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_reminderTime != null)
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove Reminder'),
                          onPressed: _removeReminder,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: AppTheme.cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Color picker
                IconButton(
                  icon: const Icon(Icons.color_lens),
                  onPressed: _showColorPicker,
                  tooltip: 'Change color',
                ),
                
                // Tag add button
                IconButton(
                  icon: const Icon(Icons.tag),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Add Tag'),
                        content: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Enter tag name',
                          ),
                          textCapitalization: TextCapitalization.none,
                          autofocus: true,
                          onSubmitted: (_) {
                            _addTag();
                            Navigator.pop(context);
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _addTag();
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Add tag',
                ),
                
                // Reminder button
                IconButton(
                  icon: Icon(
                    _reminderTime != null ? Icons.alarm : Icons.alarm_add,
                    color: _reminderTime != null ? AppTheme.primaryColor : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _showReminderPicker = true;
                    });
                  },
                  tooltip: 'Set reminder',
                ),
                
                const Spacer(),
                
                // Save button
                TextButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: _isSaving ? null : _saveNote,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    final text = title.isNotEmpty
        ? '$title\n\n$content'
        : content;
    
    await Share.share(text);
  }
  
  Future<void> _duplicateNote() async {
    // Create a copy of the note
    final newNote = Note(
      title: '${_titleController.text.trim()} (Copy)',
      content: _contentController.text.trim(),
      color: _noteColor,
      tags: List<String>.from(_tags),
    );
    
    // Save the copy
    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.saveNote(newNote);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note duplicated'),
        backgroundColor: AppTheme.successColor,
      ),
    );
    
    // Go back to the notes list
    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              final storageService = Provider.of<StorageService>(context, listen: false);
              final noteService = Provider.of<NoteService>(context, listen: false);
              final notificationService = NotificationService();
              
              // Delete note locally
              await storageService.deleteNote(_note!.id);
              
              // Delete from cloud if authenticated
              final authService = Provider.of<AuthService>(context, listen: false);
              if (authService.isAuthenticated && !authService.isAnonymous) {
                await noteService.deleteNoteFromCloud(_note!.id);
              }
              
              // Cancel any reminders
              if (_note!.reminderTime != null) {
                await notificationService.cancelReminder(_note!.id);
              }
              
              // Show success message and navigate back
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                
                Navigator.pop(context); // Return to notes list
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
