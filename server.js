const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const db = require('./db');

// Initialize express app
const app = express();
const PORT = process.env.PORT || 5000;

// Apply middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Serve static files from the current directory
app.use(express.static('./'));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes

// Get all notes
app.get('/api/notes', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM notes ORDER BY modified_at DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching notes:', error);
    res.status(500).json({ error: 'Failed to fetch notes' });
  }
});

// Get a single note by id
app.get('/api/notes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('SELECT * FROM notes WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching note:', error);
    res.status(500).json({ error: 'Failed to fetch note' });
  }
});

// Helper function to save base64 images
const saveBase64Image = (base64Data, noteId) => {
  // Create directory for this note if it doesn't exist
  const noteDir = path.join(uploadsDir, `note_${noteId}`);
  if (!fs.existsSync(noteDir)) {
    fs.mkdirSync(noteDir, { recursive: true });
  }
  
  // Extract content type and actual base64 data
  const matches = base64Data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
  
  if (!matches || matches.length !== 3) {
    throw new Error('Invalid base64 string');
  }
  
  const contentType = matches[1];
  const base64 = matches[2];
  const extension = contentType.split('/')[1];
  const fileName = `image_${Date.now()}.${extension}`;
  const filePath = path.join(noteDir, fileName);
  
  // Write the file
  fs.writeFileSync(filePath, base64, { encoding: 'base64' });
  
  // Return the relative path to the saved image
  return `/uploads/note_${noteId}/${fileName}`;
};

// Create a new note
app.post('/api/notes', async (req, res) => {
  try {
    const { title, content, is_favorite, color, tags, note_type, images } = req.body;
    
    // Validation
    if (!title || !content) {
      return res.status(400).json({ error: 'Title and content are required' });
    }
    
    let imagePaths = [];
    let result;
    
    // First, insert the note to get an ID
    result = await db.query(
      'INSERT INTO notes (title, content, is_favorite, color, tags, note_type) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [title, content, is_favorite || false, color || '#121212', tags || [], note_type || 'text']
    );
    
    const newNote = result.rows[0];
    
    // If it's a memory note with images, process and save them
    if (note_type === 'memory' && images && images.length > 0) {
      try {
        // Save each image and collect paths
        for (const imageData of images) {
          const imagePath = saveBase64Image(imageData, newNote.id);
          imagePaths.push(imagePath);
        }
        
        // Update the note with image paths
        if (imagePaths.length > 0) {
          result = await db.query(
            'UPDATE notes SET images = $1 WHERE id = $2 RETURNING *',
            [imagePaths, newNote.id]
          );
        }
      } catch (imgError) {
        console.error('Error saving images:', imgError);
        // Continue even if image saving fails
      }
    }
    
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating note:', error);
    res.status(500).json({ error: 'Failed to create note' });
  }
});

// Update a note
app.put('/api/notes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, is_favorite, color, tags, note_type, images, existing_images } = req.body;
    
    // Validation
    if (!title || !content) {
      return res.status(400).json({ error: 'Title and content are required' });
    }
    
    // Get existing note to check type and images
    const existingNote = await db.query('SELECT * FROM notes WHERE id = $1', [id]);
    
    if (existingNote.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    let imagePaths = existing_images || existingNote.rows[0].images || [];
    
    // If it's a memory note with new images, process and save them
    if (note_type === 'memory' && images && images.length > 0) {
      try {
        // Save each new image and collect paths
        for (const imageData of images) {
          // Only process if it's a base64 image (not an existing path)
          if (imageData.startsWith('data:image')) {
            const imagePath = saveBase64Image(imageData, id);
            imagePaths.push(imagePath);
          }
        }
      } catch (imgError) {
        console.error('Error saving images:', imgError);
        // Continue even if image saving fails
      }
    }
    
    // Update the note with all fields including image paths
    const result = await db.query(
      'UPDATE notes SET title = $1, content = $2, is_favorite = $3, color = $4, tags = $5, note_type = $6, images = $7, modified_at = CURRENT_TIMESTAMP WHERE id = $8 RETURNING *',
      [title, content, is_favorite || false, color || '#121212', tags || [], note_type || 'text', imagePaths, id]
    );
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating note:', error);
    res.status(500).json({ error: 'Failed to update note' });
  }
});

// Toggle favorite status
app.patch('/api/notes/:id/favorite', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await db.query(
      'UPDATE notes SET is_favorite = NOT is_favorite, modified_at = CURRENT_TIMESTAMP WHERE id = $1 RETURNING *',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error toggling favorite status:', error);
    res.status(500).json({ error: 'Failed to toggle favorite status' });
  }
});

// Delete a note
app.delete('/api/notes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get the note first to check if it has images
    const noteQuery = await db.query('SELECT * FROM notes WHERE id = $1', [id]);
    
    if (noteQuery.rows.length === 0) {
      return res.status(404).json({ error: 'Note not found' });
    }
    
    const note = noteQuery.rows[0];
    
    // Delete the note from the database
    const result = await db.query('DELETE FROM notes WHERE id = $1 RETURNING *', [id]);
    
    // If the note had images, clean up the image directory
    if (note.note_type === 'memory' && note.images && note.images.length > 0) {
      try {
        const noteDir = path.join(uploadsDir, `note_${id}`);
        if (fs.existsSync(noteDir)) {
          // Delete all files in the directory
          fs.readdirSync(noteDir).forEach(file => {
            fs.unlinkSync(path.join(noteDir, file));
          });
          
          // Remove the directory
          fs.rmdirSync(noteDir);
        }
      } catch (cleanupError) {
        console.error('Error cleaning up image files:', cleanupError);
        // Continue even if cleanup fails
      }
    }
    
    res.json({ message: 'Note deleted successfully', note: result.rows[0] });
  } catch (error) {
    console.error('Error deleting note:', error);
    res.status(500).json({ error: 'Failed to delete note' });
  }
});

// Serve the main HTML file for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.resolve(__dirname, 'index.html'));
});

// Initialize database and start server
const startServer = async () => {
  try {
    await db.initializeDatabase();
    
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
  }
};

startServer();