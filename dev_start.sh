#!/bin/bash

# Setup OpenAI API key for Firebase Functions emulator
echo "Please enter your OpenAI API key:"
read -s OPENAI_API_KEY
echo "OpenAI API key set for the current session."

cd functions
export OPENAI_API_KEY

# Start Firebase emulators
echo "Starting Firebase emulators..."
firebase emulators:start

# Note: To run the Flutter app, open a new terminal and run:
# flutter run
