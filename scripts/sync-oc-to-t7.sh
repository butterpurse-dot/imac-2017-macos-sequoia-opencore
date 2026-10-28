#!/bin/bash
# Copies the Sequoia-ready OpenCore (built by OCLP onto the installer stick) to the boot SSD's EFI partition,
# so the SSD's own OpenCore can start the Sequoia installer. Backs up the SSD's current OpenCore first.
# Usage: STICK_NAME="CB05" SSD_NAME="PSSD T7" bash sync-oc-to-t7.sh
set -uo pipefail

STICK_NAME="${STICK_NAME:-CB05}"
SSD_NAME="${SSD_NAME:-PSSD T7}"
BK="${BACKUP_DIR:-/Users/Shared/OC-backup-$(date +%Y-%m-%d)}"

find_esp() {
  local name="$1" d
  for d in $(diskutil list external physical | grep -oE '^/dev/disk[0-9]+'); do
    if diskutil info "$d" | grep -q "$name"; then echo "${d}s1"; return; fi
  done
}
mp_of() { diskutil info "$1" | awk -F': *' '/Mount Point/ {print $2}'; }

STICK="$(find_esp "$STICK_NAME")"
SSD="$(find_esp "$SSD_NAME")"
if [ -z "$STICK" ] || [ -z "$SSD" ]; then echo "Could not find both disks (stick: '$STICK', SSD: '$SSD'). Nothing changed."; exit 1; fi

sudo diskutil mount readOnly "$STICK" >/dev/null 2>&1
sudo diskutil mount "$SSD" >/dev/null 2>&1
SMP="$(mp_of "$STICK")"; TMP="$(mp_of "$SSD")"
cleanup() { sudo diskutil unmount "$STICK" >/dev/null 2>&1; sudo diskutil unmount "$SSD" >/dev/null 2>&1; }
if [ -z "$SMP" ] || [ -z "$TMP" ]; then echo "Could not mount both EFI partitions. Nothing changed."; cleanup; exit 1; fi
if [ ! -f "$SMP/EFI/OC/config.plist" ] || [ ! -f "$SMP/EFI/OC/OpenCore.efi" ]; then echo "Stick has no complete OpenCore. Nothing changed."; cleanup; exit 1; fi

mkdir -p "$BK" && sudo cp -R "$TMP/EFI/OC" "$BK/" || { echo "Backup failed. Nothing changed."; cleanup; exit 1; }
echo "Backed up the SSD's current OpenCore to $BK"

sudo rsync -a --delete --exclude='._*' "$SMP/EFI/OC/" "$TMP/EFI/OC/"
if sudo diff -rq --exclude='._*' --exclude='.DS_Store' "$SMP/EFI/OC" "$TMP/EFI/OC" >/dev/null 2>&1; then
  echo "RESULT: OK, the SSD now has the Sequoia-ready OpenCore"
else
  echo "RESULT: copy differs, check before restarting"
fi
cleanup
