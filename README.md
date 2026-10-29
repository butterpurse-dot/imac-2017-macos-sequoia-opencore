# imac-2017-macos-sequoia-opencore

Install macOS Sequoia 15 on a 2017 iMac (iMac18,x) with [OpenCore Legacy Patcher](https://github.com/dortania/OpenCore-Legacy-Patcher).

<p align="center"><img src="assets/boot-chain.svg" alt="Firmware → OpenCore on the boot disk's EFI → iMac19,1 model spoof → Sequoia" width="100%"></p>

Tested on iMac18,2. iMac18,1 and iMac18,3 should behave the same, but haven't been tested.

## Requirements

- macOS Ventura and an admin account
- OCLP 2.5.1 or newer
- USB stick of 32 GB or more (it gets erased)
- Wired keyboard (wireless ones don't work in the boot picker)
- A backup

## Install

```bash
git clone https://github.com/butterpurse-dot/imac-2017-macos-sequoia-opencore.git
cd imac-2017-macos-sequoia-opencore
bash scripts/diag-efi.sh                     # lists disks by Media Name
export STICK_NAME="…" BOOT_DISK_NAME="…"
```

1. **OCLP:** *Build and Install OpenCore*, then install it to the boot disk's EFI. Restart.
2. **OCLP:** *Create macOS Installer*, then *Download* Sequoia, then *Flash Installer* to the stick. Accept the prompt to install OpenCore to the stick's EFI.
3. Run `bash scripts/diag-efi.sh`. The stick must show `EFI/OC/config.plist`. If it's missing, repeat the prompt in step 2.
4. Run `bash scripts/sync-oc-to-disk.sh`, which copies the stick's OpenCore to the boot disk.
5. Run `bash scripts/spoof-smbios.sh`, which reports the Mac to Sequoia as an iMac19,1. Restart.
6. Run `open "/Applications/Install macOS Sequoia.app"` and choose the boot disk. The install takes about an hour.

Scripts 4 and 5 back up to `/Users/Shared/OC-backup-<date>/` before changing anything.

## Troubleshooting

| Symptom | Fix |
|---|---|
| No boot picker when holding ⌥ | Use a wired keyboard |
| Startup error on every EFI entry | The stick's EFI is empty. Redo step 2 |
| 🚫 with `support.apple.com/mac/startup` | Run step 4 |
| "Not compatible" or "cannot be installed on this computer" | Run step 5 |
| `bless` error `0xe00002e2` | Ignore it. OCLP already set the default boot entry |

## After install

- **Sequoia updates:** Install 15.x updates from System Settings. When OCLP offers to re-apply its patches after the restart, accept it.
- **Major upgrades:** Don't install the next major macOS until OCLP supports it.
- **Optional:** `bash scripts/debloat.sh` disables 16 background services. `undo-debloat.sh` reverts it.

## Scripts

| Script | Purpose | sudo |
|---|---|:-:|
| `diag-efi.sh` | List disks and show OpenCore state (read-only) | ✔ |
| `sync-oc-to-disk.sh` | Copy OpenCore from the stick to the boot disk | ✔ |
| `spoof-smbios.sh` | Set the model to `MODEL` (default iMac19,1) | ✔ |
| `debloat.sh` / `undo-debloat.sh` | Disable or re-enable background services | |

Unsupported by Apple. Use at your own risk. MIT licensed.
