import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../utils/theme.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  
  const NoteCard({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.shortAnimationDuration,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }
  
  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Parse note color
    final Color noteColor = widget.note.color == '#121212'
        ? AppTheme.cardColor
        : Color(int.parse(widget.note.color.substring(1), radix: 16) + 0xFF000000);
    
    // Format date
    final String formattedDate = DateFormat('MMM dd, yyyy').format(widget.note.modifiedAt);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: noteColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note header
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        widget.note.title.isEmpty ? 'Untitled' : widget.note.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Favorite button
                    IconButton(
                      icon: Icon(
                        widget.note.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.note.isFavorite
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                      ),
                      onPressed: widget.onToggleFavorite,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              
              // Note preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.note.getContentPreview(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tags
              if (widget.note.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.note.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Card footer (date and actions)
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 8,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    // Date
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    
                    const Spacer(),
                    
                    // Reminder indicator
                    if (widget.note.reminderTime != null)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.alarm,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    
                    // Delete button
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.textSecondaryColor,
                      ),
                      onPressed: widget.onDelete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
