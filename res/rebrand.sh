#!/usr/bin/env bash
# Rebrands the RustDesk sources at CI build time, after checkout (submodules included).
# Display-layer rename only: internal crate/library identifiers stay "rustdesk" so the
# upstream build scripts keep working; the workflow renames the shipped .exe separately.
set -euo pipefail

BRAND="$(tr -d '\r\n' < res/brand/name.txt)"
echo "Rebranding as: ${BRAND}"

# Runtime app name — drives window titles, tray tooltip, service name, install dir,
# and config paths. Lives in the hbb_common submodule, hence patched here, not committed.
sed -i "s/RwLock::new(\"RustDesk\".to_owned())/RwLock::new(\"${BRAND}\".to_owned())/" libs/hbb_common/src/config.rs
grep -q "RwLock::new(\"${BRAND}\"" libs/hbb_common/src/config.rs

# Numeric-only one-time passwords (UltraViewer style): swap the generator's
# character set from digits+letters to digits only.
sed -z -i "s/const CHARS: &\\[char\\] = &\\[[^]]*\\];/const CHARS: \\&[char] = \\&['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];/" libs/hbb_common/src/config.rs
grep -q "'0', '1', '2', '3'" libs/hbb_common/src/config.rs

# Native runner's fallback window title (used before librustdesk is loaded).
sed -i "s/L\"RustDesk\"/L\"${BRAND}\"/" flutter/windows/runner/main.cpp

# Windows version-info resource: ProductName etc. shown in Explorer file properties.
sed -i "s/\"RustDesk\"/\"${BRAND}\"/g" flutter/windows/runner/Runner.rc

# User-visible strings. Whole-word + case-sensitive: keys and text like "RustDesk ID"
# are renamed consistently in both the Dart call sites and the translation tables,
# while identifiers (RustDeskMultiWindowManager) and lowercase URLs stay untouched.
sed -i "s/\bRustDesk\b/${BRAND}/g" src/lang/*.rs
find flutter/lib -name '*.dart' -print0 | xargs -0 sed -i "s/\bRustDesk\b/${BRAND}/g"

# Swap in the branded icons staged under res/brand/.
cp -f res/brand/icon.png       res/icon.png
cp -f res/brand/icon.ico       res/icon.ico
cp -f res/brand/tray-icon.ico  res/tray-icon.ico
cp -f res/brand/32x32.png      res/32x32.png
cp -f res/brand/64x64.png      res/64x64.png
cp -f res/brand/128x128.png    res/128x128.png
cp -f "res/brand/128x128@2x.png" "res/128x128@2x.png"
# flutter/assets/icon.png, flutter/assets/logo.png and
# flutter/windows/runner/resources/app_icon.ico are committed branded in this fork.

echo "BRAND=${BRAND}" >> "${GITHUB_ENV}"
echo "Rebrand complete."
