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

// Modal elements
const noteEditorModal = document.getElementById('note-editor-modal');
const modalTitle = document.getElementById('modal-title');
const noteTitle = document.getElementById('note-title');
const noteContent = document.getElementById('note-content');
const noteTags = document.getElementById('note-tags');
const tagsPreview = document.getElementById('tags-preview');
const noteFavorite = document.getElementById('note-favorite');
const closeModalBtn = document.getElementById('close-modal-btn');
const saveNoteBtn = document.getElementById('save-note-btn');
const cancelNoteBtn = document.getElementById('cancel-note-btn');
const addTagBtn = document.getElementById('add-tag-btn');

// Shopping List elements
const shoppingListModal = document.getElementById('shopping-list-modal');
const itemName = document.getElementById('item-name');
const addItemBtn = document.getElementById('add-item-btn');
const shoppingItems = document.getElementById('shopping-items');
const clearItemsBtn = document.getElementById('clear-items-btn');
const saveListBtn = document.getElementById('save-list-btn');
const closeShoppingListBtn = document.getElementById('close-shopping-list-btn');

// Memory Note elements
const memoryModal = document.getElementById('memory-modal');
const memoryModalTitle = document.getElementById('memory-modal-title');
const memoryTitle = document.getElementById('memory-title');
const memoryContent = document.getElementById('memory-content');
const memoryTags = document.getElementById('memory-tags');
const memoryTagsPreview = document.getElementById('memory-tags-preview');
const memoryFavorite = document.getElementById('memory-favorite');
const imagesContainer = document.getElementById('images-container');
const imageUpload = document.getElementById('image-upload');
const closeMemoryBtn = document.getElementById('close-memory-btn');
const saveMemoryBtn = document.getElementById('save-memory-btn');
const cancelMemoryBtn = document.getElementById('cancel-memory-btn');
const addMemoryTagBtn = document.getElementById('add-memory-tag-btn');

// Note Type Selection Modal
const noteTypeModal = document.getElementById('note-type-modal');
const textNoteOption = document.getElementById('text-note-option');
const memoryNoteOption = document.getElementById('memory-note-option');
const closeNoteTypeBtn = document.getElementById('close-note-type-btn');

// Drawer menu items
const homeItem = document.getElementById('home-item');
const favoritesItem = document.getElementById('favorites-item');
const shoppingListItem = document.getElementById('shopping-list-item');
const tagsItem = document.getElementById('tags-item');
const themesItem = document.getElementById('themes-item');
const settingsItem = document.getElementById('settings-item');

