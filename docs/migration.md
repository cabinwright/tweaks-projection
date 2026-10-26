# Moving a car from Leafia's `wireless.carplay.aa` to `tweaks.projection`

For the 2023 EV6 (`CVEV.USA.0000.V015.012.260507`) running HMG Leafia Plus v1.0.2 with all five
parts (`/data/nemesis/wireless.carplay.aa.parts` = `1_projection 2_tbt 3_bridge 4_audio 5_menu`).
The goal is that wireless projection never stops working. Nothing in steps 1 to 4 writes
`/system`, kills an app or reboots. Commands run over ADB (`adb shell "..."`); `nemesis root -c`
runs as root.

## What the car has now (read on 2026-10-25)

| File | md5 on the car | Pack state |
|---|---|---|
| `HKMC_GPM.apk` | `329946b20cd51855d7da6056dbfbc4db` | turn-by-turn build |
| `HKMC_Navi_ExSL.apk` | `496ef30d2c7f8260f25bd14d62c646c2` | turn-by-turn build |
| `HKMC_DiPO.apk` | `cd240c40c923eaff5da5b41a7aacbbe6` | bridge build |
| `Iap2ServerApp.apk` | `75d7fea4d2009be6aa5c840118f58c94` | bridge build |
| `HKMC_BtSettings.apk` | `93ecaa97597a79be2a10728e45c72b33` | menu fix |
| `libautoreceiver_infobank.so` | `c08410a8d32a615b1aa805cd8a243d52` | turn-by-turn build |
| `libCarPlayCore.so` | `c537d5849f1fa881b0c79333ecfd83e4` | recipe applied |
| `libCarPlayAudio.so` | `81402f9bb2c74840f953c05d27291b23` | recipe applied |
| `libCarPlayUtils.so` | `8bdf0a2a178abf79a2cbda881d5e8264` | recipe applied |
| `libev6aac.so` | `badc26bd4c40a1c3e543b733a8ec5028` | Leafia's build |
| `onebin/cvev_us/featurexml.cfg` | `9ff5d15286e1af75e2b7fbf9ca2502d9` | wireless lines commented |
| `permissions/...androidauto_wireless.xml` | `fa91812d3eeee415768018ab6ee6804a` | added |
| `permissions/...carplay_wireless.xml` | `95ff801a064526de56059dba10960b05` | added |
| `persist.sys.iap2.wifi`, `persist.iap2.iden.wireless` | `t`, `t` | on |
| `build.prop`, `wpa_supplicant*.conf`, `wifihotspot.xml` | same as Leafia's stock snapshot | untouched |
| `/system/bin/ifconfig` | link to `toolbox` | stock |

