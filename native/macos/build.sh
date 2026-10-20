#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
xcrun clang -arch x86_64 -fobjc-arc -fblocks -dynamiclib \
  -Wall -Wextra -Werror -Wno-unused-parameter \
  -framework Cocoa HideCursor.m -o build/HideCursor.dylib
echo "Built native/macos/build/HideCursor.dylib"
