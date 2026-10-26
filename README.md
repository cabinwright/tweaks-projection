# tweaks-projection

A tweak pack for [Cabinwright tweaks](https://github.com/cabinwright/tweaks): wireless Android Auto and
CarPlay, phone navigation directions in the instrument cluster, and two fixes that keep wireless
projection working. NEMESIS package `tweaks.projection`; its tweaks show up in the **Tweaks** app
and its `tweaksd` runs them. Written for the 2023 Kia EV6 (Gen5W, firmware
`CVEV.USA.0000.V015.012.260507`) and matched to that firmware exactly.

It is a port of what [HMG Leafia Plus](https://github.com/VysseCodes/HMG-Leafia-Plus)'s package
`wireless.carplay.aa` (v1.0.2) installs on that car, file for file and checksum for checksum, so
a car that runs Leafia's package can move to this pack without anything changing (see
[docs/migration.md](docs/migration.md)).

| Tweak | Kind | What it does |
|---|---|---|
| Wireless Android Auto and CarPlay (`wireless-projection`) | oneshot, system | Phones connect over the car's own Wi-Fi, without a cable. |
| Navigation directions in the instrument cluster (`cluster-directions`) | oneshot, system | The phone's next turn in the cluster and head-up display. |
| ADB TCP and wireless projection together (`adb-tcp-hotspot`) | oneshot, system | The Engineering Mode "ADB TCP" switch no longer breaks wireless projection. |
| Reconnect wireless Android Auto (`aa-reconnect`) | service | Restarts the Android Auto receiver when it gets stuck after the car's hotspot was used. |

Needs cabinwright.tweaks 1.4 or newer. With kia.tweaks (its name before 1.4) the pack works
the same, from kia.tweaks 1.2 on; the switch to cabinwright.tweaks leaves its tweaks as they are.

## What each tweak changes

**Wireless Android Auto and CarPlay**: the wireless CarPlay/Android Auto lines in
`/system/onebin/cvev_us/featurexml.cfg` commented out (hotspot only, no Wi-Fi client), the two
wireless feature files in `/system/etc/permissions`, the CarPlay Bluetooth bridge builds of
`HKMC_DiPO` and `Iap2ServerApp`, `libCarPlayCore.so` (accepts Wi-Fi sessions),
`libCarPlayAudio.so` and `libCarPlayUtils.so` (AAC and Opus over Wi-Fi) plus `libev6aac.so`, the
Phone Projection menu fix in `HKMC_BtSettings`, and `persist.sys.iap2.wifi` /
`persist.iap2.iden.wireless` = `t`.

**Navigation directions in the instrument cluster**: the turn-by-turn builds of `HKMC_GPM`,
`HKMC_Navi_ExSL`, `HKMC_DiPO`, `Iap2ServerApp` and `libautoreceiver_infobank.so`.

`HKMC_DiPO` and `Iap2ServerApp` are shared. Leafia's bridge build is made on top of the
turn-by-turn build, so while wireless is on they carry CarPlay's directions as well, and with
directions off the status says so.

**ADB TCP and wireless projection together**: with ADB TCP on, init runs
`/system/bin/ifconfig eth0 192.168.0.123` at every start, a /24 inside the hotspot's
192.168.0.0/24, and phones never connect. This replaces the `ifconfig -> toolbox` link with a
four-line script that gives exactly that call a /32 netmask and passes everything else to
`toolbox`, so the clash never happens. Turning it off puts the link back.

**Reconnect wireless Android Auto**: watches for the receiver's "Already AA Starting mode"
loop and restarts it, as Tweaks' `aa-recover` did (which it replaces, see the migration).

## How it works

No manufacturer code is shipped. `lib/leafia/` holds Leafia's deltas (`.lpd`) and byte recipes.
On the car, `lib/projpatch.jar` (this pack's patch tool, `patch/`, run with `app_process`)
rebuilds each changed file from the car's own stock copy. It writes nothing unless the source
has the exact stock md5 and the result has the md5 that Leafia's own build gives. The stock
files are backed up first to `/data/nemesis/backup/tweaks.projection`; they're taken from
Leafia's own backups when its package already replaced them. Turning a tweak off puts back the
exact stock bytes. Nothing reboots: changes show after the next head unit start.

`status.sh` only reads checksums and properties, and it reports Leafia's install as "on". The
Tweaks app records a system tweak's switch from its first reported state, so installing this
pack over Leafia's install changes nothing.

| Path | What |
|---|---|
| `package/NEMESIS.data` | `id=tweaks.projection`, no apps, no services |
| `package/tweaks/<id>/` | `tweak.conf` and scripts (the Tweaks format) |
| `package/lib/projection.sh` | shared code of the two projection tweaks |
| `package/lib/projection-adopt.sh` | copies Leafia's stock backups into this pack's backup |
| `package/lib/leafia/` | Leafia's patch data, `libev6aac.so`, the two feature files |
| `package/lib/ifconfig` | the wrapper `adb-tcp-hotspot` installs |
| `patch/` | `projpatch`: md5, delta, zipadd (from Tweaks' tweakpatch), lpzipadd, recipe check/apply |
| `native/ev6aac/` | source of `libev6aac.so` (Leafia's, unchanged) |
| `tests/host-test.sh` | runs every tweak against a mock `/system` on a computer |

## Build

```sh
sh build.sh     # -> dist/tweaks.projection.zip
```

Needs the Android SDK (build-tools 29.0.2, platform 23), a JDK (8 or newer) and `zip`.
`libev6aac.so` is committed. Rebuilding it needs clang and lld (`native/ev6aac/build.sh`;
Ubuntu clang 18.1.3 reproduces it byte for byte).

## Test

```sh
sh tests/host-test.sh <stock dir>
```

`<stock dir>` holds the car's stock files laid out like Leafia's backups (see the script). They
are the manufacturer's files, so keep them private. The test passes only if every result matches the
checksums Leafia's install has on the car, turning off restores `/system` byte for byte, a
failed install is undone, and unknown files are left alone.

## License

AGPL-3.0-or-later (see `LICENSE`), Copyright (c) 2026 hazptr. Includes work from HMG Leafia Plus
(GPL-3.0) and from the NEMESIS community packages `wireless.projection` and `projection.tbt`
(AGPL-3.0): see `NOTICE.md`. Not affiliated with Hyundai, Kia, Apple or Google. Modifying your
head unit is at your own risk.
