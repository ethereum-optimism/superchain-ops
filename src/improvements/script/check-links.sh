#!/bin/bash

# Check if file argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

# Regular expression to match Ethereum address (0x followed by 40 hex characters)
eth_address_regex="^0x[a-fA-F0-9]{40}$"

# Function to convert GitHub URL to raw format
convert_to_raw_github_url() {
  # Check if the URL is a GitHub link
  if [[ "$1" =~ ^https://github.com/([^/]+)/([^/]+)/blob/(.*)#L([0-9]+)$ ]]; then
    echo "https://raw.githubusercontent.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}"
  else
    echo "$1"
  fi
}

# Read the local file
content=$(cat "$1")

# Extract href and content inside <a> tags using sed
echo "$content" | sed -n 's/.*<a [^>]*href="\([^"]*\)".*>\(.*\)<\/a>.*/\1 \2/p' | while read -r href content; do
  # Get the line number where the <a href=""> tag is found in the HTML file
  line_number=$(grep -n -m 1 "<a [^>]*href=\"$href\"" "$1" | cut -d: -f1)
  
  # Check if content matches the Ethereum address pattern
  if [[ "$content" =~ $eth_address_regex ]]; then
    # Check if href is a GitHub URL and convert it to raw URL
    raw_url=$(convert_to_raw_github_url "$href")
    
    # Print the full line with the <a href="..."> tag from the HTML file
    echo "A content: $content"
    
    # Extract the line number from the GitHub URL if it exists
    github_line_number=""
    if [[ "$href" =~ \#L([0-9]+) ]]; then
      github_line_number="${BASH_REMATCH[1]}"
    fi

    # Fetch the raw content from GitHub and print the specific line
    if [ -n "$github_line_number" ]; then
      # Fetch the raw file from GitHub and extract the specific line
      line_content=$(curl -s "$raw_url" | sed -n "${github_line_number}p")
      echo "Content at Line $github_line_number: $line_content"
      
      # Check if the line content contains the Ethereum address and print success or failure
      if [[ "$(echo "$line_content" | tr '[:upper:]' '[:lower:]')" =~ "$(echo "$content" | tr '[:upper:]' '[:lower:]')" ]]; then
        echo "✅ Success: Ethereum address found on this line!"
      else
        echo "❌ Failure: Ethereum address not found on this line."
      fi
    fi
    
    echo "------------------------"
  fi
done