// State variables
let notes = [];
let isSearchActive = false;
let searchQuery = '';
let isInitialized = false;
let currentShoppingItems = [];
let currentFilter = 'all'; // 'all', 'favorites'
let currentImages = []; // For memory notes

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
    
    // If it's a memory note, add memory class
    if (note.note_type === 'memory') {
        noteCard.className += ' memory-card';
    }
    
    noteCard.dataset.id = note.id;
    noteCard.dataset.type = note.note_type || 'text';
    
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
    
    // Convert database images array from string to actual array if needed
    let images = note.images || [];
    if (typeof images === 'string') {
        // Remove the curly braces and parse the images
        images = images.replace(/{|}/g, '').split(',').filter(img => img.trim() !== '');
    }
    
    // Format the date
    const modifiedDate = new Date(note.modified_at || note.created_at);
    
    // Create different HTML structure depending on note type
    if (note.note_type === 'memory') {
        // Memory note card (with images)
        noteCard.innerHTML = `
            <div class="note-header">
                <div class="note-title">${note.title}</div>
                <i class="fas ${note.is_favorite ? 'fa-heart' : 'fa-heart-crack'} favorite-btn ${note.is_favorite ? 'active' : ''}"></i>
            </div>
            <div class="note-card-content">
                ${images.length > 0 ? `
                    <div class="memory-image-preview">
                        <img src="${images[0]}" alt="Memory Image">
                        ${images.length > 1 ? `
                            <div class="memory-image-count">
                                <i class="fas fa-images"></i> ${images.length}
                            </div>
                        ` : ''}
                    </div>
                ` : ''}
                <div class="memory-content">${getContentPreview(note.content)}</div>
                ${tags.length > 0 ? `
                    <div class="note-tags">
                        ${tags.map(tag => `<div class="note-tag"><i class="fas fa-tag fa-flip-horizontal"></i> ${tag}</div>`).join('')}
                    </div>
                ` : ''}
            </div>
            <div class="note-footer">
                <div class="note-date"><i class="far fa-clock"></i> ${formatDate(modifiedDate)}</div>
                <div class="note-actions">
                    <i class="fas fa-share-alt"></i>
                    <i class="fas fa-trash-alt"></i>
                </div>
            </div>
        `;
    } else {
        // Regular text note card
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
    }
    
    // Add event listeners
    noteCard.addEventListener('click', () => {
        // Open the appropriate editor based on note type
        if (note.note_type === 'memory') {
            showMemoryEditor(note);
        } else {
            showEditNote(note);
        }
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

// Show the note editor modal with note data
function showEditNote(note = null) {
    // Reset the form
    resetNoteForm();
    
    // Set the modal title
    modalTitle.textContent = note ? 'Edit Note' : 'Create New Note';
    
    // Populate form with note data if editing
    if (note) {
        noteTitle.value = note.title || '';
        noteContent.value = note.content || '';
        noteFavorite.checked = note.is_favorite || false;
        
        // Process tags
        let tags = note.tags || [];
        if (typeof tags === 'string') {
            // Remove the curly braces and parse the tags
            tags = tags.replace(/{|}/g, '').split(',').filter(tag => tag.trim() !== '');
        }
        
        // Add tags to the preview
        tags.forEach(tag => addTagToPreview(tag));
    }
    
    // Show the modal
    modalBackdrop.classList.remove('hidden');
    noteEditorModal.classList.add('visible');
    
    // Focus on the title field
    setTimeout(() => {
        noteTitle.focus();
    }, 300);
}

// Reset the note form
function resetNoteForm() {
    noteTitle.value = '';
    noteContent.value = '';
    noteTags.value = '';
    noteFavorite.checked = false;
    tagsPreview.innerHTML = '';
}

// Close the note editor modal
function closeNoteEditor() {
    noteEditorModal.classList.remove('visible');
    modalBackdrop.classList.add('hidden');
}

// Add a tag to the preview
function addTagToPreview(tagText) {
    if (!tagText || tagText.trim() === '') return;
    
    // Check if tag already exists
    const existingTags = Array.from(tagsPreview.querySelectorAll('.tag')).map(tag => 
        tag.textContent.replace('close', '').trim()
    );
    
    if (existingTags.includes(tagText.trim())) return;
    
    // Create tag element
    const tag = document.createElement('div');
    tag.className = 'tag';
    tag.innerHTML = `${tagText} <i class="fas fa-times"></i>`;
    
    // Add delete functionality
    tag.querySelector('i').addEventListener('click', () => {
        tag.remove();
    });
    
    tagsPreview.appendChild(tag);
}

// Get tags from the preview
function getTagsFromPreview() {
    return Array.from(tagsPreview.querySelectorAll('.tag')).map(tag => 
        tag.textContent.replace('close', '').trim()
    );
}

// Save the note
async function saveNote() {
    const title = noteTitle.value.trim();
    const content = noteContent.value.trim();
    const isFavorite = noteFavorite.checked;
    const tags = getTagsFromPreview();
    
    // Validate form
    if (!title) {
        showSnackbar('Please enter a title');
        return;
    }
    
    if (!content) {
        showSnackbar('Please enter some content');
        return;
    }
    
    // Create note data
    const noteData = {
        title,
        content,
        is_favorite: isFavorite,
        tags
    };
    
    // Check if we're editing or creating
    const noteId = noteEditorModal.dataset.noteId;
    
    try {
        if (noteId) {
            // Update existing note
            await updateNote(noteId, noteData);
        } else {
            // Create new note
            await createNote(noteData);
        }
        
        // Close the modal
        closeNoteEditor();
    } catch (error) {
        console.error('Error saving note:', error);
        showSnackbar('Failed to save note');
    }
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
    // First apply search filter if active
    let filteredNotes = filterNotes();
    
    // Then apply category filter
    filteredNotes = applyFilter(filteredNotes);
    
    notesContainer.innerHTML = '';
    
    // Update notes count and header text
    notesCountText.textContent = `${notes.length} Notes`;
    const headerText = document.querySelector('header h1');
    headerText.textContent = currentFilter === 'favorites' ? 'Favorites' : 'Notes';
    
    if (filteredNotes.length === 0) {
        const emptyState = document.createElement('div');
        emptyState.className = 'empty-state';
        
        let emptyIcon = 'fa-book-open';
        let emptyTitle = 'No notes yet';
        let emptyMessage = 'Tap the + button to create a note';
        
        if (isSearchActive) {
            emptyIcon = 'fa-search';
            emptyTitle = 'No results found';
            emptyMessage = '';
        } else if (currentFilter === 'favorites') {
            emptyIcon = 'fa-heart-broken';
            emptyTitle = 'No favorite notes';
            emptyMessage = 'Add notes to favorites to see them here';
        }
        
        emptyState.innerHTML = `
            <i class="fas ${emptyIcon}"></i>
            <h2>${emptyTitle}</h2>
            ${emptyMessage ? `<p>${emptyMessage}</p>` : ''}
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

// Shopping List Functions
function showShoppingList() {
    // Clear the items and reset the form
    shoppingItems.innerHTML = '';
    itemName.value = '';
    
    // Parse the shopping list from the notes
    parseShoppingListItems();
    
    // Show the modal
    modalBackdrop.classList.remove('hidden');
    shoppingListModal.classList.add('visible');
    
    // Focus on the input field
    setTimeout(() => {
        itemName.focus();
    }, 300);
}

function closeShoppingList() {
    shoppingListModal.classList.remove('visible');
    modalBackdrop.classList.add('hidden');
}

function parseShoppingListItems() {
    // Find a note with title "Shopping List"
    const shoppingListNote = notes.find(note => 
        note.title.toLowerCase() === 'shopping list'
    );
    
    if (!shoppingListNote) {
        // No shopping list found, create an empty array
        currentShoppingItems = [];
        renderShoppingItems();
        return;
    }
    
    // Parse items from the note content
    const content = shoppingListNote.content;
    const lines = content.split('\n');
    
    currentShoppingItems = lines
        .map(line => line.trim())
        .filter(line => line.startsWith('-'))
        .map(line => {
            const itemText = line.substring(1).trim();
            const isCompleted = itemText.startsWith('~') && itemText.endsWith('~');
            const text = isCompleted 
                ? itemText.substring(1, itemText.length - 1).trim()
                : itemText;
            
            return {
                text,
                isCompleted
            };
        });
    
    renderShoppingItems();
}

function renderShoppingItems() {
    shoppingItems.innerHTML = '';
    
    if (currentShoppingItems.length === 0) {
        const emptyState = document.createElement('div');
        emptyState.className = 'empty-state';
        emptyState.innerHTML = `
            <i class="fas fa-shopping-cart"></i>
            <h2>Your shopping list is empty</h2>
            <p>Add items above to get started</p>
        `;
        shoppingItems.appendChild(emptyState);
        return;
    }
    
    currentShoppingItems.forEach((item, index) => {
        const itemElement = document.createElement('div');
        itemElement.className = 'shopping-item';
        
        itemElement.innerHTML = `
            <div class="item-name ${item.isCompleted ? 'completed' : ''}">
                <i class="fas ${item.isCompleted ? 'fa-check-circle' : 'fa-circle'}"></i>
                ${item.text}
            </div>
            <div class="item-actions">
                <i class="fas ${item.isCompleted ? 'fa-circle' : 'fa-check-circle'}"></i>
                <i class="fas fa-trash-alt"></i>
            </div>
        `;
        
        // Toggle completion status
        const toggleBtn = itemElement.querySelector('.item-actions i:first-child');
        toggleBtn.addEventListener('click', () => {
            currentShoppingItems[index].isCompleted = !item.isCompleted;
            renderShoppingItems();
        });
        
        // Delete item
        const deleteBtn = itemElement.querySelector('.item-actions i:last-child');
        deleteBtn.addEventListener('click', () => {
            currentShoppingItems.splice(index, 1);
            renderShoppingItems();
        });
        
        // Toggle completion status by clicking on the item
        const itemName = itemElement.querySelector('.item-name');
        itemName.addEventListener('click', () => {
            currentShoppingItems[index].isCompleted = !item.isCompleted;
            renderShoppingItems();
        });
        
        shoppingItems.appendChild(itemElement);
    });
}

function addShoppingItem() {
    const text = itemName.value.trim();
    
    if (!text) {
        showSnackbar('Please enter an item');
        return;
    }
    
    currentShoppingItems.push({
        text,
        isCompleted: false
    });
    
    itemName.value = '';
    itemName.focus();
    
    renderShoppingItems();
}

function clearShoppingItems() {
    if (!confirm('Are you sure you want to clear all items?')) {
        return;
    }
    
    currentShoppingItems = [];
    renderShoppingItems();
}

async function saveShoppingList() {
    // Format the content
    const content = currentShoppingItems
        .map(item => item.isCompleted 
            ? `- ~${item.text}~` 
            : `- ${item.text}`
        )
        .join('\n');
    
    // Find an existing shopping list note
    const existingList = notes.find(note => 
        note.title.toLowerCase() === 'shopping list'
    );
    
    try {
        if (existingList) {
            // Update the existing note
            await updateNote(existingList.id, {
                ...existingList,
                content
            });
        } else {
            // Create a new note
            await createNote({
                title: 'Shopping List',
                content,
                is_favorite: false,
                tags: ['shopping']
            });
        }
        
        closeShoppingList();
        showSnackbar('Shopping list saved successfully');
    } catch (error) {
        console.error('Error saving shopping list:', error);
        showSnackbar('Failed to save shopping list');
    }
}

// Filter notes based on current filter
function applyFilter(notes) {
    if (currentFilter === 'favorites') {
        return notes.filter(note => note.is_favorite);
    }
    return notes;
}

// Memory Note Functions
function showNoteTypeSelection() {
    // Show the note type selection modal
    modalBackdrop.classList.remove('hidden');
    noteTypeModal.classList.add('visible');
}

function closeNoteTypeModal() {
    noteTypeModal.classList.remove('visible');
    modalBackdrop.classList.add('hidden');
}

function showMemoryEditor(note = null) {
    // Reset the form and images
    resetMemoryForm();
    
    // Set the modal title
    memoryModalTitle.textContent = note ? 'Edit Memory' : 'Create Memory';
    
    // Store the note ID if editing
    if (note) {
        memoryModal.dataset.noteId = note.id;
        
        // Populate form with note data
        memoryTitle.value = note.title || '';
        memoryContent.value = note.content || '';
        memoryFavorite.checked = note.is_favorite || false;
        
        // Process tags
        let tags = note.tags || [];
        if (typeof tags === 'string') {
            tags = tags.replace(/{|}/g, '').split(',').filter(tag => tag.trim() !== '');
        }
        
        // Add tags to the preview
        tags.forEach(tag => addMemoryTagToPreview(tag));
        
        // Process and display existing images
        let images = note.images || [];
        if (typeof images === 'string') {
            images = images.replace(/{|}/g, '').split(',').filter(img => img.trim() !== '');
        }
        
        // Add existing images to the preview and keep track of them
        images.forEach(imagePath => {
            addImagePreview(imagePath);
        });
    } else {
        memoryModal.dataset.noteId = '';
    }
    
    // Show the modal
    modalBackdrop.classList.remove('hidden');
    memoryModal.classList.add('visible');
    
    // Focus on the title field
    setTimeout(() => {
        memoryTitle.focus();
    }, 300);
}

function resetMemoryForm() {
    memoryTitle.value = '';
    memoryContent.value = '';
    memoryTags.value = '';
    memoryFavorite.checked = false;
    memoryTagsPreview.innerHTML = '';
    imagesContainer.innerHTML = '';
    currentImages = [];
}

function closeMemoryEditor() {
    memoryModal.classList.remove('visible');
    modalBackdrop.classList.add('hidden');
    resetMemoryForm();
}

function addMemoryTagToPreview(tagText) {
    if (!tagText || tagText.trim() === '') return;
    
    // Check if tag already exists
    const existingTags = Array.from(memoryTagsPreview.querySelectorAll('.tag')).map(tag => 
        tag.textContent.replace('close', '').trim()
    );
    
    if (existingTags.includes(tagText.trim())) return;
    
    // Create tag element
    const tag = document.createElement('div');
    tag.className = 'tag';
    tag.innerHTML = `${tagText} <i class="fas fa-times"></i>`;
    
    // Add delete functionality
    tag.querySelector('i').addEventListener('click', () => {
        tag.remove();
    });
    
    memoryTagsPreview.appendChild(tag);
}

function getMemoryTagsFromPreview() {
    return Array.from(memoryTagsPreview.querySelectorAll('.tag')).map(tag => 
        tag.textContent.replace('close', '').trim()
    );
}

function addImagePreview(imageSrc) {
    // Create a new image preview element
    const imagePreview = document.createElement('div');
    imagePreview.className = 'image-preview';
    
    // If it's a file (from input), use createObjectURL
    // If it's a server path, use directly
    let imgSrc = imageSrc;
    if (!(typeof imageSrc === 'string' && (imageSrc.startsWith('/') || imageSrc.startsWith('http')))) {
        imgSrc = URL.createObjectURL(imageSrc);
    }
    
    imagePreview.innerHTML = `
        <img src="${imgSrc}" alt="Memory Image">
        <div class="remove-btn">
            <i class="fas fa-times"></i>
        </div>
    `;
    
    // Add remove button functionality
    imagePreview.querySelector('.remove-btn').addEventListener('click', () => {
        // If it's a Blob URL, revoke it to free memory
        if (imgSrc.startsWith('blob:')) {
            URL.revokeObjectURL(imgSrc);
        }
        
        // Remove from the currentImages array
        if (typeof imageSrc === 'string') {
            currentImages = currentImages.filter(img => img !== imageSrc);
        } else {
            currentImages = currentImages.filter(img => img !== imageSrc);
        }
        
        // Remove the image preview element
        imagePreview.remove();
    });
    
    // Add to the images container
    imagesContainer.appendChild(imagePreview);
    
    // Add to current images array
    currentImages.push(imageSrc);
}

async function handleImageUpload(files) {
    // Process each selected file
    for (const file of files) {
        // Check if it's an image
        if (!file.type.startsWith('image/')) {
            showSnackbar('Only image files are allowed');
            continue;
        }
        
        // Check file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
            showSnackbar('Image too large (max 5MB)');
            continue;
        }
        
        // Add to the preview
        addImagePreview(file);
    }
}

async function convertImageToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}

async function saveMemory() {
    const title = memoryTitle.value.trim();
    const content = memoryContent.value.trim();
    const isFavorite = memoryFavorite.checked;
    const tags = getMemoryTagsFromPreview();
    
    // Validate form
    if (!title) {
        showSnackbar('Please enter a title');
        return;
    }
    
    if (!content) {
        showSnackbar('Please add a description');
        return;
    }
    
    // Show loading indicator
    const saveBtn = saveMemoryBtn;
    const originalText = saveBtn.innerHTML;
    saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
    saveBtn.disabled = true;
    
    try {
        // Convert file objects to base64 strings
        const imagePromises = currentImages.map(async image => {
            // If it's already a string (from server), return as is
            if (typeof image === 'string') {
                return image;
            }
            
            // Otherwise convert File to base64
            return await convertImageToBase64(image);
        });
        
        // Wait for all images to be processed
        const base64Images = await Promise.all(imagePromises);
        
        // Prepare note data
        const noteData = {
            title,
            content,
            is_favorite: isFavorite,
            tags,
            note_type: 'memory',
            images: base64Images
        };
        
        // Check if we're editing or creating
        const noteId = memoryModal.dataset.noteId;
        
        if (noteId) {
            // Update existing note
            await updateNote(noteId, noteData);
        } else {
            // Create new memory note
            await createNote(noteData);
        }
        
        // Close the modal
        closeMemoryEditor();
    } catch (error) {
        console.error('Error saving memory note:', error);
        showSnackbar('Failed to save memory');
    } finally {
        // Restore button state
        saveBtn.innerHTML = originalText;
        saveBtn.disabled = false;
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
    
    // Event listeners for drawer and search
    menuBtn.addEventListener('click', toggleDrawer);
    modalBackdrop.addEventListener('click', (e) => {
        if (drawer.classList.contains('visible')) {
            toggleDrawer();
        } else if (noteTypeModal.classList.contains('visible')) {
            closeNoteTypeModal();
        } else if (noteEditorModal.classList.contains('visible')) {
            closeNoteEditor();
        } else if (memoryModal.classList.contains('visible')) {
            closeMemoryEditor();
        } else if (shoppingListModal.classList.contains('visible')) {
            closeShoppingList();
        }
    });
    
    searchBtn.addEventListener('click', toggleSearch);
    closeSearchBtn.addEventListener('click', toggleSearch);
    
    searchInput.addEventListener('input', (e) => {
        searchQuery = e.target.value;
        renderNotes();
    });
    
    // Add note button
    addNoteBtn.addEventListener('click', () => {
        showNoteTypeSelection();
    });
    
    // Note type selection
    textNoteOption.addEventListener('click', () => {
        closeNoteTypeModal();
        showEditNote();
    });
    
    memoryNoteOption.addEventListener('click', () => {
        closeNoteTypeModal();
        showMemoryEditor();
    });
    
    closeNoteTypeBtn.addEventListener('click', closeNoteTypeModal);
    
    // Note editor modal buttons
    closeModalBtn.addEventListener('click', closeNoteEditor);
    cancelNoteBtn.addEventListener('click', closeNoteEditor);
    saveNoteBtn.addEventListener('click', saveNote);
    
    // Memory editor modal buttons
    closeMemoryBtn.addEventListener('click', closeMemoryEditor);
    cancelMemoryBtn.addEventListener('click', closeMemoryEditor);
    saveMemoryBtn.addEventListener('click', saveMemory);
    
    // Image upload handling
    imageUpload.addEventListener('change', () => {
        handleImageUpload(imageUpload.files);
        // Reset the input so the same file can be selected again
        imageUpload.value = '';
    });
    
    // Memory tags input
    addMemoryTagBtn.addEventListener('click', () => {
        const tagText = memoryTags.value.trim();
        if (tagText) {
            addMemoryTagToPreview(tagText);
            memoryTags.value = '';
            memoryTags.focus();
        }
    });
    
    memoryTags.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            const tagText = memoryTags.value.trim();
            if (tagText) {
                addMemoryTagToPreview(tagText);
                memoryTags.value = '';
            }
        }
    });
    
    // Tags input
    addTagBtn.addEventListener('click', () => {
        const tagText = noteTags.value.trim();
        if (tagText) {
            addTagToPreview(tagText);
            noteTags.value = '';
            noteTags.focus();
        }
    });
    
    noteTags.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            const tagText = noteTags.value.trim();
            if (tagText) {
                addTagToPreview(tagText);
                noteTags.value = '';
            }
        }
    });
    
    // Shopping List modal buttons
    closeShoppingListBtn.addEventListener('click', closeShoppingList);
    addItemBtn.addEventListener('click', addShoppingItem);
    clearItemsBtn.addEventListener('click', clearShoppingItems);
    saveListBtn.addEventListener('click', saveShoppingList);
    
    itemName.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            addShoppingItem();
        }
    });
    
    // Initialize drawer items
    homeItem.addEventListener('click', () => {
        currentFilter = 'all';
        renderNotes();
        toggleDrawer();
    });
    
    favoritesItem.addEventListener('click', () => {
        currentFilter = 'favorites';
        renderNotes();
        toggleDrawer();
    });
    
    shoppingListItem.addEventListener('click', () => {
        toggleDrawer();
        showShoppingList();
    });
    
    tagsItem.addEventListener('click', () => {
        toggleDrawer();
        showSnackbar('Tags feature is coming soon!');
    });
    
    themesItem.addEventListener('click', () => {
        toggleDrawer();
        showSnackbar('Themes feature is coming soon!');
    });
    
    settingsItem.addEventListener('click', () => {
        toggleDrawer();
        showSnackbar('Settings feature is coming soon!');
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