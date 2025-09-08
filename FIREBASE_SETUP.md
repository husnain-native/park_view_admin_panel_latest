# Firebase Setup for Admin Panel

## Overview
This admin panel now includes Cloud Functions to fetch all Firebase Auth users and display them in the admin interface.

## Setup Instructions

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Initialize Firebase Functions
Navigate to the admin panel directory and run:
```bash
cd park_view_admin_panel
firebase init functions
```

### 4. Deploy Cloud Functions
```bash
firebase deploy --only functions
```

### 5. Update Flutter Dependencies
Run in the admin panel directory:
```bash
flutter pub get
```

## How It Works

### Cloud Functions Created:
1. **getAllUsers** - Fetches all Firebase Auth users
2. **syncAllUsersToFirestore** - Syncs all Firebase Auth users to Firestore

### Admin Panel Features:
- **Blue Theme**: Admin panel uses blue as the primary color
- **Real User Data**: Shows actual users from Firebase Auth console
- **Sync Button**: Manually sync all Firebase Auth users to Firestore
- **Search**: Search users by email or name
- **User Management**: View, edit, and delete users

## Usage

1. **Deploy Cloud Functions** (one-time setup)
2. **Sign in as Admin** in the admin panel
3. **Click the Sync Button** to fetch all Firebase Auth users
4. **View all users** from your Firebase Auth console

## Security
- Only authenticated admin users can access the Cloud Functions
- Admin verification is done through Firestore `admins` collection
- All operations are logged and secured

## Troubleshooting

### If Cloud Functions fail to deploy:
1. Check Firebase project configuration
2. Ensure you have billing enabled (required for Cloud Functions)
3. Verify Node.js version (18+ recommended)

### If users don't appear:
1. Make sure Cloud Functions are deployed
2. Check admin authentication
3. Verify Firestore rules allow admin access

## Files Modified:
- `functions/index.js` - Cloud Functions implementation
- `functions/package.json` - Dependencies
- `lib/services/admin_service.dart` - Admin service with Cloud Function calls
- `lib/screens/users_screen.dart` - Updated UI with sync functionality
- `pubspec.yaml` - Added cloud_functions dependency