The pack's status scripts, run read-only on the car with its own shell, report
`cluster-directions` "on phone directions in the cluster" and `wireless-projection` "on phones
connect without a cable". Leafia's stock backups in `/data/nemesis/backup/{projection.tbt,
wireless.carplay.bt, carplay.wifi.audio, projection.menu}` all have the stock md5s.

## What uninstalling Leafia's package normally does (don't)

`nemesis uninstall wireless.carplay.aa` (or NEMESIS Manager > Uninstall) runs its
`scripts/preun.sh` from `/data/nemesis/apps/wireless.carplay.aa` and then deletes that folder.
It doesn't reboot. Undoing the parts newest first, it does this:

1. `5_menu`: stock `HKMC_BtSettings.apk`/`.odex` back from `backup/projection.menu`; the backup
   is removed.
2. `4_audio`: stock `libCarPlayAudio.so` and `libCarPlayUtils.so` back; `libev6aac.so` deleted.
3. `3_bridge`: the turn-by-turn builds of `HKMC_DiPO`/`Iap2ServerApp` back (from
   `backup/wireless.carplay.bt`), stock `libCarPlayCore.so` back, and `persist.sys.iap2.wifi` and
   `persist.iap2.iden.wireless` set to `f`.
4. `2_tbt`: stock `HKMC_GPM`, `HKMC_DiPO`, `Iap2ServerApp`, `HKMC_Navi_ExSL` (apk and odex) and
   `libautoreceiver_infobank.so` back.
5. `1_projection`: runs its restore twice (preun and postun). It writes back the stock
   featurexml.cfg and deletes the two wireless feature files. It also rewrites build.prop,
   `wpa_supplicant*.conf` and `wifihotspot.xml` with identical bytes, and sets
   `persist.ium.support` back to its install-time value `carplay` (the car shows `iap1` today, so
   this one changes). It removes `/data/property/persist.wifi.state` and sets `wifi_on` to 0
   (already 0). Each run ends with `am force-stop com.daudio.app.phoneprojection` and
   `am force-stop com.daudio.app.dipo`, **which drops any running Android Auto or CarPlay
   session at once**.
6. ADB: `persist.adb.tcp.port` set to empty and `persist.service.adb.tcp.enable` to 1 (it is 1
   already).

Every Leafia backup folder is deleted along the way. Running apps keep their old code until the
next start, but after the next start the car has no wireless projection and no phone directions.

With this pack installed and both switches on, tweaksd would notice within its 5-minute status
recheck that both tweaks went "off" and run `enable.sh` for both. They would rebuild the same
files from the now-stock `/system`, so the car would heal before a restart. But the session drop
in step 5, the window, a second full rewrite of `/system` and the `persist.ium.support` change
are why the steps below detach Leafia's package instead of undoing it.

## Steps

**0. Prerequisites.** cabinwright.tweaks 1.4 or newer (or kia.tweaks 1.2 or newer, its earlier name) installed and running.
Build `dist/tweaks.projection.zip`.

**1. Install the pack.** It has no install hooks, so nothing on `/system` changes.

```sh
adb push dist/tweaks.projection.zip /data/local/tmp/
adb shell "nemesis install /data/local/tmp/tweaks.projection.zip"
```

**2. Let the Tweaks app record the switches.** Open the Tweaks app once. The app records each
system tweak's switch from its first reported state, so expect:

| Tweak | State | Switch recorded |
|---|---|---|
| Wireless Android Auto and CarPlay | on: phones connect without a cable | on |
| Navigation directions in the instrument cluster | on: phone directions in the cluster | on |
| ADB TCP and wireless projection together | off: stock | off |
| Reconnect wireless Android Auto | on (service, default on) | on |

`Reconnect wireless Android Auto` starts at once. While Tweaks' `aa-recover` runs, it only
logs and leaves restarts to it. Check `/data/nemesis/cabinwright/tweaks/state.json`: both projection
tweaks should show `"want":"on","state":"on"`. If either shows `error`, stop here and roll back
(uninstall the pack); nothing was changed.

**3. Take over Leafia's stock backups.** This writes only `/data/nemesis/backup/tweaks.projection`.

```sh
adb shell "nemesis root -c 'sh /data/nemesis/apps/tweaks.projection/lib/projection-adopt.sh'"
# expect: all stock files are in /data/nemesis/backup/tweaks.projection
```

**4. Detach Leafia's package without its undo.** Point its uninstall at an empty part list and
drop its ADB record. Its own `preun.sh` then has nothing to undo: `run_part none preun` finds
no `comp/none` and returns, and `adb_net_restore` finds no record. NEMESIS then deletes only
`/data/nemesis/apps/wireless.carplay.aa`.

```sh
adb shell "nemesis root -c 'mkdir -p /data/nemesis/backup/leafia-detached && cp /data/nemesis/wireless.carplay.aa.parts /data/nemesis/wireless.carplay.aa.adb /data/nemesis/backup/leafia-detached/'"
adb shell "nemesis root -c 'echo none > /data/nemesis/wireless.carplay.aa.parts && rm /data/nemesis/wireless.carplay.aa.adb'"
adb shell "nemesis uninstall wireless.carplay.aa"
```

Check: `/data/nemesis/wireless.carplay.aa.log` ends with `undoing: none` and `all parts back
to stock` (Leafia's wording; nothing was undone). The md5s in the table above are unchanged, and
both tweaks still say "on". `persist.adb.tcp.port` stays 5555. Leafia's backup folders stay
where they are; they can be deleted later, since step 3 copied them.

**5. ADB TCP fix.** In the Tweaks app, turn on **ADB TCP and wireless projection together**
(it asks first). It replaces the `ifconfig` link at once, and if eth0 has the /24 right now it
narrows it at once too. Then turn off Tweaks' **Wireless projection with ADB TCP**
(`eth0-guard`). From then on the stock `set_adb_ip` gives eth0 a /32 at every start, so there's
no gap.

**6. Stuck-receiver fix.** Turn off Tweaks' **Fix wireless Android Auto not connecting**
(`aa-recover`). The pack's **Reconnect wireless Android Auto** is already running and acts on
the next stuck loop as soon as the old one has stopped, so there's no gap.

**7. Restart when convenient.** It isn't required, since no file changed. Afterwards check
wireless Android Auto, wireless CarPlay with audio, directions in the cluster, and that all four
tweaks still show "on".

**8. Tweaks' next release** (kia.tweaks 1.3) drops `eth0-guard` and `aa-recover`. If a car skipped steps 5 and
6, the update still ends cleanly: tweaksd stops every running `run.sh` when it restarts and
never starts tweaks whose folders are gone. The pack's `aa-reconnect` then stops deferring by
itself. Turn on `adb-tcp-hotspot` before updating Tweaks, or eth0 is unguarded from the
next start.

## Rollback

- **Before step 4:** `adb shell "nemesis uninstall tweaks.projection"`. The pack has no hooks,
  and its projection tweaks never ran a script, so Leafia's install is exactly as before.
  `rm -rf /data/nemesis/backup/tweaks.projection` if you like. If step 5 was done, turn
  that tweak off first.
- **After step 4, keeping the pack:** nothing to do; the pack owns the install. To go back to
  stock, turn both projection tweaks off (they restore the stock files from
  `/data/nemesis/backup/tweaks.projection`), then restart.
- **After step 4, back to Leafia's package:** turn both projection tweaks off, restart, then
  install Leafia's zip from USB as usual. Its installer checks for stock files, so it must
  start from stock.
- **Without the app:** the same scripts by hand:
  `nemesis root -c 'sh /data/nemesis/apps/tweaks.projection/tweaks/wireless-projection/disable.sh'`
  (and `cluster-directions/disable.sh`, `adb-tcp-hotspot/disable.sh`).
- The step 4 records are in `/data/nemesis/backup/leafia-detached/` if ever needed.
