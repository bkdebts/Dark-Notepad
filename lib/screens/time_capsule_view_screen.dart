import 'package:flutter/material.dart';
import '../models/note.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class TimeCapsuleViewScreen extends StatelessWidget {
  final Note note;
  const TimeCapsuleViewScreen({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Capsule'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              String shareText = note.title + '\n\n' + note.content;
              Share.share(shareText, subject: note.title);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('🎉 Time Capsule Unlocked! 🎉', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 24),
            if (note.imageBytes != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.memory(note.imageBytes!, height: 180),
              ),
            if (note.videoBytes != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.videocam, size: 48, color: Colors.blue),
                    Text('Video attached (playback not supported on web)', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Text(note.content, style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 32),
            Text('Created for: ${note.title}', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            Text('Released on: ${note.releaseAt}', style: TextStyle(color: Colors.deepPurple)),
          ],
        ),
      ),
    );
  }
} 