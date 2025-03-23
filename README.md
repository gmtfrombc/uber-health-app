# Uber Health App

A Flutter application that provides a conversational healthcare interface using Firebase Functions and OpenAI.

## Development Environment Setup

### Production Development Workflow

This setup connects directly to your production Firebase project, using your cloud-stored API key.

#### Prerequisites:
- Flutter SDK installed
- Firebase CLI installed
- Node.js 20 or higher
- OpenAI API key stored as a Firebase Secret

#### Setup Steps:

1. Clone the repository
   ```
   git clone <repository-url>
   cd uber_health_app_stable
   ```

2. Switch to the development branch
   ```
   git checkout production-dev
   ```

3. Start the development environment:
   ```
   ./dev_start_all.sh
   ```
   This script will:
   - Build the Firebase Functions
   - Start the Flutter app

   Alternatively, you can:
   - Run `./dev_start.sh` to just build the Firebase Functions
   - Then in a separate terminal, run `./run_flutter.sh` to start the Flutter app

## Architecture

- **Flutter App**: Front-end mobile application for iOS/Android
- **Firebase Functions**: Backend API that securely communicates with OpenAI
- **OpenAI API**: Provides AI-powered chat capabilities for medical triage

## Security Considerations

### API Key Security
- The OpenAI API key is securely stored as a Firebase Secret
- Never commit API keys to Git repositories
- Regenerate keys if they have been exposed
- Add API key restrictions in the Google Cloud Console

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
