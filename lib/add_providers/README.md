# Firebase Providers Setup

This directory contains utilities for setting up providers in Firebase Firestore.

## Adding Providers to Firebase

1. Generate a Firebase service account key:
   - Go to Firebase Console > Project Settings > Service Accounts
   - Click "Generate new private key"
   - Save the JSON file as `serviceAccountKey.json` in this directory (DO NOT COMMIT THIS FILE)

2. Modify the `add-providers-clean.js` script:
   - Uncomment the Firebase initialization code
   - Uncomment the provider creation function
   - Customize the provider data if needed

3. Install dependencies:
   ```
   npm install firebase-admin
   ```

4. Run the script:
   ```
   node add-providers-clean.js
   ```

5. The script will output the IDs of the created provider documents. Store these IDs safely as they will be used in the app.

## Security

- Never commit your Firebase service account key to version control
- After using the key, consider revoking it and generating a new one for production
- The `.gitignore` file is set up to prevent accidental commits of key files 