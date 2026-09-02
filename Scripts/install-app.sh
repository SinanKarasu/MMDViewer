#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
derived_data="$project_dir/.build/DerivedData"
install_dir=${INSTALL_DIR:-$HOME/Applications}
built_app="$derived_data/Build/Products/Release/MMDViewer.app"
installed_app="$install_dir/MMDViewer.app"
project_file="$project_dir/MMDViewer.xcodeproj"

if [[ "$install_dir" == "/" || "$install_dir" == "$HOME" || "$install_dir" == "$project_dir" ]]; then
    echo "Refusing unsafe installation directory: $install_dir" >&2
    exit 2
fi

xcodebuild \
    -project "$project_file" \
    -scheme MMDViewer \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "$derived_data" \
    build

if [[ ! -d "$built_app" || ! -x "$built_app/Contents/MacOS/MMDViewer" ]]; then
    echo "Build did not produce a valid application at $built_app" >&2
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$built_app"
mkdir -p "$install_dir"

staging_dir=$(mktemp -d "$install_dir/.MMDViewer-install.XXXXXX")
staged_app="$staging_dir/MMDViewer.app"
ditto "$built_app" "$staged_app"
codesign --verify --deep --strict --verbose=2 "$staged_app"

if [[ -e "$installed_app" ]]; then
    trash_root="$HOME/.Trash"
    mkdir -p "$trash_root"
    backup_dir=$(mktemp -d "$trash_root/MMDViewer-backup.XXXXXX")
    mv "$installed_app" "$backup_dir/MMDViewer.app"
    echo "Previous installation moved to $backup_dir/MMDViewer.app"
fi

mv "$staged_app" "$installed_app"
rmdir "$staging_dir"

launch_services=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
if [[ -x "$launch_services" ]]; then
    "$launch_services" -f "$installed_app"
fi

echo "Installed $installed_app"
