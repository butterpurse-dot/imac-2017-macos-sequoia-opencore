#!/bin/bash
# Read-only: shows what OpenCore looks like on the installer stick's and the boot SSD's EFI partitions.
# Mounts each EFI read-only, prints a summary, unmounts. Changes nothing.
# Usage: STICK_NAME="CB05" SSD_NAME="PSSD T7" bash diag-efi.sh   (names as shown by `diskutil info`)
set -uo pipefail

STICK_NAME="${STICK_NAME:-CB05}"
SSD_NAME="${SSD_NAME:-PSSD T7}"

inspect() {
  local label="$1" name="$2" esp="" d
  for d in $(diskutil list external physical | grep -oE '^/dev/disk[0-9]+'); do
    if diskutil info "$d" | grep -q "$name"; then esp="${d}s1"; fi
  done
  echo "=============== $label ($name) ==============="
  if [ -z "$esp" ]; then echo "disk not found"; return; fi
  echo "EFI partition: $esp"
  sudo diskutil mount readOnly "$esp" >/dev/null 2>&1
  local mp
  mp="$(diskutil info "$esp" | awk -F': *' '/Mount Point/ {print $2}')"
  if [ -z "$mp" ]; then echo "could not mount"; return; fi
  echo "-- files"
  find "$mp" -maxdepth 4 -not -name '._*' -not -path '*/.fseventsd*' -not -path '*/.Spotlight*' -not -path '*/.Trashes*' | sed "s|$mp||" | head -80
  local cfg="$mp/EFI/OC/config.plist"
  if [ -f "$cfg" ]; then
    echo "-- config.plist"
    echo -n "boot-args: ";       plutil -extract NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args raw "$cfg" 2>&1
    echo -n "ProductName: ";     plutil -extract PlatformInfo.Generic.SystemProductName raw "$cfg" 2>&1
    echo -n "SecureBootModel: "; plutil -extract Misc.Security.SecureBootModel raw "$cfg" 2>&1
    echo -n "Timeout: ";         plutil -extract Misc.Boot.Timeout raw "$cfg" 2>&1
    echo -n "Kernel.Add count: "; plutil -extract Kernel.Add raw "$cfg" 2>&1
  else
    echo "no config.plist at EFI/OC  ← OpenCore is NOT installed here"
  fi
  sudo diskutil unmount "$esp" >/dev/null 2>&1
}

inspect "Installer stick" "$STICK_NAME"
inspect "Boot SSD"        "$SSD_NAME"
