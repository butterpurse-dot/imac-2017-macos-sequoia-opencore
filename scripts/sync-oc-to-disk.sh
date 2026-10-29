#!/bin/bash
# Copies the Sequoia-ready OpenCore (that OCLP put on the installer stick) to the boot disk's EFI partition,
# so the boot disk's own OpenCore can start the installer. Backs up the boot disk's OpenCore first.
# Usage: STICK_NAME="…" BOOT_DISK_NAME="…" bash scripts/sync-oc-to-disk.sh
set -uo pipefail
source "$(dirname "$0")/lib.sh"
require_names STICK_NAME BOOT_DISK_NAME
BK="${BACKUP_DIR:-/Users/Shared/OC-backup-$(date +%Y-%m-%d)}"

STICK="$(find_esp "$STICK_NAME")"; DISK="$(find_esp "$BOOT_DISK_NAME")"
if [ -z "$STICK" ] || [ -z "$DISK" ]; then echo "Could not find both EFI partitions (stick: '$STICK', boot disk: '$DISK'). Nothing changed."; exit 1; fi
if [ "$STICK" = "$DISK" ]; then echo "Stick and boot disk are the same disk. Nothing changed."; exit 1; fi

sudo diskutil mount readOnly "$STICK" >/dev/null 2>&1
sudo diskutil mount "$DISK" >/dev/null 2>&1
SMP="$(mp_of "$STICK")"; DMP="$(mp_of "$DISK")"
cleanup() { sudo diskutil unmount "$STICK" >/dev/null 2>&1; sudo diskutil unmount "$DISK" >/dev/null 2>&1; }
if [ -z "$SMP" ] || [ -z "$DMP" ]; then echo "Could not mount both EFI partitions. Nothing changed."; cleanup; exit 1; fi
if [ ! -f "$SMP/EFI/OC/config.plist" ] || [ ! -f "$SMP/EFI/OC/OpenCore.efi" ]; then echo "The stick has no complete OpenCore. Nothing changed."; cleanup; exit 1; fi
if [ ! -d "$DMP/EFI/OC" ]; then echo "The boot disk has no OpenCore yet. Do step 2 (Build and Install OpenCore) first. Nothing changed."; cleanup; exit 1; fi

mkdir -p "$BK" && sudo cp -R "$DMP/EFI/OC" "$BK/" || { echo "Backup failed. Nothing changed."; cleanup; exit 1; }
echo "Backed up the boot disk's OpenCore to $BK"

sudo rsync -a --delete --exclude='._*' "$SMP/EFI/OC/" "$DMP/EFI/OC/"
if sudo diff -rq --exclude='._*' --exclude='.DS_Store' "$SMP/EFI/OC" "$DMP/EFI/OC" >/dev/null 2>&1; then
  echo "RESULT: OK, the boot disk now has the Sequoia-ready OpenCore"
else
  echo "RESULT: copy differs, check before restarting"
fi
cleanup
