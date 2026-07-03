#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Voice Replies"
APP_BUNDLE="dist/${APP_NAME}.app"
ZIP_PATH="dist/${APP_NAME}.zip"
DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_SPECIFIC_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

./scripts/build_app.sh >/dev/null

if [[ -n "${DEVELOPER_ID_APPLICATION}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "${DEVELOPER_ID_APPLICATION}" "${APP_BUNDLE}"
else
  echo "DEVELOPER_ID_APPLICATION is not set; keeping ad-hoc local signing."
fi

ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

if [[ -n "${DEVELOPER_ID_APPLICATION}" && -n "${APPLE_ID}" && -n "${APPLE_TEAM_ID}" && -n "${APPLE_APP_SPECIFIC_PASSWORD}" ]]; then
  xcrun notarytool submit "${ZIP_PATH}" \
    --apple-id "${APPLE_ID}" \
    --team-id "${APPLE_TEAM_ID}" \
    --password "${APPLE_APP_SPECIFIC_PASSWORD}" \
    --wait
  xcrun stapler staple "${APP_BUNDLE}"
  ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"
else
  echo "Notarization skipped. Set APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD, and DEVELOPER_ID_APPLICATION to notarize."
fi

codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"
echo "${ZIP_PATH}"
