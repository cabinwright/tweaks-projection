# Notices

tweaks-projection is licensed under the GNU Affero General Public License v3.0 or later
(`LICENSE`), Copyright (c) 2026 hazptr. It contains work from the projects below, which keep
their authors' licences and notices.

## HMG Leafia Plus (GPL-3.0)

https://github.com/VysseCodes/HMG-Leafia-Plus, by VysseCodes and contributors, licensed under
the GNU General Public License v3.0. GPL-3.0 section 13 allows it to be combined with AGPL-3.0
code, and its parts stay under the GPL-3.0.

From it, taken from the tree at commit 08f4436 (package v1.0.5 on the car):

- `package/lib/leafia/carplay-core-wifi.recipe`, `carplay-audio-formats.recipe`,
  `carplay-utils-converter.recipe` (from `recipes/`), unchanged apart from a first comment line
  that names where they come from.
- `package/lib/leafia/ev6/*.lpd` (from `patches/ev6/`), `libautoreceiver_infobank.tbt.lpd` and
  `HKMC_BtSettings.menu.9096dec5.lpd` (from `patches/common/`), unchanged.
- `package/lib/leafia/libev6aac.so` (from `packages/wireless-carplay-aa/comp/4_audio/files/`),
  unchanged, and its source in `native/ev6aac/` (from `src/ev6aac/`), unchanged apart from a
  header naming where it comes from.
- `patch/src/dev/cabinwright/tweaks/projection/patch/Recipe.java` and the `lpzipadd` command in
  `Main.java`: a Java version of the recipe check/apply and zipadd of Leafia's `lpatch`
  (`tools/lpatch/lpatch.c`, GPL-3.0-or-later), with the same formats and results.
- `package/lib/projection.sh`: a rewrite of the install, uninstall and checksum logic of
  `packages/wireless-carplay-aa` (scripts and parts `1_projection` to `5_menu`), including its
  `apps_hold`/`apps_release` and `prefill_dalvik`.

Leafia's notice credits as its own work: `lpatch`, the recipes and recipe tooling, the CarPlay
Bluetooth bridge, the CarPlay Wi-Fi and audio patches and the `libev6aac.so` audio converter.

Community contribution credited by Leafia, included in the EV6 bridge and turn-by-turn builds
rebuilt here: **CarPlay turn-by-turn maneuver fix** (the DiPO route-guidance parser wrote
maneuver indexes into a copy of the index array, so every maneuver read as -1 and CarPlay
guidance never reached the cluster), contributed by
[Isaac Wisdom](https://github.com/isaacwisdom).

At runtime, `libev6aac.so` loads the head unit's own `libstagefright_soft_aacdec.so` (Fraunhofer
FDK AAC) and `libopus.so`. Nothing from them is bundled.

## NEMESIS and its community packages (AGPL-3.0)

The pack installs and runs through **NEMESIS** by xwtk (https://github.com/xwtk/hmg_nemesis),
licensed under the GNU Affero General Public License v3.0.

Leafia's package builds on these NEMESIS community packages, whose scripts and builds remain
under the AGPL-3.0, and so does this port of it:

- **Enable Wireless Features** (`wireless.projection`): Leafia's slimmed copy of its scripts
  (hotspot only, region folder from `ro.mobis.targetdir`) is what the `wireless-projection`
  tweak reproduces: the featurexml.cfg change (`package/lib/leafia/featurexml.on.lpd` /
  `featurexml.off.lpd`, made here from the car's file and holding none of its bytes) and the
  feature files `com.hkmc.software.connectivity.androidauto_wireless.xml` and
  `com.hkmc.software.connectivity.carplay_wireless.xml` (unchanged).
- **Turn-by-Turn Guidance for Phone Projection** (`projection.tbt`): its app builds are what the
  turn-by-turn deltas rebuild (`*.tbt.lpd`), and the base of the CarPlay bridge builds
  (`*.bridge.lpd`).

## Cabinwright tweaks (MIT)

https://github.com/cabinwright/tweaks, Copyright (c) 2026 hazptr, MIT License. Copied from it:
the `md5`, `delta` and `zipadd` commands of `patch/src/dev/cabinwright/tweaks/projection/patch/Main.java`
and `patch/build.sh` (from its `patch/`), and the `aa-reconnect` tweak (from its `aa-recover`).
The two featurexml deltas were made with its `tools/mkdelta.py`, and `adb-tcp-hotspot` replaces
its `eth0-guard` with a fix at the cause.
