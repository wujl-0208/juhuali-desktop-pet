#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_path="${1:-${project_dir:h}/菊花梨.app}"
macos_dir="$app_path/Contents/MacOS"
resource_dir="$app_path/Contents/Resources"
mkdir -p "$macos_dir" "$resource_dir/Animations"
mkdir -p "$project_dir/.build/module-cache"

find "$project_dir/Sources" -name '*.swift' -print0 | xargs -0 xcrun swiftc \
  -O -swift-version 5 -target arm64-apple-macos13.0 \
  -module-cache-path "$project_dir/.build/module-cache" \
  -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
  -framework AppKit -framework ImageIO \
  -o "$macos_dir/JuhualiPet"

cp "$project_dir/Resources/Info.plist" "$app_path/Contents/Info.plist"
cp "$project_dir/Resources/Animations/spritesheet.png" "$resource_dir/Animations/spritesheet.png"
if [[ -f "$project_dir/Resources/AppIcon.icns" ]]; then
  cp "$project_dir/Resources/AppIcon.icns" "$resource_dir/AppIcon.icns"
fi
plutil -lint "$app_path/Contents/Info.plist"
codesign --force --sign - "$app_path"
echo "Built $app_path"
