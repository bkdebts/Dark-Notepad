// API endpoints
const API_URL = '/api/notes';

// Demo notes to seed the database if it's empty
const demoNotes = [
    {
        title: 'Welcome to Dark Notepad',
        content: 'This is a beautiful cross-platform notepad application with cloud sync, PDF export, and a stunning dark mode UI.',
        is_favorite: true,
        color: '#121212',
        tags: ['welcome', 'info']
    },
    {
        title: 'Project Ideas',
        content: '1. Mobile app for task tracking\n2. Portfolio website\n3. E-commerce dashboard\n4. Recipe manager\n5. Budget planner',
        is_favorite: false,
        color: '#121212',
        tags: ['projects', 'ideas']
    },
    {
        title: 'Meeting Notes',
        content: 'Team meeting 04/20:\n- Discussed project timeline\n- Assigned tasks to team members\n- Set next meeting for 04/27\n- Review design mockups',
        is_favorite: false,
        color: '#121212',
        tags: ['work', 'meeting']
    },
    {
        title: 'Shopping List',
        content: '- Milk\n- Eggs\n- Bread\n- Cheese\n- Apples\n- Coffee\n- Pasta\n- Tomato sauce',
        is_favorite: false,
        color: '#121212',
        tags: ['shopping', 'personal']
    },
    {
        title: 'Flutter Tips',
        content: '1. Use const constructors when possible\n2. Prefer StatelessWidget over StatefulWidget\n3. Use AnimatedBuilder for complex animations\n4. Leverage Provider for state management\n5. Use MediaQuery for responsive design',
        is_favorite: true,
        color: '#845EF7',
        tags: ['flutter', 'coding']
    }
];

// DOM Elements
const splashScreen = document.getElementById('splash-screen');
const app = document.getElementById('app');
const drawer = document.getElementById('drawer');
const modalBackdrop = document.getElementById('modal-backdrop');
const menuBtn = document.getElementById('menu-btn');
const searchBtn = document.getElementById('search-btn');
const searchBox = document.getElementById('search-box');
const searchInput = document.getElementById('search-input');
const closeSearchBtn = document.getElementById('close-search-btn');
const notesContainer = document.getElementById('notes-container');
const notesCountText = document.getElementById('notes-count-text');
const addNoteBtn = document.getElementById('add-note-btn');

// State variables
let notes = [];
let isSearchActive = false;
let searchQuery = '';
let isInitialized = false;

// Format date to "MMM DD, YYYY" format
function formatDate(date) {
    const options = { month: 'short', day: 'numeric', year: 'numeric' };
    return date.toLocaleDateString('en-US', options);
}

// Get a preview of the content (truncate if necessary)
function getContentPreview(content, maxLength = 100) {
    if (content.length <= maxLength) {
        return content;
    }
    return content.substring(0, maxLength) + '...';
}

// Create a note card element
function createNoteCard(note) {
    const noteCard = document.createElement('div');
    noteCard.className = 'note-card';
    noteCard.dataset.id = note.id;
    
    // If the note has a custom color, apply it
    if (note.color !== '#121212') {
        noteCard.className += ' primary';
    }
    
    // Convert database tags array from string to actual array if needed
    let tags = note.tags || [];
    if (typeof tags === 'string') {
        // Remove the curly braces and parse the tags
        tags = tags.replace(/{|}/g, '').split(',').filter(tag => tag.trim() !== '');
    }
    
    // Format the date
    const modifiedDate = new Date(note.modified_at || note.created_at);
    
    noteCard.innerHTML = `
        <div class="note-header">
            <div class="note-title">${note.title}</div>
            <i class="fas ${note.is_favorite ? 'fa-heart' : 'fa-heart-crack'} favorite-btn ${note.is_favorite ? 'active' : ''}"></i>
        </div>
        <div class="note-content">${getContentPreview(note.content)}</div>
        ${tags.length > 0 ? `
            <div class="note-tags">
                ${tags.map(tag => `<div class="note-tag"><i class="fas fa-tag fa-flip-horizontal"></i> ${tag}</div>`).join('')}
            </div>
        ` : ''}
        <div class="note-footer">
            <div class="note-date"><i class="far fa-clock"></i> ${formatDate(modifiedDate)}</div>
            <div class="note-actions">
                <i class="fas fa-share-alt"></i>
                <i class="fas fa-trash-alt"></i>
            </div>
        </div>
    `;
    
    // Add event listeners
    noteCard.addEventListener('click', () => {
        // Open note editor (to be implemented)
        showEditNote(note);
    });
    
    const favoriteBtn = noteCard.querySelector('.favorite-btn');
    favoriteBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        toggleFavorite(note.id);
    });
    
    const actionBtns = noteCard.querySelectorAll('.note-actions i');
    
    // Share button
    actionBtns[0].addEventListener('click', (e) => {
        e.stopPropagation();
        showSnackbar('Sharing features coming soon!');
    });
    
    // Delete button
    actionBtns[1].addEventListener('click', (e) => {
        e.stopPropagation();
        deleteNote(note.id);
    });
    
    return noteCard;
}

