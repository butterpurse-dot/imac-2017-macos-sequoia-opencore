#!/bin/bash
# Shared helpers. Disks are matched by the "Device / Media Name" that `diskutil info` shows.

require_names() {
  local missing=0 v
  for v in "$@"; do
    if [ -z "${!v:-}" ]; then echo "Set $v first."; missing=1; fi
  done
  if [ "$missing" = 1 ]; then
    echo
    echo "Your disks (use the Media Name):"
    for d in $(diskutil list physical | grep -oE '^/dev/disk[0-9]+'); do
      printf '  %-12s %s\n' "$d" "$(diskutil info "$d" | awk -F': *' '/Device \/ Media Name/ {print $2}')"
    done
    echo
    echo 'Example: STICK_NAME="SanDisk 3.2Gen1" BOOT_DISK_NAME="Samsung SSD" bash scripts/<script>.sh'
    exit 1
  fi
}

# Prints the EFI partition (sN) of the physical disk whose Media Name contains $1.
find_esp() {
  local name="$1" d p
  for d in $(diskutil list physical | grep -oE '^/dev/disk[0-9]+'); do
    if diskutil info "$d" | grep -q "Media Name:.*$name"; then
      p="$(diskutil list "$d" | awk '/EFI EFI/ {print $NF; exit}')"
      [ -n "$p" ] && echo "/dev/$p"
      return
    fi
  done
}

mp_of() { diskutil info "$1" | awk -F': *' '/Mount Point/ {print $2}'; }
