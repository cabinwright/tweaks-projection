# tweaks-projection

A tweak pack for [Cabinwright](https://github.com/cabinwright/store): wireless Android Auto and
CarPlay, phone navigation directions in the instrument cluster, and two fixes that keep wireless
projection working. Package `tweaks.projection`, installed from the Cabinwright store; its tweaks
show up in the **Tweaks** app, and the store's runner runs them. Written for the 2023 Kia EV6
(Gen5W, firmware `CVEV.USA.0000.V015.012.260507`) and matched to that firmware exactly.

It is a port of what [HMG Leafia Plus](https://github.com/VysseCodes/HMG-Leafia-Plus)'s package
`wireless.carplay.aa` (v1.0.2) installs on that car, file for file and checksum for checksum, so
a car that runs Leafia's package can move to this pack without anything changing (see
[docs/migration.md](docs/migration.md)).

| Tweak | Kind | What it does |
|---|---|---|
| Wireless Android Auto and CarPlay (`wireless-projection`) | oneshot, changes system files | Phones connect over the car's own Wi-Fi, without a cable. |
| Navigation directions in the instrument cluster (`cluster-directions`) | oneshot, changes system files | The phone's next turn in the cluster and head-up display. |
| ADB TCP and wireless projection together (`adb-tcp-hotspot`) | oneshot, changes system files | The Engineering Mode "ADB TCP" switch no longer breaks wireless projection. |
| Reconnect wireless Android Auto (`aa-reconnect`) | service | Restarts the Android Auto receiver when it gets stuck after the car's hotspot was used. |

Needs cabinwright.store 1.0 or newer.

## What each tweak changes

Every change is declared in the tweak's `tweak.conf` (`need=` lines, each with the reason the
store shows before you agree), and goes through the store's `kt`, which allows only those.

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
directions off the status says so. The two tweaks can be turned on and off in any order: the
runner keeps each tweak's build of these files in its place, so turning one off leaves the
other's.

**ADB TCP and wireless projection together**: with ADB TCP on, init runs
`/system/bin/ifconfig eth0 192.168.0.123` at every start, a /24 inside the hotspot's
192.168.0.0/24, and phones never connect. This replaces the `ifconfig -> toolbox` link with a
four-line script that gives exactly that call a /32 netmask and passes everything else to
`toolbox`, so the clash never happens. If eth0 already has the /24, it runs the stock
`set_adb_ip` again so the fix works at once. Turning it off puts the link back.

**Reconnect wireless Android Auto**: reads the receiver's log for its "Already AA Starting
mode" loop and restarts the receiver (`com.google.android.projection.sink`) when it is stuck.

## How it works

Tweaks run as their own unprivileged user. They read `/system`, write only their own data folder,
and make every change through `kt`. The runner records each change before it is made and undoes
it when the tweak is turned off, so the packs carry no backups of their own.

No manufacturer code is shipped. `lib/leafia/` holds Leafia's deltas (`.lpd`) and byte recipes.
On the car, `lib/projpatch.jar` (this pack's patch tool, `patch/`, run with `app_process`)
rebuilds each changed file from the car's own stock copy, and `dexopt` optimizes the rebuilt
apps, all in the tweak's data folder. Nothing goes in unless the source has the exact stock md5
and the result has the md5 that Leafia's own build gives. Nothing reboots: changes show after
the next head unit start.

A file Leafia's package already changed is taken over instead (`kt file adopt`): the runner
records the stock copy from Leafia's backups (`/data/nemesis/backup/projection.tbt` and the
others) as the original, so turning the tweak off restores stock just the same.

`status.sh` only reads checksums and properties, and it reports Leafia's install as "on".

| Path | What |
|---|---|
| `package/NEMESIS.data` | `id=tweaks.projection`, no apps, no services |
| `package/tweaks/<id>/` | `tweak.conf` and scripts |
| `package/lib/projection.sh` | shared code of the two projection tweaks |
| `package/lib/projection-adopt.sh` | taking over what Leafia's package installed |
| `package/lib/leafia/` | Leafia's patch data, `libev6aac.so`, the two feature files |
| `package/lib/ifconfig` | the wrapper `adb-tcp-hotspot` installs |
| `patch/` | `projpatch`: md5, delta, zipadd (from Tweaks' tweakpatch), lpzipadd, recipe check/apply |
| `native/ev6aac/` | source of `libev6aac.so` (Leafia's, unchanged) |
| `tools/check-tweaks.sh` | checks every `tweak.conf` (keys, needs, `disable.sh` where needed) |
| `tests/host-test.sh` | runs every tweak against a mock `/system` on a computer |
| `tests/fake-kt.sh` | the stand-in `kt` and runner journal the host test uses |

## Build

```sh
sh build.sh     # -> dist/tweaks.projection.zip
```

Needs the Android SDK (build-tools 29.0.2, platform 23), a JDK (8 or newer) and `zip`.
`build.sh` also runs `tools/check-tweaks.sh`. CI lints with the Cabinwright menu repo's
`api/tools/lint.sh` (ShellCheck, javac), pinned at `v1.0`.
`libev6aac.so` is committed. Rebuilding it needs clang and lld (`native/ev6aac/build.sh`;
Ubuntu clang 18.1.3 reproduces it byte for byte).

## Test

```sh
sh tests/host-test.sh <stock dir>
```

`<stock dir>` holds the car's stock files laid out like Leafia's backups (see the script). They
are the manufacturer's files, so keep them private. The scripts run as the runner runs them,
with `/system` read-only to them and a stand-in `kt` (`tests/fake-kt.sh`) that refuses anything
a tweak didn't declare and keeps the runner's journal. The test passes only if every result
matches the checksums Leafia's install has on the car, turning the tweaks off in any order
restores `/system` byte for byte, Leafia's install is taken over without a change, a failed
install can be turned off cleanly, unknown files are left alone, and every `kt` call was
declared.

## License

AGPL-3.0-or-later (see `LICENSE`), Copyright (c) 2026 hazptr. Includes work from HMG Leafia Plus
(GPL-3.0) and from the NEMESIS community packages `wireless.projection` and `projection.tbt`
(AGPL-3.0): see `NOTICE.md`. Not affiliated with Hyundai, Kia, Apple or Google. Modifying your
head unit is at your own risk.
