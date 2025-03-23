#!/bin/bash

cd functions

echo "Building Firebase Functions..."
npm run build

echo "Functions built successfully! You can now run your Flutter app."
echo "To run your Flutter app, use: flutter run"
cd ..
