# iMac18,2 (21.5" 4K, 2017) → macOS Sequoia, booting from an external Samsung T7

<p align="center"><img src="assets/hero.svg" alt="2017 iMac upgraded from Ventura 13.7.8 to Sequoia 15.8.1" width="100%"></p>

Apple's last macOS for this iMac is **Ventura 13.7.8**. This one now runs **Sequoia 15.8.x (now 15.8.2)** with
[OpenCore Legacy Patcher](https://github.com/dortania/OpenCore-Legacy-Patcher) 2.5.1. It boots from a USB‑C Samsung T7 SSD, not the slow internal HDD.

| | |
|---|---|
| Mac | iMac18,2 · i5‑7400 · 8 GB · Radeon Pro 555 (Polaris) · Wi‑Fi BCM43602 |
| Boot disk | Samsung T7 1 TB on USB‑C (10 Gb/s) |
| Tool | OCLP 2.5.1 → OpenCore 1.0.6 |
| Result | Sequoia 15.8.1 · Wi‑Fi ✅ · Metal GPU ✅ |

## Verified working

From System Information and the diagnostic reports after the upgrade.

| Area | Status | Detail |
|---|:-:|---|
| Graphics | ✅ | Radeon Pro (Polaris) accelerated (`AMDRadeonX4000`), Metal 2. Intel graphics accelerated too |
| Display | ✅ | Built-in Retina at 4096 × 2304 |
| Wi‑Fi | ✅ | BCM43602, 5 GHz 802.11ac, via OCLP's `IO80211FamilyLegacy` + `AirportBrcmFixup` |
| Bluetooth | ✅ | BCM20703 |
| Audio | ✅ | Built-in speakers and microphone |
| FaceTime camera | ✅ | Detected |
| Ethernet | ✅ | Gigabit, `AppleBCM5701Ethernet` |
| Boot from T7 | ✅ | OpenCore on the T7's EFI, no USB stick needed |
| Kernel panics | ✅ | None |
| macOS updates | ✅ | Auto-updated 15.8.1 → 15.8.2. OCLP re-applied its patches after one restart. Wi‑Fi and GPU survived |
| Shutdown | ✅ | `shutdown_stall` reports still appear, but decoded they show no hung process. macOS logs one whenever shutdown passes 2 s. They happened on Ventura too |
| Memory | ✅ | Normal pressure in everyday use with `debloat.sh`. Heavy Xcode builds still swap a little. More RAM is the only real fix |
| SIP | ⚠️ | Off. Required by OCLP |

Check your own:

```bash
system_profiler SPSoftwareDataType SPDisplaysDataType SPAirPortDataType SPBluetoothDataType SPAudioDataType SPCameraDataType
ioreg -rc IOAccelerator | grep IOClass        # GPU acceleration
kmutil showloaded | grep -iE "lilu|amfipass|airportbrcm|80211FamilyLegacy"
ls /Library/Logs/DiagnosticReports | grep -i panic   # empty = good
```

## How it boots

<p align="center"><img src="assets/boot-chain.svg" alt="Firmware → OpenCore on T7 EFI → iMac19,1 spoof → Sequoia" width="100%"></p>

## Does this apply to you?

| You have | Status |
|---|---|
| iMac18,2 on Ventura, booting from an external USB‑C SSD | ✅ Tested. This repo |
| iMac18,2 booting from the internal drive | 🟡 Same steps should work. Pick the internal disk instead of the SSD. Untested |
| iMac18,1 / iMac18,3 (2017 Kaby Lake) | 🟡 Probably the same model check and fix. Untested |
| Any other Mac | ❓ Check [OCLP's supported models](https://dortania.github.io/OpenCore-Legacy-Patcher/MODELS.html) first |
| Apple Silicon Mac | ❌ Not needed. Use Software Update |

**You'll need:** OCLP 2.5.1+, a USB stick of 32 GB or more (it gets erased), a **wired** keyboard, an admin password, and about 2 hours.

## Step matrix

| # | Step | How | Command / clicks | sudo | Restart | Check it worked |
|---|---|---|---|:-:|:-:|---|
| 0 | Find your disk names | Terminal | `diskutil list external physical` then `diskutil info diskN \| grep "Media Name"` | | | You know the stick's and the SSD's names |
| 1 | Install OCLP | Browser | [OCLP releases](https://github.com/dortania/OpenCore-Legacy-Patcher/releases), run the `.pkg` | ✔ | | `OpenCore-Patcher.app` is in Applications |
| 2 | Put OpenCore on the SSD | OCLP | *Build and Install OpenCore* → *Install to disk* → SSD → EFI | ✔ | ✔ | `nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version` prints a version |
| 3 | Make the installer stick | OCLP | *Create macOS Installer* → *Download* → Sequoia → *Flash Installer* → stick | ✔ | | A volume named "Install macOS Sequoia" appears |
| 4 | OpenCore onto the stick | OCLP | Say **yes** when it asks → stick → **EFI** → *Install* | ✔ | | `bash scripts/diag-efi.sh` shows a `config.plist` on the stick |
| 5 | Copy it to the SSD | Script | `bash scripts/sync-oc-to-t7.sh` | ✔ | | Prints `RESULT: OK` |
| 6 | Spoof iMac19,1 | Script | `bash scripts/spoof-smbios.sh` | ✔ | ✔ | After restarting, `ioreg -lp IODeviceTree -d2 \| grep board-id` shows `Mac-AA95B1DDAB278B95` (iMac19,1's board). `hw.model` may still say iMac18,2, and that's fine |
| 7 | Install Sequoia | Installer | `open "/Applications/Install macOS Sequoia.app"` → pick the SSD | ✔ | ✔✔✔ | `sw_vers -productVersion` prints 15.x |
| 8 | Optional speed-up | Script | `bash scripts/debloat.sh` | | | Prints `off: …` lines |

## Commands, in order

```bash
git clone https://github.com/butterpurse-dot/imac18-2-macos-sequoia-opencore-external-ssd.git
cd imac18-2-macos-sequoia-opencore-external-ssd

sysctl -n hw.model                       # expect iMac18,2
diskutil list external physical          # find the stick and the SSD
export STICK_NAME="CB05" SSD_NAME="PSSD T7"   # ← your names from diskutil info

# steps 1–4 happen in the OCLP app (see the matrix above), then:
bash scripts/diag-efi.sh                 # stick must show EFI/OC/config.plist
bash scripts/sync-oc-to-t7.sh            # → RESULT: OK
bash scripts/spoof-smbios.sh             # → RESULT: OK
sudo shutdown -r now                     # OpenCore boots the SSD by itself after 10 s

open "/Applications/Install macOS Sequoia.app"   # pick the SSD · ☕ about an hour
sw_vers -productVersion                  # 15.x 🎉
bash scripts/debloat.sh                  # optional
```

Backups land in `/Users/Shared/OC-backup-<date>/`. To undo the spoof, copy `config.before-spoof.plist` back to the SSD's `EFI/OC/config.plist`.

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

- Sequoia 15.x security updates through System Settings are fine. OCLP's `macos-update` hook gets ready for them, and after the restart OCLP offers to re‑apply its patches (accept, then restart). Wi‑Fi may be missing until then.
- Major upgrades never install automatically. Wait for OCLP to support the next macOS before upgrading.
- Keep OCLP itself updated. It tells you when there's a new version.
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
