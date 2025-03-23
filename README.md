# Uber Health App

A Flutter application that provides a conversational healthcare interface using Firebase Functions and OpenAI.

## Development Environment Setup

This project has two workflow options:

### Option 1: Local Development Workflow (Recommended for Development)

This setup uses Firebase Emulators to allow local development without affecting production.

#### Prerequisites:
- Flutter SDK installed
- Firebase CLI installed
- Node.js 20 or higher
- OpenJDK 17 for Firebase Emulators
- OpenAI API key

#### Setup Steps:

1. Clone the repository
   ```
   git clone <repository-url>
   cd uber_health_app_stable
   ```

2. Switch to the development branch
   ```
   git checkout dev-environment
   ```

3. Start the development environment:
   ```
   ./dev_start_all.sh
   ```
   This script will:
   - Prompt for your OpenAI API key (which is securely stored in `.env.local`)
   - Start the Firebase emulators
   - Start the Flutter app

   Alternatively, you can:
   - Run `./dev_start.sh` to just start the Firebase emulators
   - Then in a separate terminal, run `./run_flutter.sh` to start the Flutter app

### Option 2: Production Workflow

For production deployment, the app uses Firebase Functions with secrets.

#### Setup Steps:

1. Switch to the production branch
   ```
   git checkout firebase_functions
   ```

2. Configure Firebase:
   ```
   firebase login
   firebase functions:secrets:set OPENAI_KEY
   ```

3. Deploy Firebase Functions:
   ```
   cd functions
   npm run deploy
   ```

4. Run Flutter app:
   ```
   flutter run
   ```

## Architecture

- **Flutter App**: Front-end mobile application for iOS/Android
- **Firebase Functions**: Backend API that securely communicates with OpenAI
- **OpenAI API**: Provides AI-powered chat capabilities for medical triage

## Important Note

The OpenAI API key is handled differently in each workflow:
- In local development, it's stored in a `.env.local` file (not committed to Git)
- In production, it's stored as a Firebase Secret

Never commit API keys to the Git repository.

## Security Note

### Firebase Configuration

This project uses Firebase and requires configuration with API keys. For security reasons:

1. **NEVER commit `firebase_options.dart` to public repositories**
2. Use the provided `firebase_options_template.dart` as a reference
3. Copy the template to `firebase_options.dart` and replace placeholder values with your actual Firebase configuration

### Setting Up Firebase Configuration Securely

If you've cloned this repository:

1. Copy `lib/firebase_options_template.dart` to `lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase configuration
3. Make sure `lib/firebase_options.dart` is in `.gitignore` to prevent accidentally committing it

### API Key Security

For Firebase and other API keys:

1. Regenerate keys if they have been exposed
2. Add API key restrictions in the Google Cloud Console
3. For web applications, consider setting up API restrictions based on HTTP referrers
4. For mobile applications, consider using Firebase App Check to add an additional layer of security

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
