# Feature Request: Implement Custom Playlist Ordering in Game Client

## Objective
Update the Game Client application to respect the custom drag-and-drop order defined in the Admin Dashboard for both **Folders** and **Playlists**.

## Technical Context
The Admin Dashboard now writes an `order` field (integer/timestamp) to documents in Firestore.
- **Collection**: `qr_playlists` (Folders)
- **Sub-collection**: `qr_playlists/{folderId}/playlists` (Playlists)

## Requirements

1.  **Update Folder Fetching Logic**:
    - Modify the query that fetches the list of folders (categories).
    - **Current**: Likely sorts by `name` or has no specific sort.
    - **New**: Must sort by `order` (Ascending) primarily, and `name` (Ascending) secondarily as a fallback.
    - **Query**: `.orderBy('order').orderBy('name')`

2.  **Update Playlist Fetching Logic**:
    - Modify the query that fetches playlists within a selected folder.
    - **Current**: Likely sorts by `name`.
    - **New**: Must sort by `order` (Ascending).
    - **Query**: `.orderBy('order')`

3.  **Verify UI**:
    - Ensure the list of categories/folders in the game app matches the order shown in the Admin Dashboard.
    - Ensure the list of playlists inside a category matches the order shown in the Admin Dashboard.

## Dependencies
- Ensure the `firestore.indexes.json` is deployed (it already is) to support the composite sorting if needed.
