#!/usr/bin/env bash
set -euo pipefail
: "${RUNNER_TEMP:?GitHub runner temp directory is required}"
: "${GITHUB_ENV:?GitHub environment file is required}"
mkdir -p "$RUNNER_TEMP/kunlun-godot"
cd "$RUNNER_TEMP/kunlun-godot"
release=https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable
archive=Godot_v4.6.3-stable_linux.x86_64.zip
curl --fail --location --retry 3 "$release/$archive" -o "$archive"
curl --fail --location --retry 3 "$release/SHA512-SUMS.txt" -o SHA512-SUMS.txt
awk -v name="$archive" '$2 == name || $2 == "*" name' SHA512-SUMS.txt > selected.sha512
test "$(wc -l < selected.sha512)" -eq 1
sha512sum --check selected.sha512
unzip -q "$archive"
chmod +x Godot_v4.6.3-stable_linux.x86_64
echo "GODOT=$PWD/Godot_v4.6.3-stable_linux.x86_64" >> "$GITHUB_ENV"
