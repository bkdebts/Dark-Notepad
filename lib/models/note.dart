import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Note {
  final String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime modifiedAt;
  bool isFavorite;
  String? reminderTime;
  String color;
  List<String> tags;
  bool isSynced;

  Note({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.isFavorite = false,
    this.reminderTime,
    this.color = '#121212',
    this.tags = const [],
    this.isSynced = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  // Create from JSON for local storage
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      isFavorite: json['isFavorite'] ?? false,
      reminderTime: json['reminderTime'],
      color: json['color'] ?? '#121212',
      tags: List<String>.from(json['tags'] ?? []),
      isSynced: json['isSynced'] ?? false,
    );
  }

  // Create from Firestore document
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      modifiedAt: (data['modifiedAt'] as Timestamp).toDate(),
      isFavorite: data['isFavorite'] ?? false,
      reminderTime: data['reminderTime'],
      color: data['color'] ?? '#121212',
      tags: List<String>.from(data['tags'] ?? []),
      isSynced: true,
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'reminderTime': reminderTime,
      'color': color,
      'tags': tags,
      'isSynced': isSynced,
    };
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'isFavorite': isFavorite,
      'reminderTime': reminderTime,
      'color': color,
      'tags': tags,
      'lastSyncedAt': Timestamp.now(),
    };
  }

  // Get a formatted date string for display
  String getFormattedDate() {
    final formatter = DateFormat('MMM dd, yyyy HH:mm');
    return formatter.format(modifiedAt);
  }

  // Get a preview of the content
  String getContentPreview({int maxLength = 100}) {
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }

  // Update the note
  void update({
    String? title,
    String? content,
    bool? isFavorite,
    String? reminderTime,
    String? color,
    List<String>? tags,
  }) {
    if (title != null) this.title = title;
    if (content != null) this.content = content;
    if (isFavorite != null) this.isFavorite = isFavorite;
    if (reminderTime != null) this.reminderTime = reminderTime;
    if (color != null) this.color = color;
    if (tags != null) this.tags = tags;
    
    this.modifiedAt = DateTime.now();
    this.isSynced = false;
  }

  // Create a copy of this note
  Note copy() {
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      isFavorite: isFavorite,
      reminderTime: reminderTime,
      color: color,
      tags: List<String>.from(tags),
      isSynced: isSynced,
    );
  }

  // Empty note factory
  factory Note.empty() {
    return Note(
      title: '',
      content: '',
    );
  }
}