// Placeholder for note editor (to be implemented)
function showEditNote(note) {
    showSnackbar('Note editing coming soon!');
}

// API Functions

// Fetch all notes from server
async function fetchNotes() {
    try {
        const response = await fetch(API_URL);
        if (!response.ok) {
            throw new Error(`Failed to fetch notes: ${response.status}`);
        }
        const data = await response.json();
        notes = data;
        renderNotes();
    } catch (error) {
        console.error('Error fetching notes:', error);
        showSnackbar('Failed to load notes from server');
    }
}

// Create a new note
async function createNote(noteData) {
    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(noteData)
        });
        
        if (!response.ok) {
            throw new Error(`Failed to create note: ${response.status}`);
        }
        
        const newNote = await response.json();
        notes.unshift(newNote); // Add to beginning of array
        renderNotes();
        showSnackbar('Note created successfully');
        return newNote;
    } catch (error) {
        console.error('Error creating note:', error);
        showSnackbar('Failed to create note');
        return null;
    }
}

// Update an existing note
async function updateNote(noteId, noteData) {
    try {
        const response = await fetch(`${API_URL}/${noteId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(noteData)
        });
        
        if (!response.ok) {
            throw new Error(`Failed to update note: ${response.status}`);
        }
        
        const updatedNote = await response.json();
        notes = notes.map(note => note.id === noteId ? updatedNote : note);
        renderNotes();
        showSnackbar('Note updated successfully');
        return updatedNote;
    } catch (error) {
        console.error('Error updating note:', error);
        showSnackbar('Failed to update note');
        return null;
    }
}

// Delete a note
async function deleteNote(noteId) {
    if (!confirm('Are you sure you want to delete this note?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_URL}/${noteId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error(`Failed to delete note: ${response.status}`);
        }
        
        notes = notes.filter(note => note.id !== noteId);
        renderNotes();
        showSnackbar('Note deleted successfully');
    } catch (error) {
        console.error('Error deleting note:', error);
        showSnackbar('Failed to delete note');
    }
}

// Toggle favorite status of a note
async function toggleFavorite(noteId) {
    try {
        const response = await fetch(`${API_URL}/${noteId}/favorite`, {
            method: 'PATCH'
        });
        
        if (!response.ok) {
            throw new Error(`Failed to toggle favorite: ${response.status}`);
        }
        
        const updatedNote = await response.json();
        notes = notes.map(note => note.id === noteId ? updatedNote : note);
        renderNotes();
    } catch (error) {
        console.error('Error toggling favorite status:', error);
        showSnackbar('Failed to update favorite status');
    }
}

// Filter notes based on search query
function filterNotes() {
    if (!isSearchActive || searchQuery === '') {
        return notes;
    }
    
    const query = searchQuery.toLowerCase();
    return notes.filter(note => {
        // Check title and content
        if (note.title.toLowerCase().includes(query) || 
            note.content.toLowerCase().includes(query)) {
            return true;
        }
        
        // Process tags
        let tags = note.tags || [];
        if (typeof tags === 'string') {
            // Remove the curly braces and parse the tags
            tags = tags.replace(/{|}/g, '').split(',').filter(tag => tag.trim() !== '');
        }
        
        return tags.some(tag => tag.toLowerCase().includes(query));
    });
}

// Render notes to the container
function renderNotes() {
    const filteredNotes = filterNotes();
    notesContainer.innerHTML = '';
    
    // Update notes count
    notesCountText.textContent = `${notes.length} Notes`;
    
    if (filteredNotes.length === 0) {
        const emptyState = document.createElement('div');
        emptyState.className = 'empty-state';
        emptyState.innerHTML = `
            <i class="fas fa-book-open"></i>
            <h2>${isSearchActive ? 'No results found' : 'No notes yet'}</h2>
            ${!isSearchActive ? '<p>Tap the + button to create a note</p>' : ''}
        `;
        notesContainer.appendChild(emptyState);
    } else {
        filteredNotes.forEach(note => {
            notesContainer.appendChild(createNoteCard(note));
        });
    }
}

// Show a snackbar message
function showSnackbar(message) {
    // Remove any existing snackbar
    const existingSnackbar = document.querySelector('.snackbar');
    if (existingSnackbar) {
        existingSnackbar.remove();
    }
    
    // Create and show the snackbar
    const snackbar = document.createElement('div');
    snackbar.className = 'snackbar';
    snackbar.textContent = message;
    document.body.appendChild(snackbar);
    
    // Remove the snackbar after 3 seconds
    setTimeout(() => {
        snackbar.remove();
    }, 3000);
}

// Toggle drawer visibility
function toggleDrawer() {
    drawer.classList.toggle('visible');
    modalBackdrop.classList.toggle('hidden');
}

// Toggle search box visibility
function toggleSearch() {
    isSearchActive = !isSearchActive;
    searchBox.classList.toggle('hidden');
    
    if (isSearchActive) {
        searchInput.focus();
    } else {
        searchInput.value = '';
        searchQuery = '';
        renderNotes();
    }
}

// Seed database with demo notes if empty
async function seedDatabaseIfEmpty() {
    try {
        const response = await fetch(API_URL);
        if (!response.ok) {
            throw new Error(`Failed to fetch notes: ${response.status}`);
        }
        
        const data = await response.json();
        
        if (data.length === 0) {
            console.log('Database is empty, seeding with demo notes');
            
            // Create demo notes sequentially to prevent race conditions
            for (const note of demoNotes) {
                await createNote(note);
            }
            
            return true;
        }
        
        return false;
    } catch (error) {
        console.error('Error checking database:', error);
        showSnackbar('Failed to connect to the database');
        return false;
    }
}

// Initialize the app
async function initApp() {
    // Simulating splash screen delay
    setTimeout(() => {
        splashScreen.style.opacity = '0';
        setTimeout(() => {
            splashScreen.classList.add('hidden');
            app.classList.remove('hidden');
        }, 500); // Wait for fade out animation
    }, 2000); // Show splash for 2 seconds
    
    // Event listeners
    menuBtn.addEventListener('click', toggleDrawer);
    modalBackdrop.addEventListener('click', toggleDrawer);
    
    searchBtn.addEventListener('click', toggleSearch);
    closeSearchBtn.addEventListener('click', toggleSearch);
    
    searchInput.addEventListener('input', (e) => {
        searchQuery = e.target.value;
        renderNotes();
    });
    
    addNoteBtn.addEventListener('click', () => {
        // Open a popup to create a new note
        const noteTitle = prompt('Enter note title:');
        if (noteTitle) {
            const noteContent = prompt('Enter note content:');
            if (noteContent) {
                createNote({
                    title: noteTitle,
                    content: noteContent,
                    is_favorite: false,
                    color: '#121212',
                    tags: []
                });
            }
        }
    });
    
    // Initialize drawer items
    const drawerItems = document.querySelectorAll('.drawer-item');
    drawerItems.forEach(item => {
        item.addEventListener('click', () => {
            toggleDrawer();
            if (item.textContent.trim() !== 'Home') {
                showSnackbar(`${item.textContent.trim()} feature is not available in demo version.`);
            }
        });
    });
    
    // Seed database if empty, then fetch all notes
    try {
        await seedDatabaseIfEmpty();
        await fetchNotes();
        isInitialized = true;
    } catch (error) {
        console.error('Error initializing app:', error);
        showSnackbar('Failed to initialize the app. Please reload.');
    }
    
    // Add transitions after initial render
    splashScreen.style.transition = 'opacity 0.5s ease';
}

// Start the app when DOM is fully loaded
document.addEventListener('DOMContentLoaded', initApp);