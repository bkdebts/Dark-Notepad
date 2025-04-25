const { Pool } = require('pg');
require('dotenv').config();

// Create a new Pool using the connection string from environment variables
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Function to initialize the database with tables
const initializeDatabase = async () => {
  try {
    // Create notes table if it doesn't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notes (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_favorite BOOLEAN DEFAULT FALSE,
        color VARCHAR(50) DEFAULT '#121212',
        tags TEXT[] DEFAULT '{}',
        note_type VARCHAR(50) DEFAULT 'text',
        images TEXT[] DEFAULT '{}'
      );
    `);
    
    // Check if the note_type and images columns exist, add them if they don't
    const checkColumns = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'notes' AND column_name IN ('note_type', 'images');
    `);
    
    if (checkColumns.rows.length < 2) {
      // Add missing columns
      if (!checkColumns.rows.find(row => row.column_name === 'note_type')) {
        await pool.query(`ALTER TABLE notes ADD COLUMN note_type VARCHAR(50) DEFAULT 'text';`);
      }
      
      if (!checkColumns.rows.find(row => row.column_name === 'images')) {
        await pool.query(`ALTER TABLE notes ADD COLUMN images TEXT[] DEFAULT '{}';`);
      }
    }
    
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
    throw error;
  }
};

module.exports = {
  pool,
  initializeDatabase,
  query: (text, params) => pool.query(text, params)
};