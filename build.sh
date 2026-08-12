#!/bin/bash
set -e

# Clone Flutter stable SDK if not already cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"
echo "Flutter version:"
flutter --version

echo "Building Flutter Web release package..."
cd frontend
flutter pub get
flutter build web --release
