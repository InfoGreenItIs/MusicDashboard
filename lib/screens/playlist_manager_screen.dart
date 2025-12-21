import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../models/playlist_models.dart';
import '../services/spotify_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistManagerScreen extends StatefulWidget {
  const PlaylistManagerScreen({super.key});

  @override
  State<PlaylistManagerScreen> createState() => _PlaylistManagerScreenState();
}

class _PlaylistManagerScreenState extends State<PlaylistManagerScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  String? _selectedFolder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Panel: Folders
                  Expanded(flex: 1, child: _buildFolderList()),
                  const SizedBox(width: 24),
                  // Right Panel: Playlists
                  Expanded(flex: 2, child: _buildPlaylistList()),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Playlist Manager',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showAddFolderDialog(),
              icon: const Icon(Icons.create_new_folder),
              label: const Text('New Folder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondary.withOpacity(0.2),
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh logic if needed
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Folders',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('qr_playlists')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: SelectableText(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final folderName = doc.id;
                        final isSelected = folderName == _selectedFolder;

                        return ListTile(
                          title: Text(
                            folderName,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.white,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          onTap: () {
                            setState(() {
                              _selectedFolder = folderName;
                            });
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white30,
                                ),
                                onPressed: () =>
                                    _showRenameFolderDialog(folderName),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.white30,
                                ),
                                onPressed: () =>
                                    _confirmDeleteFolder(folderName),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistList() {
    if (_selectedFolder == null) {
      return Center(
        child: Text(
          'Select a folder to view playlists',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Playlists in "$_selectedFolder"',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddPlaylistDialog,
                      icon: const Icon(Icons.add_link),
                      label: const Text('Add Playlist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('qr_playlists')
                      .doc(_selectedFolder)
                      .collection('playlists')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: SelectableText(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No playlists in this folder.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final playlist = PlaylistModel.fromSnapshot(doc);

                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ExpansionTile(
                            leading: playlist.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      playlist.imageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  ),
                            title: Text(
                              playlist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${playlist.trackCount} tracks • By ${playlist.owner}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deletePlaylist(playlist.id),
                            ),
                            children: [
                              if (playlist.spotifyUrl != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => launchUrl(
                                        Uri.parse(playlist.spotifyUrl!),
                                      ),
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                      ),
                                      label: const Text('Open in Spotify'),
                                    ),
                                  ),
                                ),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: playlist.tracks.length,
                                  itemBuilder: (context, i) {
                                    final track = playlist.tracks[i];
                                    return ListTile(
                                      visualDensity: VisualDensity.compact,
                                      leading: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                        ),
                                      ),
                                      title: Text(
                                        track['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        track['artist'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddFolderDialog() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('New Folder', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Folder Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _spotifyService.createFolder(controller.text.trim());
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameFolderDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    bool isLoading = false; // Internal loading state for the dialog if needed

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            title: const Text(
              'Rename Folder',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'New Folder Name'),
            ),
            actions: [
              if (!isLoading)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              if (!isLoading)
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.trim().isEmpty ||
                        controller.text.trim() == currentName) {
                      Navigator.pop(dialogContext);
                      return;
                    }

                    setDialogState(() => isLoading = true);
                    try {
                      await _spotifyService.renameFolder(
                        currentName,
                        controller.text.trim(),
                      );

                      // If the renamed folder was currently selected, update the selection
                      if (_selectedFolder == currentName) {
                        setState(() {
                          _selectedFolder = controller.text.trim();
                        });
                      }

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Folder renamed successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Rename'),
                ),
              if (isLoading) const CircularProgressIndicator(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteFolder(String folderName) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Delete Folder?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will delete "$folderName" and ALL playlists inside it.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _spotifyService.deleteFolder(folderName);
              if (_selectedFolder == folderName) {
                setState(() => _selectedFolder = null);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPlaylistDialog() async {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            title: const Text(
              'Add Playlist',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Spotify URL or ID',
                    hintText: 'https://open.spotify.com/playlist/...',
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const Text(
                    'Fetching data...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
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
                  onPressed: () async {
                    if (controller.text.isEmpty) return;
                    setDialogState(() => isLoading = true);

                    try {
                      await _spotifyService.addPlaylist(
                        controller.text.trim(),
                        _selectedFolder!,
                      );
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playlist added successfully'),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Fetch & Add'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deletePlaylist(String playlistId) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Delete Playlist?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this playlist?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await _spotifyService.deletePlaylist(
                _selectedFolder!,
                playlistId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
