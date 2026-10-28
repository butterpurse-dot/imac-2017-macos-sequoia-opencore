# iMac18,2 (21.5" 4K, 2017) → macOS Sequoia, booting from an external Samsung T7

<p align="center"><img src="assets/hero.svg" alt="2017 iMac upgraded from Ventura 13.7.8 to Sequoia 15.8.1" width="100%"></p>

Apple's last macOS for this iMac is **Ventura 13.7.8**. This one now runs **Sequoia 15.8.1 (24H32)** with
[OpenCore Legacy Patcher](https://github.com/dortania/OpenCore-Legacy-Patcher) 2.5.1. It boots from a USB‑C Samsung T7 SSD, not the slow internal HDD.

| | |
|---|---|
| Mac | iMac18,2 · i5‑7400 · 8 GB · Radeon Pro 555 (Polaris) · Wi‑Fi BCM43602 |
| Boot disk | Samsung T7 1 TB on USB‑C (10 Gb/s) |
| Tool | OCLP 2.5.1 → OpenCore 1.0.6 |
| Result | Sequoia 15.8.1 · Wi‑Fi ✅ · Metal GPU ✅ |

## How it boots

<p align="center"><img src="assets/boot-chain.svg" alt="Firmware → OpenCore on T7 EFI → iMac19,1 spoof → Sequoia" width="100%"></p>

## The short recipe

1. **OCLP** → *Create macOS Installer* → *Download macOS Installer*, pick Sequoia, then *Flash Installer* onto a USB stick of **32 GB or more**.
2. When it asks to install OpenCore onto the stick, say **yes** and choose the stick's **EFI** partition. Check it really landed with `scripts/diag-efi.sh`.
3. Copy that OpenCore to the T7: `scripts/sync-oc-to-t7.sh`.
4. Spoof the model so the installer accepts the Mac: `scripts/spoof-smbios.sh` (iMac18,2 → iMac19,1).
5. Restart. The T7's OpenCore boots by itself. Open `Install macOS Sequoia.app` and pick the T7 as the destination.
6. ☕ About an hour. Done.

<p align="center"><img src="assets/terminal.svg" alt="terminal replay of the upgrade" width="100%"></p>

## Gotchas we hit

| Symptom | Cause | Fix |
|---|---|---|
| No boot picker when holding ⌥ | 2.4 GHz wireless keyboard dongle | Use a wired keyboard |
| `bless … 0xe00002e2` | Can't bless while booted through OpenCore | Not needed. The T7's OpenCore already loads by default |
| Startup error on every EFI entry | The stick's EFI was **empty**. The flash stopped before installing OpenCore | Install OpenCore onto the stick's EFI again (step 2) |
| 🚫 + `support.apple.com/mac/startup` | The T7's OpenCore (built for Ventura) loaded the installer | `sync-oc-to-t7.sh` |
| "not compatible" / "cannot be installed on this computer" | Sequoia only accepts iMac19,1+ | `spoof-smbios.sh` |

## Make it fast

<p align="center"><img src="assets/debloat.svg" alt="background services switched off" width="100%"></p>

- `scripts/debloat.sh` stops 16 stock background services and turns off transparency and motion. `scripts/undo-debloat.sh` reverts it.
- Remove leftover `LaunchDaemons` from uninstalled apps (Docker, Adobe ARMDC, Teams, Google updater).
- The real upgrade is **RAM**. 8 GB is the bottleneck. The 21.5" 2017 has SO‑DIMM slots behind the display, up to 32 GB.

## Keep it working

- Update macOS **through OCLP**, not System Settings. Update OCLP first.
- If it won't boot, hold ⌥ and pick the T7.

## Scripts

| Script | Does | sudo |
|---|---|---|
| [`diag-efi.sh`](scripts/diag-efi.sh) | Read-only check of OpenCore on the stick and the SSD | ✔ |
| [`sync-oc-to-t7.sh`](scripts/sync-oc-to-t7.sh) | Copy the stick's OpenCore to the SSD, with a backup | ✔ |
| [`spoof-smbios.sh`](scripts/spoof-smbios.sh) | Set the model to iMac19,1, with a backup | ✔ |
| [`debloat.sh`](scripts/debloat.sh) / [`undo-debloat.sh`](scripts/undo-debloat.sh) | Turn background services off or back on | ✘ |

Disk names default to `CB05` (stick) and `PSSD T7` (SSD). Override them with `STICK_NAME=… SSD_NAME=… bash scripts/…`.

> ⚠️ Unsupported by Apple. Experiment at your own risk. This Mac was a learning machine and was already out of warranty.

MIT licensed.
