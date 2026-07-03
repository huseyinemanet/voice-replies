#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Voice Replies"
EXECUTABLE_NAME="VoiceTranslation"
APP_BUNDLE="dist/${APP_NAME}.app"

swift build -c release

rm -rf dist
mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources"

cp ".build/release/${EXECUTABLE_NAME}" "${APP_BUNDLE}/Contents/MacOS/${EXECUTABLE_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${EXECUTABLE_NAME}"

codesign --force --deep --sign - "${APP_BUNDLE}" >/dev/null

echo "${APP_BUNDLE}"
