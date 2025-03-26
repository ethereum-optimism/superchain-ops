#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

eth_address_regex="^0x[a-fA-F0-9]{40}$"

# Function to convert GitHub URL to raw format
convert_to_raw_github_url() {
  if [[ "$1" =~ ^https://github.com/([^/]+)/([^/]+)/blob/(.*)#L([0-9]+)$ ]]; then
    echo "https://raw.githubusercontent.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}"
  else
    echo "$1"
  fi
}

content=$(cat "$1")

echo "$content" | sed -n 's/.*<a [^>]*href="\([^"]*\)".*>\(.*\)<\/a>.*/\1 \2/p' | while read -r href content; do
  # Check if content matches the Ethereum address pattern
  if [[ "$content" =~ $eth_address_regex ]]; then
    raw_url=$(convert_to_raw_github_url "$href")
    
    echo "A content: $content"
    
    # Extract the line number from the GitHub URL if it exists
    github_line_number=""
    if [[ "$href" =~ \#L([0-9]+) ]]; then
      github_line_number="${BASH_REMATCH[1]}"
    fi

    # Fetch the raw content from GitHub and print the specific line
    if [ -n "$github_line_number" ]; then
      line_content=$(curl -s "$raw_url" | sed -n "${github_line_number}p")
      echo "Content at Line $github_line_number: $line_content"
      
      if [[ "$(echo "$line_content" | tr '[:upper:]' '[:lower:]')" =~ $content | tr '[:upper:]' '[:lower:]' ]]; then
        echo "✅ Success: Ethereum address found on this line!"
      else
        echo "❌ Failure: Ethereum address not found on this line."
      fi
    fi
    
    echo "------------------------"
  fi
done
