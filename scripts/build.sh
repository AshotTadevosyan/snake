#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache Snake.app/Contents/MacOS Snake.app/Contents/Resources
export CLANG_MODULE_CACHE_PATH="$PWD/build/module-cache"
arches="${ARCHS:-arm64 x86_64}"
binaries=()
for arch in $arches; do
    xcrun swiftc -O -swift-version 5 -target "$arch-apple-macosx13.0" \
        -module-cache-path "$PWD/build/module-cache" \
        Sources/Game.swift Sources/BoardView.swift Sources/AppDelegate.swift Sources/main.swift \
        -o "build/Snake-$arch"
    binaries+=("build/Snake-$arch")
done
xcrun lipo -create "${binaries[@]}" -output Snake.app/Contents/MacOS/Snake
cp Resources/Info.plist Snake.app/Contents/Info.plist
if [ -f Resources/Snake.icns ]; then
    cp Resources/Snake.icns Snake.app/Contents/Resources/
fi
xattr -cr Snake.app
codesign --force --sign - Snake.app
echo "Built $PWD/Snake.app"
