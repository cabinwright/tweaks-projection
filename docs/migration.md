# Moving a car from Leafia's `wireless.carplay.aa` to `tweaks.projection`

For the 2023 EV6 (`CVEV.USA.0000.V015.012.260507`) running HMG Leafia Plus v1.0.2 with all five
parts (`/data/nemesis/wireless.carplay.aa.parts` = `1_projection 2_tbt 3_bridge 4_audio 5_menu`).
The goal is that wireless projection never stops working. Nothing in steps 1 to 3 writes
`/system`, kills an app or reboots. Commands run over ADB (`adb shell "..."`); `nemesis root -c`
runs as root.

## What Leafia's package leaves on the car

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

The pack's status scripts report this as `cluster-directions` "on phone directions in the
cluster" and `wireless-projection` "on phones connect without a cable". Leafia's stock backups
in `/data/nemesis/backup/{projection.tbt, wireless.carplay.bt, carplay.wifi.audio,
projection.menu}` have the stock md5s.

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

Once the pack has taken the files over, that undo would put the stock files back underneath it,
and the store would report both tweaks as "Changed by something else". The session drop in step
5, a second full rewrite of `/system` and the `persist.ium.support` change are why the steps
below detach Leafia's package instead of undoing it.

## Steps

**0. Prerequisites.** cabinwright.store 1.0 or newer installed.

**1. Install the pack** from the store. It has no install hooks, so nothing on `/system`
changes. The store lists each tweak's needs before you agree.

**2. Take over Leafia's install.** In the Tweaks app, turn on **Wireless Android Auto and
CarPlay** first, then **Navigation directions in the instrument cluster**. Each finds Leafia's
builds and takes them over: the store's runner records Leafia's stock copies (each checked
against its stock md5) as the originals, so turning a tweak off later restores stock. Each says
"already installed by HMG Leafia Plus's package: taken over, nothing changed", and both show "on".

Turned on the other way round, the directions tweak refuses ("turn on Wireless Android Auto and
CarPlay first") and changes nothing: the CarPlay apps carry Leafia's wireless build, which only
the wireless tweak can take over.

If either fails with anything else, stop here: nothing on `/system` changed. **Reconnect
wireless Android Auto** is on by default and starts at once.

**3. Detach Leafia's package without its undo.** Point its uninstall at an empty part list and
drop its ADB record. Its own `preun.sh` then has nothing to undo: `run_part none preun` finds
no `comp/none` and returns, and `adb_net_restore` finds no record. NEMESIS then deletes only
`/data/nemesis/apps/wireless.carplay.aa`. These are root commands over ADB, which the store's
lockdown keeps to NEMESIS Manager: turn **Lockdown** off in the store's settings for this step,
and back on afterwards.

```sh
adb shell "nemesis root -c 'mkdir -p /data/nemesis/backup/leafia-detached && cp /data/nemesis/wireless.carplay.aa.parts /data/nemesis/wireless.carplay.aa.adb /data/nemesis/backup/leafia-detached/'"
adb shell "nemesis root -c 'echo none > /data/nemesis/wireless.carplay.aa.parts && rm /data/nemesis/wireless.carplay.aa.adb'"
adb shell "nemesis uninstall wireless.carplay.aa"
```

Check: `/data/nemesis/wireless.carplay.aa.log` ends with `undoing: none` and `all parts back
to stock` (Leafia's wording; nothing was undone). The md5s in the table above are unchanged, and
both tweaks still say "on". `persist.adb.tcp.port` stays 5555 (tweaks-adb's `adb-wifi` reads
the copied ADB record to know Leafia set it). Leafia's backup folders stay where they are; the
runner keeps its own copies of the originals, so they can be deleted.

**4. Restart when convenient.** It isn't required, since no file changed. Afterwards check
wireless Android Auto, wireless CarPlay with audio, directions in the cluster, and that all four
tweaks still show "on".

## Rollback

- **Before step 2:** uninstall the pack from the store. It never ran a script, so Leafia's
  install is exactly as before.
- **After step 2, before step 3:** turning the tweaks off, or removing the pack, restores the
  stock files, under Leafia's package. To keep Leafia's install, leave both tweaks on and stop
  here; to go back to it fully, turn both tweaks off, restart, and uninstall and reinstall
  Leafia's package as usual.
- **After step 3, keeping the pack:** nothing to do; the pack owns the install. To go back to
  stock, turn both projection tweaks off (the runner puts the stock files back), then restart.
- **After step 3, back to Leafia's package:** turn both projection tweaks off, restart, then
  install Leafia's zip from USB as usual. Its installer checks for stock files, so it must
  start from stock.
- The step 3 records are in `/data/nemesis/backup/leafia-detached/` if ever needed.
