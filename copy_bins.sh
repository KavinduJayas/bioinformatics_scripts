#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <src_path> <dst_path>"
    echo "This script copies four files from source to destination:"
    echo "  - src_path/prefix.ec.fq -> dst_path/prefix.ec.fq"
    echo "  - src_path/prefix.ec.bin -> dst_path/prefix.ec.bin"
    echo "  - src_path/prefix.ovlp.source.bin -> dst_path/prefix.ovlp.source.bin"
    echo "  - src_path/prefix.ovlp.reverse.bin -> dst_path/prefix.ovlp.reverse.bin"
    exit 1
fi

SRC_PATH="$1"
DST_PATH="$2"

FILES=("ec.fq" "ec.bin" "ovlp.source.bin" "ovlp.reverse.bin")

# Check for missing source files
missing_files=()
for suffix in "${FILES[@]}"; do
    src="${SRC_PATH}.${suffix}"
    if [ ! -f "$src" ]; then
        missing_files+=("$src")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "Warning: The following source files do not exist:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Check for existing destination files
existing_files=()
for suffix in "${FILES[@]}"; do
    dst="${DST_PATH}.${suffix}"
    if [ -f "$dst" ]; then
        existing_files+=("$dst")
    fi
done

if [ ${#existing_files[@]} -gt 0 ]; then
    echo "Warning: The following destination files already exist and will be overwritten:"
    for file in "${existing_files[@]}"; do
        echo "  - $file"
    done
    read -p "Do you want to overwrite these files? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Perform the copy operations
echo "Copying files from ${SRC_PATH} to ${DST_PATH}..."
for suffix in "${FILES[@]}"; do
    src="${SRC_PATH}.${suffix}"
    dst="${DST_PATH}.${suffix}"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        if [ $? -eq 0 ]; then
            echo "✓ Copied $src -> $dst"
        else
            echo "✗ Failed to copy $src -> $dst"
        fi
    else
        echo "⊘ Skipped $src (does not exist)"
    fi
done

echo "Done."
