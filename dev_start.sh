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
  # Extract API key from .env.local for use in this session
  OPENAI_API_KEY=$(grep "OPENAI_API_KEY=" .env.local | cut -d= -f2)
  echo "Using existing OpenAI API key from .env.local"
fi

echo "Building Firebase Functions..."
npm run build

echo "Functions built successfully! You can now run your Flutter app."
echo "To run your Flutter app, use: flutter run"
cd ..
