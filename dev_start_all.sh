#!/bin/bash

# Setup OpenAI API key for Firebase Functions emulator
echo "Please enter your OpenAI API key:"
read -s OPENAI_API_KEY
echo "OpenAI API key set for the current session."

# Start Firebase emulators in the background
echo "Starting Firebase emulators..."
(cd functions && export OPENAI_API_KEY="$OPENAI_API_KEY" && firebase emulators:start) &
EMULATOR_PID=$!

# Wait for emulators to start
echo "Waiting for emulators to start (10 seconds)..."
sleep 10

# Start Flutter app
echo "Starting Flutter app..."
flutter run

# Cleanup when Flutter app is closed
kill $EMULATOR_PID
echo "Dev environment stopped."
