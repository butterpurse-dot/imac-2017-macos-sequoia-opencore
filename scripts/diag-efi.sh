#!/bin/bash
# Read-only: shows OpenCore on the installer stick's and the boot disk's EFI partitions. Changes nothing.
# Usage: STICK_NAME="…" BOOT_DISK_NAME="…" bash scripts/diag-efi.sh
set -uo pipefail
source "$(dirname "$0")/lib.sh"
require_names STICK_NAME BOOT_DISK_NAME

inspect() {
  local label="$1" esp
  esp="$(find_esp "$2")"
  echo "=============== $label ($2) ==============="
  if [ -z "$esp" ]; then echo "disk or EFI partition not found"; return; fi
  echo "EFI partition: $esp"
  sudo diskutil mount readOnly "$esp" >/dev/null 2>&1
  local mp; mp="$(mp_of "$esp")"
  if [ -z "$mp" ]; then echo "could not mount"; return; fi
  find "$mp" -maxdepth 4 -not -name '._*' -not -path '*/.fseventsd*' -not -path '*/.Spotlight*' -not -path '*/.Trashes*' | sed "s|$mp||" | head -60
  local cfg="$mp/EFI/OC/config.plist"
  if [ -f "$cfg" ]; then
    echo "-- config.plist"
    echo -n "Model: ";           plutil -extract PlatformInfo.Generic.SystemProductName raw "$cfg" 2>&1
    echo -n "boot-args: ";       plutil -extract NVRAM.Add.7C436110-AB2A-4BBB-A880-FE41995C9F82.boot-args raw "$cfg" 2>&1
    echo -n "SecureBootModel: "; plutil -extract Misc.Security.SecureBootModel raw "$cfg" 2>&1
    echo -n "Timeout: ";         plutil -extract Misc.Boot.Timeout raw "$cfg" 2>&1
  else
    echo "no config.plist at EFI/OC  ← OpenCore is NOT installed here"
  fi
  sudo diskutil unmount "$esp" >/dev/null 2>&1
}

inspect "Installer stick" "$STICK_NAME"
inspect "Boot disk"       "$BOOT_DISK_NAME"
