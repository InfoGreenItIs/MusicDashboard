import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistFolder {
  final String name;
  final Timestamp? createdAt;

  PlaylistFolder({required this.name, this.createdAt});

  factory PlaylistFolder.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaylistFolder(
      name: data['name'] ?? doc.id,
      createdAt: data['created_at'],
    );
  }
}

class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final String owner;
  final String? imageUrl;
  final String? spotifyUrl;
  final int trackCount;
  final List<dynamic> tracks;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.description,
    required this.owner,
    this.imageUrl,
    this.spotifyUrl,
    required this.tracks,
    this.trackCount = 0,
  });

  factory PlaylistModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tracksList = data['tracks'] as List<dynamic>? ?? [];
    return PlaylistModel(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? 'Unknown',
      description: data['description'] ?? '',
      owner: data['owner'] ?? 'Unknown',
      imageUrl: data['image_url'],
      spotifyUrl: data['external_urls'] != null
          ? data['external_urls']['spotify']
          : null,
      tracks: tracksList,
      trackCount: tracksList.length,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner': owner,
      'image_url': imageUrl,
      'tracks': tracks,
      'external_urls': {'spotify': spotifyUrl},
    };
  }
}
