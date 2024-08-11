#!/bin/bash

# Important: Please run this sh file to setup your project before building the Flutter app
# This file is used to download the OBS fork version app from Kittipos server
# Author: Kittipos Leelaparn

# Define URLs for downloading OBS app versions
APPLE_SILICON_URL="https://kittipos.me/s/sMs4fTWFfz7oift/download/obs_apple.zip"
INTEL_URL="https://kittipos.me/s/4dPq95bcDEfxof9/download/obs_intel.zip"

# Define destination directories
DEST_DIR="./obs_fork"
APPLE_DEST="$DEST_DIR/obs_apple.app"
INTEL_DEST="$DEST_DIR/obs_intel.app"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Function to download and unzip the OBS app
download_and_unzip() {
  local url=$1
  local dest=$2
  local temp_zip="$dest.zip"

  echo "Downloading from $url..."
  curl -L -o "$temp_zip" "$url"

  echo "Unzipping to $dest..."
  unzip -o "$temp_zip" -d "$DEST_DIR"

  echo "Cleaning up..."
  rm "$temp_zip"
}

# Download and unzip Apple Silicon version
download_and_unzip "$APPLE_SILICON_URL" "$APPLE_DEST"

# Download and unzip Intel version
download_and_unzip "$INTEL_URL" "$INTEL_DEST"

echo "OBS app setup completed."