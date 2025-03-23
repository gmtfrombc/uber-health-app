# Uber Health App

A Flutter healthcare application that allows patients to connect with healthcare providers.

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
