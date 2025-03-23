#!/bin/bash

cd functions

# Check if API key already exists and isn't the placeholder
if grep -q "OPENAI_API_KEY=replace_with_your_key" .env.local || ! grep -q "OPENAI_API_KEY=" .env.local; then
  # API key not set or is placeholder, prompt for it
  echo "Please enter your OpenAI API key (it will NOT be displayed as you type):"
  read -s OPENAI_API_KEY
  echo ""

  if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: No API key provided. Exiting."
    exit 1
  fi

  # Update the .env.local file with the API key
  sed -i '' "s/OPENAI_API_KEY=.*/OPENAI_API_KEY=$OPENAI_API_KEY/" .env.local
  echo "OpenAI API key securely saved to .env.local"
else
  echo "Using existing OpenAI API key from .env.local"
fi

# Start Firebase emulators
echo "Starting Firebase emulators..."
firebase emulators:start --env-file=.env.local

# Note: To run the Flutter app, open a new terminal and run:
# flutter run
