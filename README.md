# Music Dashboard

A premium Flutter Web application for managing Spotify playlists and QR-based music collections. Features a modern dark interface with glassmorphism effects and Firebase backend integration.

## 🌟 Features

### Authentication & Access Control
- **Firebase Authentication**: Secure Google Sign-In integration
- **User Access Control**: Firestore-based allow-list for authorized administrators
- **User Admin Screen**: CRUD interface for managing user permissions

### Playlist Management
- **Folder & Playlist Organization**: Hierarchical structure for managing music collections
- **Drag-and-Drop Reordering**: Intuitive interface for organizing folders and playlists
- **Spotify Integration**: Cloud Functions-based Spotify API integration
- **Folder Operations**: Create, rename, and delete folders with confirmation dialogs
- **Persistent Ordering**: Custom order field stored in Firestore with composite indexes

### UI/UX
- **Deep Dark Theme**: Custom `Color(0xFF0F111A)` base styling
- **Glassmorphism**: Sidebar and UI elements with real-time blur effects
- **Google Fonts**: Professional typography using the Google Fonts package
- **Responsive Design**: Optimized for web deployment
- **Modern Interactions**: Smooth animations and hover effects

## 🏗️ Architecture

### Frontend (Flutter Web)
- **Framework**: Flutter 3.10+
- **Rendering**: CanvasKit/Wasm for optimal web performance
- **State Management**: StreamBuilder with Firestore real-time updates
- **Services**: 
  - `QrPlaylistsService`: Manages playlists and folders
  - `SpotifyService`: Handles Spotify API interactions via Cloud Functions

### Backend (Firebase)
- **Firebase Authentication**: User authentication and session management
- **Cloud Firestore**: Real-time database for playlists, folders, and user data
  - Composite indexes for efficient ordering queries
  - Security rules for user access control
- **Cloud Functions (Python 3.11)**: 
  - Spotify API integration
  - Playlist synchronization
  - Folder management operations

## 🚀 Deployment

### Hosting
- **Site URL**: [aimusicquiz2-dashboard.web.app](https://aimusicquiz2-dashboard.web.app)
- **Platform**: Firebase Hosting
- **Build Directory**: `build/web`

### Latest Deployment
- **Date**: December 21, 2025 at 19:11:44 +0100
- **Commit**: `feat: deploy dashboard to separate hosting site`

### Deploy Commands
```bash
# Build Flutter web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Firestore rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

## 📦 Dependencies

### Main Dependencies
- `flutter`: SDK
- `firebase_auth`: ^6.1.3
- `firebase_core`: ^4.3.0
- `cloud_firestore`: ^6.1.1
- `cloud_functions`: ^6.0.5
- `google_sign_in`: ^6.2.1
- `google_fonts`: ^6.3.3
- `spotify`: ^0.15.0
- `url_launcher`: ^6.3.2
- `intl`: ^0.20.2

### Dev Dependencies
- `flutter_test`: SDK
- `flutter_lints`: ^6.0.0

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK 3.10+
- Dart SDK ^3.10.0
- Firebase CLI
- Node.js (for Firebase Functions)
- Python 3.11 (for Cloud Functions)

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd MusicDashboard

# Install Flutter dependencies
flutter pub get

# Set up Firebase
firebase login
flutterfire configure

# Install Cloud Functions dependencies
cd functions
pip install -r requirements.txt
```

### Environment Setup
1. Create `functions/.env` file based on `functions/.env.example`
2. Add Spotify API credentials
3. Configure Firebase project settings

### Running Locally
```bash
# Run in debug mode
flutter run -d chrome

# Run with hot reload
flutter run -d chrome --web-renderer canvaskit

# Build for production
flutter build web --release
```

## 📁 Project Structure

```
MusicDashboard/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase configuration
│   ├── models/                      # Data models
│   ├── screens/                     # UI screens
│   │   ├── login_screen.dart
│   │   ├── playlist_manager_screen.dart
│   │   └── user_admin_screen.dart
│   └── services/                    # Business logic
│       └── qr_playlists_service.dart
├── functions/                       # Cloud Functions (Python)
│   ├── main.py
│   ├── requirements.txt
│   └── .env.example
├── web/                            # Web-specific files
├── build/                          # Build output
├── firebase.json                   # Firebase configuration
├── firestore.rules                 # Security rules
├── firestore.indexes.json          # Database indexes
└── pubspec.yaml                    # Flutter dependencies
```

## 🔐 Security

- Firestore security rules enforce user-based access control
- Only authorized users (stored in Firestore `users` collection) can access the dashboard
- Cloud Functions handle sensitive Spotify API operations server-side
- Environment variables for API keys and secrets

## 📝 Recent Updates

- ✅ Added playlist rename functionality
- ✅ Refined responsive layout for mobile/desktop
- ✅ Improved UI aesthetics (standardized fonts, consistent icons)
- ✅ Deployed dashboard to separate hosting site
- ✅ Added drag-and-drop reordering for folders and playlists
- ✅ Implemented folder rename functionality
- ✅ Added Firestore composite indexes for ordering queries
- ✅ Migrated Spotify integration to Cloud Functions
- ✅ Implemented user admin CRUD screen
- ✅ Added Firestore-based user access control
- ✅ Migrated Cloud Functions to europe-west4 region

## 🐛 Known Issues

None currently reported. See git history for resolved issues.

## 📄 License

Private project - not published to pub.dev

## 👤 Author

**DennisVanMaren**  
Email: info@greenitis.nl

---

**Project ID**: aimusicquiz2  
**Firebase Project**: aimusicquiz2  
**Web App ID**: 1:485741145479:web:1c18713e6230d8d8ebb722
