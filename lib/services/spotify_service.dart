import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SpotifyService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // No longer need client-side initialization for Spotify as it's handled in Cloud Functions

  Future<void> addPlaylist(String playlistIdOrUrl, String folderName) async {
    String playlistId = playlistIdOrUrl;
    if (playlistId.contains('open.spotify.com/playlist/')) {
      playlistId = playlistId.split('playlist/')[1].split('?')[0];
    }

    try {
      await _functions.httpsCallable('add_playlist').call({
        'playlist_id': playlistId,
        'folder_name': folderName,
      });
      // The function returns a success message string
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function Error: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('Error adding playlist: $e');
    }
  }

  Future<void> createFolder(String folderName) async {
    await _firestore.collection('qr_playlists').doc(folderName).set({
      'name': folderName,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> renameFolder(String oldName, String newName) async {
    // 1. Create Data
    final oldDocRef = _firestore.collection('qr_playlists').doc(oldName);
    final newDocRef = _firestore.collection('qr_playlists').doc(newName);

    // Check if new folder already exists to prevent overwrite
    final newDocSnapshot = await newDocRef.get();
    if (newDocSnapshot.exists) {
      throw Exception('Folder "$newName" already exists.');
    }

    // 2. Fetch all playlists from old folder
    final playlistsSnapshot = await oldDocRef.collection('playlists').get();

    // 3. Start Batch
    final batch = _firestore.batch();

    // Create new folder doc
    batch.set(newDocRef, {
      'name': newName,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Move each playlist
    for (var doc in playlistsSnapshot.docs) {
      final newPlaylistRef = newDocRef.collection('playlists').doc(doc.id);
      batch.set(newPlaylistRef, doc.data());
      batch.delete(doc.reference);
    }

    // Delete old folder doc
    batch.delete(oldDocRef);

    // 4. Commit
    await batch.commit();
  }

  Future<void> deleteFolder(String folderName) async {
    // Determine if we should make a cloud function for this to be atomic?
    // For now, client-side batch delete is fine as per original implementation
    final folderRef = _firestore.collection('qr_playlists').doc(folderName);
    final playlists = await folderRef.collection('playlists').get();

    final batch = _firestore.batch();
    for (var doc in playlists.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(folderRef);

    await batch.commit();
  }

  Future<void> deletePlaylist(String folderName, String playlistId) async {
    await _firestore
        .collection('qr_playlists')
        .doc(folderName)
        .collection('playlists')
        .doc(playlistId)
        .delete();
  }

  // Optional: Function to trigger update of all playlists
  Future<void> updateAllPlaylists() async {
    try {
      final result = await _functions
          .httpsCallable('update_all_folders')
          .call();
      print(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function Error: ${e.message}');
    }
  }

  Future<void> reorderFolders(List<String> folderNames) async {
    final batch = _firestore.batch();
    for (int i = 0; i < folderNames.length; i++) {
      final docRef = _firestore.collection('qr_playlists').doc(folderNames[i]);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  Future<void> reorderPlaylists(
    String folderName,
    List<String> playlistIds,
  ) async {
    final batch = _firestore.batch();
    final folderRef = _firestore.collection('qr_playlists').doc(folderName);
    for (int i = 0; i < playlistIds.length; i++) {
      final docRef = folderRef.collection('playlists').doc(playlistIds[i]);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }
}
