#!/bin/bash
# Makes the boot disk's OpenCore present the Mac as a newer model the Sequoia installer accepts (default iMac19,1).
# Fixes "macOS Sequoia is not compatible with this Mac" / "cannot be installed on this computer".
# Backs up config.plist first. Only edits the boot disk's EFI partition.
# Usage: BOOT_DISK_NAME="…" [MODEL=iMac19,1] bash scripts/spoof-smbios.sh
set -uo pipefail
source "$(dirname "$0")/lib.sh"
require_names BOOT_DISK_NAME
MODEL="${MODEL:-iMac19,1}"
BK="${BACKUP_DIR:-/Users/Shared/OC-backup-$(date +%Y-%m-%d)}"

DISK="$(find_esp "$BOOT_DISK_NAME")"
[ -n "$DISK" ] || { echo "Boot disk's EFI partition not found. Nothing changed."; exit 1; }
sudo diskutil mount "$DISK" >/dev/null 2>&1
MP="$(mp_of "$DISK")"
[ -n "$MP" ] || { echo "Could not mount the EFI partition. Nothing changed."; exit 1; }
CFG="$MP/EFI/OC/config.plist"
[ -f "$CFG" ] || { echo "No OpenCore config.plist on that disk. Nothing changed."; sudo diskutil unmount "$DISK" >/dev/null 2>&1; exit 1; }

mkdir -p "$BK" && sudo cp "$CFG" "$BK/config.before-spoof.plist"
echo "Before: Model='$(plutil -extract PlatformInfo.Generic.SystemProductName raw "$CFG" 2>&1)'"

TMPF="$(mktemp)"; cp "$CFG" "$TMPF"
plutil -replace PlatformInfo.Generic.SystemProductName -string "$MODEL" "$TMPF"
plutil -replace PlatformInfo.Automatic -bool true "$TMPF"
plutil -replace PlatformInfo.UpdateSMBIOSMode -string "Custom" "$TMPF"
if plutil -lint "$TMPF" >/dev/null 2>&1; then
  sudo cp "$TMPF" "$CFG"
  echo "After:  Model='$(plutil -extract PlatformInfo.Generic.SystemProductName raw "$CFG" 2>&1)'"
  echo "RESULT: OK (backup in $BK)"
else
  echo "RESULT: edited file was invalid, nothing changed"
fi
rm -f "$TMPF"
sudo diskutil unmount "$DISK" >/dev/null 2>&1
