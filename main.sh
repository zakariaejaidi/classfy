#!/bin/bash

# Classfy - File Organization Script for macOS and Linux
# Searches for files in a directory and subdirectories, 
# classifies them by type, and renames them based on creation date
# Prevents duplication by checking file hashes (SHA-1)
# IMPORTANT: This script moves files to the destination - original files are removed

# Usage: ./main.sh <source_directory> <destination_directory>

# Check if correct number of arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source_directory> <destination_directory>"
    exit 1
fi

SOURCE_DIR="$1"
DEST_DIR="$2"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist."
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Create category directories
mkdir -p "$DEST_DIR/images"
mkdir -p "$DEST_DIR/documents"
mkdir -p "$DEST_DIR/musics"
mkdir -p "$DEST_DIR/videos"
mkdir -p "$DEST_DIR/archives"
mkdir -p "$DEST_DIR/others"

# Create a temporary file to store file hashes
HASH_FILE=$(mktemp)

# Create a temporary file to track duplicate files
DUPLICATE_FILE=$(mktemp)

# Function to get file creation date (compatible with macOS and Linux)
get_creation_date() {
    local file="$1"
    local file_hash="$2"
    local date_str
    
    # Check which OS we're running on
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date_str=$(stat -f "%SB" -t "%Y%m%d-%H%M%S" "$file")
    else
        # Linux - use modification time as creation time is not reliably available
        date_str=$(date -r "$file" +"%Y%m%d-%H%M%S")
    fi
    
    # Use first 4 characters of the file hash
    local hash_prefix=${file_hash:0:4}
    
    # Append hash prefix to the date string
    date_str="${date_str}-${hash_prefix}"
    
    echo "$date_str"
}

# Function to get file hash (compatible with macOS and Linux)
get_file_hash() {
    local file="$1"
    local hash
    
    # Check which command is available
    if command -v shasum &> /dev/null; then
        # macOS typically uses shasum
        hash=$(shasum -a 1 "$file" | cut -d ' ' -f 1)
    elif command -v sha1sum &> /dev/null; then
        # Linux typically uses sha1sum
        hash=$(sha1sum "$file" | cut -d ' ' -f 1)
    else
        echo "Error: No SHA-1 hash command available (shasum or sha1sum)"
        echo "Please install the necessary tools and try again."
        exit 1
    fi
    
    echo "$hash"
}

# Function to process each file
process_file() {
    local file="$1"
    
    # Skip if it's a directory
    if [ -d "$file" ]; then
        return
    fi
    
    # Get file extension and convert to lowercase
    local filename=$(basename "$file")
    local ext="${filename##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    # Generate file hash
    local file_hash=$(get_file_hash "$file")
    
    # Check if file with same hash already processed
    if grep -q "$file_hash" "$HASH_FILE"; then
        echo "Skipping duplicate file: $file (hash: $file_hash)"
        echo "$file" >> "$DUPLICATE_FILE"
        return
    fi
    
    # Add hash to the hash file
    echo "$file_hash" >> "$HASH_FILE"
    
    # Get file creation date with hash prefix
    local creation_date=$(get_creation_date "$file" "$file_hash")
    
    # New filename with date only
    local new_name="${creation_date}.${ext}"
    
    # Determine category based on extension
    local category="others"
    
    case "$ext" in
        # Images
        jpg|jpeg|png|gif|bmp|tiff|svg|webp|heic|raw|cr2|nef)
            category="images"
            ;;
        # Documents
        pdf|doc|docx|xls|xlsx|ppt|pptx|txt|rtf|odt|ods|odp|csv|md|pages|numbers|key)
            category="documents"
            ;;
        # Music
        mp3|wav|flac|aac|ogg|m4a|wma|aiff|alac)
            category="musics"
            ;;
        # Videos
        mp4|avi|mkv|mov|wmv|flv|webm|m4v|3gp|mpeg|mpg)
            category="videos"
            ;;
        # Archives
        zip|rar|7z|tar|gz|bz2|xz|iso|dmg)
            category="archives"
            ;;
        # Code files will be placed in "others" category
        py|js|html|css|java|c|cpp|h|sh|php|rb|go|swift|ts|json|xml|yml|yaml)
            category="others"
            ;;
    esac
    
    # Check if a file with the same name already exists in the destination directory
    local dest_file="$DEST_DIR/$category/$new_name"
    local counter=1
    
    while [ -f "$dest_file" ]; do
        # If file exists with same name but different content, add a counter
        local existing_hash=$(get_file_hash "$dest_file")
        if [ "$existing_hash" = "$file_hash" ]; then
            echo "Skipping duplicate file: $file (already exists as $dest_file)"
            echo "$file" >> "$DUPLICATE_FILE"
            return
        fi
        
        # Add counter to filename
        new_name="${creation_date}_${counter}.${ext}"
        dest_file="$DEST_DIR/$category/$new_name"
        ((counter++))
    done
    
    # Move the file to destination directory (removing the original)
    mv "$file" "$dest_file"
    
    echo "Processed: $file -> $dest_file"
}

# Find all files in source directory and process them
find "$SOURCE_DIR" -type f | while read file; do
    process_file "$file"
done

# Clean up
rm "$HASH_FILE"

# Calculate and display duplicate statistics
DUPLICATE_COUNT=0
if [ -f "$DUPLICATE_FILE" ]; then
    DUPLICATE_COUNT=$(wc -l < "$DUPLICATE_FILE" | tr -d ' ')
    echo -e "\nDuplicate files detected and skipped:"
    if [ "$DUPLICATE_COUNT" -gt 0 ]; then
        echo "------------------------------------------------------------------------------"
        cat "$DUPLICATE_FILE" | sort
        echo "------------------------------------------------------------------------------"
        echo "Total duplicate files skipped: $DUPLICATE_COUNT"
    else
        echo "None"
    fi
    rm "$DUPLICATE_FILE"
fi

echo "File organization complete!"
echo "Total files processed: $(find "$DEST_DIR" -type f | wc -l | tr -d ' ')"
echo "Files organized into the following categories:"
echo "- Images: $(find "$DEST_DIR/images" -type f | wc -l | tr -d ' ')"
echo "- Documents: $(find "$DEST_DIR/documents" -type f | wc -l | tr -d ' ')"
echo "- Music: $(find "$DEST_DIR/musics" -type f | wc -l | tr -d ' ')"
echo "- Videos: $(find "$DEST_DIR/videos" -type f | wc -l | tr -d ' ')"
echo "- Archives: $(find "$DEST_DIR/archives" -type f | wc -l | tr -d ' ')"
echo "- Others: $(find "$DEST_DIR/others" -type f | wc -l | tr -d ' ')"