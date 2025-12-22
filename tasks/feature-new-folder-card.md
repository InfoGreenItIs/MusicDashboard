# Feature: Add "New Folder" Card in Folder List

**Status**: Done  
**Priority**: Medium  
**Created**: 2025-12-22  
**Updated**: 2025-12-22  
**Assignee**: Dennis van Maren

## Description

Add a "New Folder" card/tile at the top of the folder list, similar to how the playlist section has an "Add Playlist" button. This provides a more intuitive way to create folders directly from the folder list view, rather than only having the button in the header.

## Acceptance Criteria

- [x] Add a "New Folder" card as the first item in the folder list
- [x] Card should have a distinct visual style (e.g., dashed border, add icon)
- [x] Clicking the card opens the "New Folder" dialog
- [x] Card should be positioned above existing folders
- [x] Visual style should match the app's design system
- [x] **Bonus**: Standardized dialog design with Add Playlist

## Implementation Notes

### Current State
- "New Folder" button is in the header (line 64 in `playlist_manager_screen.dart`)
- Folder list uses `ReorderableListView.builder` (line 140)
- Playlists section has "Add Playlist" button in header (line 265)

### Implemented Solution

**New Folder Card:**
- Added before the existing folder list
- Uses primary color with 0.5 opacity border
- Background with primary color at 0.1 opacity (glassmorphic style)
- Icon: `Icons.add_circle_outline`
- Centered layout with icon + text
- Border radius of 12px matching existing design
- InkWell with border radius for ripple effect

**Dialog Standardization:**
- Updated `_showAddFolderDialog()` to use StatefulBuilder
- Added loading state management
- Includes success/error SnackBar messages
- Added hint text: "My Music Folder"
- Autofocus on TextField for better UX
- Loading indicator during folder creation
- Now matches the Add Playlist dialog design

## Notes / Updates

### 2025-12-22
- Task created to improve UX for folder creation
- Inspired by common file manager patterns (Google Drive, Dropbox, etc.)
- Should provide more intuitive way to create folders
- Consider keeping header button OR replacing it with this card (user preference)
- **✅ Completed**: Added New Folder card and standardized dialog designs
- **Implementation**: Card added at line 118, dialog updated at line 451
- Both changes successfully hot-reloaded in running app

## Implementation Notes

### Current State
- "New Folder" button is in the header (line 64 in `playlist_manager_screen.dart`)
- Folder list uses `ReorderableListView.builder` (line 140)
- Playlists section has "Add Playlist" button in header (line 265)

### Proposed Implementation

**Option 1: Add Card Before ReorderableListView**
```dart
// In _buildFolderList(), modify the Column children:
children: [
  Padding(...), // Existing "Folders" title
  // Add this new card
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: InkWell(
      onTap: _showAddFolderDialog,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'New Folder',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  Expanded(...), // Existing StreamBuilder
]
```

**Option 2: Integrate into ReorderableListView**
- Modify the list to include a "fake" first item that's not reorderable
- More complex but keeps everything in one list

### Design Considerations

**Visual Style Options:**
1. **Dashed border** - Clearly indicates "add new" action
2. **Solid border with opacity** - Matches existing cards better
3. **Icon-first layout** - Large icon with text below
4. **Minimal style** - Just icon and text, no border

**Recommended**: Solid border with primary color and slight opacity background for consistency with the app's glassmorphic design.

### UI Layout

```
┌─────────────────────────────┐
│  Folders                    │
├─────────────────────────────┤
│  ┌───────────────────────┐  │
│  │  +  New Folder        │  │ <- New card
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Folder 1             │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Folder 2             │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

## Related Files

- `lib/screens/playlist_manager_screen.dart` - Modify `_buildFolderList()` method
  - Current "New Folder" button at line 64 (in header)
  - Folder list implementation around lines 93-228
  - Can reuse existing `_showAddFolderDialog()` method (line 451)
  - **Also update**: Standardize `_showAddFolderDialog()` to match `_showAddPlaylistDialog()` design

## Design Consistency: Dialogs

### Current State
**Add Folder Dialog** (line 451):
- Simple AlertDialog
- No loading state
- Basic TextField with label "Folder Name"
- Simple "Cancel" and "Create" buttons

**Add Playlist Dialog** (line 590):
- StatefulBuilder for loading states  
- Loading indicator and "Fetching data..." message
- TextField with labelText AND hintText
- Error handling with SnackBar
- "Cancel" and "Fetch & Add" buttons

### Recommendation: Standardize Both Dialogs

**Update `_showAddFolderDialog()` to match:**
```dart
Future<void> _showAddFolderDialog() async {
  final controller = TextEditingController();
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text(
            'New Folder',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  hintText: 'My Music Folder',
                ),
              ),
            ],
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            if (!isLoading)
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isEmpty) return;
                  setDialogState(() => isLoading = true);
                  
                  try {
                    _spotifyService.createFolder(controller.text.trim());
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Folder created successfully'),
                      ),
                    );
                  } catch (e) {
                    setDialogState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            if (isLoading) const CircularProgressIndicator(),
          ],
        );
      },
    ),
  );
}
```

**Benefits:**
- Consistent user experience across all dialogs
- Better error handling
- Visual feedback during operations
- Prevents accidental dismissal during loading

## Notes / Updates

### 2025-12-22
- Task created to improve UX for folder creation
- Inspired by common file manager patterns (Google Drive, Dropbox, etc.)
- Should provide more intuitive way to create folders
- Consider keeping header button OR replacing it with this card (user preference)

### Design Decision
Keep both the header button AND the card? Or replace header button with card?
- **Recommendation**: Keep both - header button for quick access anywhere, card for visual discoverability
