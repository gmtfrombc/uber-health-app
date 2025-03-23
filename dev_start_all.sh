#!/bin/bash

cd functions

# Function to read password with asterisk feedback
read_secret() {
  # Clear any previous input
  unset OPENAI_API_KEY
  # Set local variable to store the key
  local key=""
  local char=""
  
  # Display prompt message
  echo "Please enter your OpenAI API key (asterisks will be shown as you type):"
  
  # Read characters one at a time
  while IFS= read -r -s -n1 char; do
    # If user presses enter, break the loop
    if [[ $char == $'\0' ]] || [[ $char == $'\n' ]]; then
      echo
      break
    fi
    
    # If backspace or delete is pressed
    if [[ $char == $'\177' ]] || [[ $char == $'\b' ]]; then
      if [ -n "$key" ]; then
        # Remove last character
        key="${key%?}"
        # Move cursor back and erase
        echo -en "\b \b"
      fi
    else
      # Add character to password
      key+="$char"
      # Print asterisk
      echo -n "*"
    fi
  done
  
  # Set the global variable
  OPENAI_API_KEY=$key
}

# Check if API key already exists and isn't the placeholder
if grep -q "OPENAI_API_KEY=replace_with_your_key" .env.local || ! grep -q "OPENAI_API_KEY=" .env.local; then
  # API key not set or is placeholder, prompt for it
  read_secret

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
