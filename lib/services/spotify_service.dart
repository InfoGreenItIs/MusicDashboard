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
}
