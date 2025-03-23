#!/bin/bash

# Build functions
cd functions
echo "Building Firebase Functions..."
npm run build
echo "Functions built successfully!"

# Go back to the project root
cd ..

# Start Flutter app
echo "Starting Flutter app..."
flutter run
