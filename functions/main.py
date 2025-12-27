from firebase_functions import https_fn, options, logger
from firebase_admin import initialize_app, firestore
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import os
import json
import time

initialize_app()
db = firestore.client()

def get_spotify_client():
    client_id = os.environ.get("SPOTIPY_CLIENT_ID")
    client_secret = os.environ.get("SPOTIPY_CLIENT_SECRET")
    if not client_id or not client_secret:
        raise ValueError("SPOTIPY_CLIENT_ID and SPOTIPY_CLIENT_SECRET must be set as environment variables.")
    
    auth_manager = SpotifyClientCredentials(client_id=client_id, client_secret=client_secret)
    return spotipy.Spotify(auth_manager=auth_manager)

def fetch_playlist_data(sp, playlist_id):
    """Fetches track data from a Spotify playlist."""
    try:
        playlist = sp.playlist(playlist_id)
        tracks = []
        results = sp.playlist_tracks(playlist_id)
        while results:
            for item in results['items']:
                track = item['track']
                if track and track['album']:
                    track_image_url = track['album']['images'][0]['url'] if track['album']['images'] else None
                    tracks.append({
                        'id': track['id'],
                        'name': track['name'],
                        'artist': ", ".join([artist['name'] for artist in track['artists']]),
                        'album': track['album']['name'],
                        'release_date': track['album']['release_date'],
                        'duration_ms': track['duration_ms'],
                        'popularity': track['popularity'],
                        'external_url': track['external_urls']['spotify'],
                        'image_url': track_image_url
                    })
            results = sp.next(results) if results['next'] else None
        
        playlist_image_url = playlist['images'][0]['url'] if playlist['images'] else None
        return {
            'id': playlist['id'],
            'name': playlist['name'],
            'description': playlist['description'],
            'owner': playlist['owner']['display_name'],
            'image_url': playlist_image_url,
            'tracks': tracks
        }
    except Exception as e:
        raise RuntimeError(f"Error fetching playlist data: {e}")

@https_fn.on_call(region="europe-west4", cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]))
def add_playlist(req: https_fn.CallableRequest):
    """
    Adds a playlist to Firestore.
    Expects data: { "playlist_id": "...", "folder_name": "..." }
    """
    if not req.auth:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="The user must be authenticated.")

    try:
        playlist_id = req.data.get('playlist_id')
        folder_name = req.data.get('folder_name')

        if not playlist_id or not folder_name:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT, message="Missing playlist_id or folder_name")

        sp = get_spotify_client()
        logger.info(f"Fetching data for playlist {playlist_id} to add to folder {folder_name}")
        playlist_data = fetch_playlist_data(sp, playlist_id)

        # Add default order using timestamp (milliseconds) to ensure it appears at the end
        playlist_data['order'] = int(time.time() * 1000)

        # Store in Firestore
        folder_doc_ref = db.collection("qr_playlists").document(folder_name)
        playlist_doc_ref = folder_doc_ref.collection("playlists").document(playlist_data['id'])
        playlist_doc_ref.set(playlist_data)
        
        # Update folder timestamp
        folder_doc_ref.set({'name': folder_name, 'last_updated': firestore.SERVER_TIMESTAMP}, merge=True)

        logger.info(f"Successfully added playlist {playlist_data['name']} to {folder_name}")
        return f"Playlist '{playlist_data['name']}' stored in folder '{folder_name}'."

    except ValueError as e:
         logger.error(f"ValueError in add_playlist: {e}")
         raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=str(e))
    except Exception as e:
         logger.error(f"Error in add_playlist: {e}")
         raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=f"Error: {str(e)}")

@https_fn.on_call(region="europe-west4", cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]))
def update_all_folders(req: https_fn.CallableRequest):
    """
    Refreshes all playlists in Firestore.
    """
    if not req.auth:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="The user must be authenticated.")

    try:
        sp = get_spotify_client()
        logger.info("Starting update of all folders...")
        folders = db.collection("qr_playlists").stream()
        
        updated_count = 0
        errors = []

        for folder in folders:
            folder_name = folder.id
            playlists = db.collection("qr_playlists").document(folder_name).collection("playlists").stream()
            
            for playlist_doc in playlists:
                playlist_data = playlist_doc.to_dict()
                pid = playlist_data.get('id')
                
                if pid:
                    try:
                        new_data = fetch_playlist_data(sp, pid)
                        # Store updated data, use merge=True to preserve 'order' field
                        db.collection("qr_playlists").document(folder_name).collection("playlists").document(pid).set(new_data, merge=True)
                        updated_count += 1

                    except Exception as e:
                        error_msg = f"Error updating playlist {pid} in {folder_name}: {str(e)}"
                        logger.error(error_msg)
                        errors.append(error_msg)
        
        response_msg = f"Updated {updated_count} playlists."
        if errors:
            response_msg += f" Errors: {'; '.join(errors)}"
            
        return response_msg

    except Exception as e:
        logger.error(f"Fatal error in update_all_folders: {e}")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=f"Error: {str(e)}")

@https_fn.on_call(region="europe-west4", cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]))
def search_playlists(req: https_fn.CallableRequest):
    """
    Search for playlists on Spotify.
    Expects data: { "q": "search term", "limit": 10 }
    """
    if not req.auth:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="The user must be authenticated.")

    try:
        query = req.data.get('q')
        limit = req.data.get('limit', 10)
        
        if not query:
             raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT, message="Missing query parameter 'q'")

        sp = get_spotify_client()
        logger.info(f"Searching playlists for query: '{query}' with limit {limit}")
        results = sp.search(q=query, type='playlist', limit=int(limit))
        
        items = results['playlists']['items']
        simplified_items = []
        for p in items:
            if p:
                simplified_items.append({
                    'id': p['id'],
                    'name': p['name'],
                    'owner': p['owner']['display_name'],
                    'tracks_total': p['tracks']['total'],
                    'image_url': p['images'][0]['url'] if p['images'] else None,
                    'external_url': p['external_urls']['spotify']
                })

        return simplified_items

    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=f"Error: {str(e)}")

