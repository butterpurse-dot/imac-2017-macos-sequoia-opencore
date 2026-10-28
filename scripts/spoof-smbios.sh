#!/bin/bash
# Makes the boot SSD's OpenCore present the Mac as an iMac19,1, the oldest iMac the Sequoia installer accepts.
# Fixes "macOS Sequoia is not compatible with this Mac" / "cannot be installed on this computer".
# Backs up config.plist first. Only edits the SSD's EFI partition.
# Usage: SSD_NAME="PSSD T7" bash spoof-smbios.sh
set -uo pipefail

SSD_NAME="${SSD_NAME:-PSSD T7}"
MODEL="${MODEL:-iMac19,1}"
BK="${BACKUP_DIR:-/Users/Shared/OC-backup-$(date +%Y-%m-%d)}"

SSD=""
for d in $(diskutil list external physical | grep -oE '^/dev/disk[0-9]+'); do
  if diskutil info "$d" | grep -q "$SSD_NAME"; then SSD="${d}s1"; fi
done
[ -n "$SSD" ] || { echo "SSD not found. Nothing changed."; exit 1; }

sudo diskutil mount "$SSD" >/dev/null 2>&1
MP="$(diskutil info "$SSD" | awk -F': *' '/Mount Point/ {print $2}')"
[ -n "$MP" ] || { echo "Could not mount the SSD's EFI. Nothing changed."; exit 1; }
CFG="$MP/EFI/OC/config.plist"
[ -f "$CFG" ] || { echo "No config.plist. Nothing changed."; sudo diskutil unmount "$SSD" >/dev/null 2>&1; exit 1; }

mkdir -p "$BK" && sudo cp "$CFG" "$BK/config.before-spoof.plist"
echo "Before: Model='$(plutil -extract PlatformInfo.Generic.SystemProductName raw "$CFG" 2>&1)'"

TMPF="$(mktemp)"; cp "$CFG" "$TMPF"
plutil -replace PlatformInfo.Generic.SystemProductName -string "$MODEL" "$TMPF"
plutil -replace PlatformInfo.Automatic -bool true "$TMPF"
plutil -replace PlatformInfo.UpdateSMBIOSMode -string "Custom" "$TMPF"
if plutil -lint "$TMPF" >/dev/null 2>&1; then
  sudo cp "$TMPF" "$CFG"
  echo "After:  Model='$(plutil -extract PlatformInfo.Generic.SystemProductName raw "$CFG" 2>&1)'"
  echo "RESULT: OK"
else
  echo "RESULT: edited file was invalid, nothing changed"
fi
rm -f "$TMPF"
sudo diskutil unmount "$SSD" >/dev/null 2>&1
