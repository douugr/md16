# MD16

**Sega Mega Drive / Genesis** emulator (also Master System, Game Gear and SG-1000) made for an **old iPad with iOS 8**. Tested on an iPad 3 (A5X, armv7) running iOS 8.4.1 with a jailbreak.

It is a custom libretro frontend written in Objective-C/UIKit that builds the [Genesis Plus GX](https://github.com/libretro/Genesis-Plus-GX) core into the app, with Bluetooth controllers through [BTstack](https://github.com/bluekitchen/btstack). It exists because the RetroArch iOS builds no longer run on iOS 8. (The project started out as Retro16.)

## Install

Add the Cydia repository **https://douugr.github.io/repo/** (Cydia or Melder → Sources → Edit → Add) and install **MD16**. The BTstack package is installed with it.

## Features

- OpenGL ES 2 video (RGB565), sharp (pixels) or smooth image
- **CRT TV filter** (game menu → "Image…"): scanlines that widen on bright colors, a phosphor mask, composite-video blending (color bleeds more than brightness, so dithering turns into the smooth gradients and transparencies artists drew for TVs) and an optional gently curved screen that still fills the display. Runs at 60 fps on an iPad 3
- **RetroAchievements:** sign in with your retroachievements.org account (side menu → Achievements) and unlock achievements while you play, with a pop-up and the badge of each one. The Achievements screen lists your games and their unlocks, and the game menu shows the achievements of the game you are playing. Save states keep the achievement progress. For now unlocks count in Casual mode only (Hardcore needs approval from RetroAchievements), and only original, unmodified games are recognized
- **Side menu:** Games, Achievements, Upload and Controller live in a drawer (☰ button or swipe from the left edge)
- RemoteIO audio, with game pacing driven by the audio queue: if the iPad falls behind, the emulator runs an extra frame without drawing, so the game neither slows down nor stutters
- On-screen controls: 8-way D-pad, A/B/C in an arc like the original pad, START and a menu button
- Visuals inspired by the 16-bit era: grey grid on black, chrome lettering, red and diagonal stripes; the library shows games as cartridge labels
- **Bluetooth controller** (tested with the 8BitDo Pro 2) via BTstack, with:
  - a setup assistant that learns your buttons ("press: Up, A, B, C, Start…");
  - D-pad and left analog stick;
  - automatic reconnection.
  BTstack runs on its own thread, separate from the game.
- **Upload ROMs from a browser:** the "Upload ROMs" screen shows an address (`http://md16.local:8616/<code>/`, with the IP version below it and a QR code to upload from a phone). The code at the end is random and changes every time the screen opens, so nobody else on the network can reach the page;; on your computer, open it and drag the files in — no cable or SSH
- **Automatic IPS/BPS patching:** an `.ips`/`.bps` with the same name as the ROM is applied when the game starts, to a temporary copy; the original ROM is never changed. For BPS the CRC is checked and the app warns if the patch is for another ROM version
- 3 manual save-state slots plus an autosave on exit, with "Continue where you left off?" when the game opens
- SRAM (cartridge saves) written automatically
- Optional 1-frame **run-ahead** (menu): hides one frame of the game's own input lag; it pauses itself if the iPad starts dropping frames
- Optional performance overlay (fps, emulation and drawing time, button→frame time)

On the iPad 3, Sonic 2 runs at 60 fps with about 5–7 ms of emulation per frame.

## Requirements (to build)

- Jailbroken iPad on iOS 8 with **OpenSSH** and **BTstack** (Cydia package `ch.ringwald.btstack` 1.1)
- Mac with **Xcode 13.4.1** extracted (only the toolchain is used; newer versions can't build armv7)
- `ldid` (`brew install ldid`)
- SSH access to the iPad as root, ideally with a key

The app is installed in `/Applications`, outside the sandbox, because that is the only way it can talk to BTdaemon.

## Build and install

```bash
export X13=/path/to/Xcode-13.4.1.app/Contents/Developer   # default: ../Xcode-13.4.1.app
export IPAD=192.168.x.x                                    # the iPad's IP

./build.sh            # builds build/MD16.app
./build.sh install    # builds and installs on the iPad over SSH
./build.sh roms       # sends the ROMs in ../roms to the iPad
```

The first time, `build.sh` downloads Genesis Plus GX (pinned commit) and builds the core, which takes a few minutes. It also copies `libBTstack.dylib` from the iPad and makes a link stub: the package's dylib only has armv6 and arm64 slices, so the stub relabels armv6 as armv7 (`tools/make_link_stub.py`).

## Usage

- ROMs live in `Documents/MD16/roms`. Send them with **Upload ROMs** or `./build.sh roms`. You need your own: no ROMs come with this project.
- **Controller:**
  1. Keep iOS Bluetooth **off** and **Wi-Fi on**. On the iPad 3 they share the same chip, and BTstack doesn't start without Wi-Fi.
  2. Put the controller in pairing mode.
  3. Tap Controller → Search for controllers, tap your controller, then Set up buttons.
- **In-game menu:** button in the top-right corner, or a controller button set up as "Menu".

## Licenses

- The code in this repository is released under the **MIT License** (see [LICENSE](LICENSE)). The icon is original, made for the project.
- **rcheevos** (RetroAchievements runtime) is © RetroAchievements, MIT License. It is downloaded at build time (tag pinned in `build.sh`).
- **Genesis Plus GX** is not included here: it is downloaded at build time and follows its own **non-commercial** license.
- The packaged app (the `.deb` on the Cydia repo) is linked with Genesis Plus GX, so the whole binary is also bound by that non-commercial license.
- The headers in `vendor/btstack` are from BTstack (© BlueKitchen GmbH / Matthias Ringwald) and follow the BTstack license.
