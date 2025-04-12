# Classfy

A cross-platform Bash script for organizing files by type and preventing duplicates, compatible with both macOS and Linux.

## Features

- **File Classification**: Automatically sorts files into categories (images, documents, music, videos, archives, and others)
- **Cross-Platform**: Works on both macOS and Linux systems
- **Timestamp-Based Naming**: Renames files based on their creation date (format: YYYYMMDD-HHMMSS-HHHH)
- **Hash-Based Suffix**: Uses first 4 characters of the file's SHA-1 hash for unique naming
- **Duplicate Prevention**: Uses SHA-1 file hashing to detect and skip duplicate files

## Requirements

- Bash shell
- Basic file utilities (`find`, `cp`, etc.)
- Hash utility (`shasum`, `sha1sum`, `md5sum`, or `md5`)

## Installation

1. Clone this repository or download the script:
   ```bash
   git clone https://github.com/zakariaejaidi/classfy
   cd classfy
   ```

2. Make the script executable:
   ```bash
   chmod +x main.sh
   ```

## Usage

```bash
./main.sh <source_directory> <destination_directory>
```

### Example

```bash
./main.sh ~/Downloads ~/Organized
```

This will:
1. Scan all files in the `~/Downloads` directory and its subdirectories
2. Move and organize the files into category folders within `~/Organized`
3. Rename each file based on its creation date + hash prefix
4. Skip duplicate files (files with identical content)

## Categories

Files are organized into the following categories based on their extensions:

- **Images**: jpg, jpeg, png, gif, bmp, tiff, svg, webp, heic, raw, cr2, nef
- **Documents**: pdf, doc, docx, xls, xlsx, ppt, pptx, txt, rtf, odt, ods, odp, csv, md, pages, numbers, key
- **Music**: mp3, wav, flac, aac, ogg, m4a, wma, aiff, alac
- **Videos**: mp4, avi, mkv, mov, wmv, flv, webm, m4v, 3gp, mpeg, mpg
- **Archives**: zip, rar, 7z, tar, gz, bz2, xz, iso, dmg
- **Others**: Any other file types, including code files

## How It Works

1. The script recursively finds all files in the source directory
2. For each file:
   - It calculates a SHA-1 hash of the file content
   - If a file with the same hash has already been processed, it skips the file
   - It determines the file category based on its extension
   - It renames the file using its creation date
   - It copies the file to the appropriate category folder in the destination directory

## Notes

- The script moves files from the source directory to the destination directory
- Original files are removed from their source location after being processed
- On Linux, since creation time is not reliably available, modification time is used instead
- The script requires SHA-1 utilities (`shasum` or `sha1sum`) to be installed

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.