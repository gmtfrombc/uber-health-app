#!/bin/bash

# Setup OpenAI API key for Firebase Functions emulator
echo "Please enter your OpenAI API key (it will NOT be displayed as you type):"
read -s OPENAI_API_KEY
echo ""

if [ -z "$OPENAI_API_KEY" ]; then
  echo "Error: No API key provided. Exiting."
  exit 1
fi

# Update the .env.local file with the API key
cd functions
sed -i '' "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=$OPENAI_API_KEY/" .env.local
echo "OpenAI API key securely saved to .env.local"

# Start Firebase emulators in the background
echo "Starting Firebase emulators..."
(firebase emulators:start --env-file=.env.local) &
EMULATOR_PID=$!

# Wait for emulators to start
echo "Waiting for emulators to start (10 seconds)..."
sleep 10

# Change back to project root directory
cd ..

# Start Flutter app
echo "Starting Flutter app..."
flutter run

# Cleanup when Flutter app is closed
kill $EMULATOR_PID
echo "Dev environment stopped."
