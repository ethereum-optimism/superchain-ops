#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <directory_path>"
  exit 1
fi

eth_address_regex="^0x[a-fA-F0-9]{40}$"
temp_file=$(mktemp)

echo "0" > "$temp_file"

convert_to_raw_github_url() {
  if [[ "$1" =~ ^https://github.com/([^/]+)/([^/]+)/blob/(.*)#L([0-9]+)$ ]]; then
    echo "https://raw.githubusercontent.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/${BASH_REMATCH[3]}"
  else
    echo "$1"
  fi
}

find "$1" -name "VALIDATION.md" -type f | while read -r file; do
  echo "Processing: $file"
  echo "================="
  
  content=$(cat "$file")
  
  echo "$content" | sed -n 's/.*<a [^>]*href="\([^"]*\)".*>\(.*\)<\/a>.*/\1 \2/p' | while read -r href content; do
    if [[ "$content" =~ $eth_address_regex ]]; then
      raw_url=$(convert_to_raw_github_url "$href")
      
      echo "A content: $content"
      
      github_line_number=""
      if [[ "$href" =~ \#L([0-9]+) ]]; then
        github_line_number="${BASH_REMATCH[1]}"
      fi

      if [ -n "$github_line_number" ]; then
        line_content=$(curl -s "$raw_url" | sed -n "${github_line_number}p")
        echo "Content at Line $github_line_number: $line_content"
        
        if [[ "$(echo "$line_content" | tr '[:upper:]' '[:lower:]')" =~ $(echo "$content" | tr '[:upper:]' '[:lower:]') ]]; then
          echo "✅ Success: Ethereum address found on this line!"
        else
          echo "⛔ Failure: Ethereum address not found on this line."
          failures=$(($(cat "$temp_file") + 1))
          echo "$failures" > "$temp_file"
          validation_line=$(grep -n "$href" "$file" | cut -d: -f1)
          validation_content=$(sed -n "${validation_line}p" "$file")
          {
            echo "File: $file (line $validation_line)"
            echo "Validation line: $validation_content"
            echo "Target URL: $href"
            echo "Expected address: $content"
            echo "Found content: $line_content"
            echo "---"
          } >> "$temp_file.failures"
        fi
      fi
      
      echo "------------------------"
    fi
  done
  
  echo -e "\n"
done

failures=$(cat "$temp_file")

if [ "$failures" -gt 0 ]; then
  echo "======================="
  echo "Failed Validations Summary:"
  echo "======================="
  cat "$temp_file.failures"
  echo "======================="
  echo "Found $failures validation failure(s)"
  rm "$temp_file" "$temp_file.failures"
  exit 1
else
  echo "All validations passed successfully"
  rm "$temp_file"
  exit 0
fi
