import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? releaseAt;
  final Uint8List? imageBytes;
  final Uint8List? videoBytes;
  final bool isLocked;
  bool isSynced;

  Note({
    String? id,
    this.title = '',
    this.content = '',
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.isSynced = false,
    this.releaseAt,
    this.imageBytes,
    this.videoBytes,
    this.isLocked = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isSynced,
    DateTime? releaseAt,
    Uint8List? imageBytes,
    Uint8List? videoBytes,
    bool? isLocked,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
      releaseAt: releaseAt ?? this.releaseAt,
      imageBytes: imageBytes ?? this.imageBytes,
      videoBytes: videoBytes ?? this.videoBytes,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isSynced': isSynced,
      'releaseAt': releaseAt?.toIso8601String(),
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'videoBytes': videoBytes != null ? base64Encode(videoBytes!) : null,
      'isLocked': isLocked,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      isSynced: json['isSynced'] ?? false,
      releaseAt: json['releaseAt'] != null ? DateTime.parse(json['releaseAt']) : null,
      imageBytes: json['imageBytes'] != null ? base64Decode(json['imageBytes']) : null,
      videoBytes: json['videoBytes'] != null ? base64Decode(json['videoBytes']) : null,
      isLocked: json['isLocked'] ?? false,
    );
  }
} 