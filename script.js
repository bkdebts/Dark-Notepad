// Demo data for notes
const demoNotes = [
    {
        id: '1',
        title: 'Welcome to Dark Notepad',
        content: 'This is a beautiful cross-platform notepad application with cloud sync, PDF export, and a stunning dark mode UI.',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
        modifiedAt: new Date(Date.now() - 12 * 60 * 60 * 1000), // 12 hours ago
        tags: ['welcome', 'info'],
        isFavorite: true,
        color: '#121212'
    },
    {
        id: '2',
        title: 'Project Ideas',
        content: '1. Mobile app for task tracking\n2. Portfolio website\n3. E-commerce dashboard\n4. Recipe manager\n5. Budget planner',
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), // 5 days ago
        modifiedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
        tags: ['projects', 'ideas'],
        isFavorite: false,
        color: '#121212'
    },
    {
        id: '3',
        title: 'Meeting Notes',
        content: 'Team meeting 04/20:\n- Discussed project timeline\n- Assigned tasks to team members\n- Set next meeting for 04/27\n- Review design mockups',
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
        modifiedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000), // 4 days ago
        tags: ['work', 'meeting'],
        isFavorite: false,
        color: '#121212'
    },
    {
        id: '4',
        title: 'Shopping List',
        content: '- Milk\n- Eggs\n- Bread\n- Cheese\n- Apples\n- Coffee\n- Pasta\n- Tomato sauce',
        createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
        modifiedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
        tags: ['shopping', 'personal'],
        isFavorite: false,
        color: '#121212'
    },
    {
        id: '5',
        title: 'Flutter Tips',
        content: '1. Use const constructors when possible\n2. Prefer StatelessWidget over StatefulWidget\n3. Use AnimatedBuilder for complex animations\n4. Leverage Provider for state management\n5. Use MediaQuery for responsive design',
        createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), // 10 days ago
        modifiedAt: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000), // 6 days ago
        tags: ['flutter', 'coding'],
        isFavorite: true,
        color: '#845EF7'
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
let notes = [...demoNotes];
let isSearchActive = false;
let searchQuery = '';

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
    
    noteCard.innerHTML = `
        <div class="note-header">
            <div class="note-title">${note.title}</div>
            <i class="material-icons favorite-btn ${note.isFavorite ? 'active' : ''}">${note.isFavorite ? 'favorite' : 'favorite_border'}</i>
        </div>
        <div class="note-content">${getContentPreview(note.content)}</div>
        ${note.tags.length > 0 ? `
            <div class="note-tags">
                ${note.tags.map(tag => `<div class="note-tag">#${tag}</div>`).join('')}
            </div>
        ` : ''}
        <div class="note-footer">
            <div class="note-date">${formatDate(note.modifiedAt)}</div>
            <div class="note-actions">
                <i class="material-icons">delete_outline</i>
            </div>
        </div>
    `;
    
    // Add event listeners
    noteCard.addEventListener('click', () => showSnackbar('This is a demo version. Note editing is not available.'));
    
    const favoriteBtn = noteCard.querySelector('.favorite-btn');
    favoriteBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        toggleFavorite(note.id);
    });
    
    const deleteBtn = noteCard.querySelector('.note-actions i');
    deleteBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        showSnackbar('This is a demo version. Note deletion is not available.');
    });
    
    return noteCard;
}

// Toggle favorite status of a note
function toggleFavorite(noteId) {
    notes = notes.map(note => {
        if (note.id === noteId) {
            return { ...note, isFavorite: !note.isFavorite };
        }
        return note;
    });
    
    renderNotes();
}

// Filter notes based on search query
function filterNotes() {
    if (!isSearchActive || searchQuery === '') {
        return notes;
    }
    
    const query = searchQuery.toLowerCase();
    return notes.filter(note => 
        note.title.toLowerCase().includes(query) ||
        note.content.toLowerCase().includes(query) ||
        note.tags.some(tag => tag.toLowerCase().includes(query))
    );
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
            <i class="material-icons">note_outlined</i>
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

// Initialize the app
function initApp() {
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
        showSnackbar('This is a demo version. Note creation is not available.');
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
    
    // Render initial notes
    renderNotes();
    
    // Add transitions after initial render
    splashScreen.style.transition = 'opacity 0.5s ease';
}

// Start the app when DOM is fully loaded
document.addEventListener('DOMContentLoaded', initApp);