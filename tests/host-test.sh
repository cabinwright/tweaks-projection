#!/bin/sh
# Host test: runs the pack's tweaks against a mock /system made from a 2023 Kia EV6 (260507)'s
# stock files, the way the store's runner runs them: as scripts that can't write /system, with
# $TWEAK_ID, $TWEAK_DIR and $TWEAK_DATA set and a stand-in kt (tests/fake-kt.sh) that checks
# every call against the tweak's need= lines and keeps the runner's journal. Turning a tweak off
# is its disable.sh, if any, then the journal replayed. The pack's projpatch runs on the host
# JVM; md5, getprop, setprop and dexopt are stubs. Passes only if every result has the
# checksums HMG Leafia Plus's own install has on the car, turning off restores /system byte for
# byte in any order, Leafia's install is taken over without a change, and no tweak calls kt
# for something it didn't declare.
#
# usage: tests/host-test.sh <stock dir>
#   <stock dir> is laid out like Leafia's backups on the car (adb pull /data/nemesis/backup):
#   projection.tbt/ (HKMC_GPM, HKMC_DiPO, Iap2ServerApp, HKMC_Navi_ExSL .apk/.odex and
#   libautoreceiver_infobank.so), wireless.carplay.bt/libCarPlayCore.so,
#   carplay.wifi.audio/libCarPlayAudio.so and libCarPlayUtils.so, projection.menu/
#   HKMC_BtSettings.apk/.odex, wireless.projection/featurexml.cfg. The manufacturer's files: keep them private.
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
STOCK=$(cd "$1" && pwd)
T=$HERE/package/tweaks
W=$(mktemp -d)
trap 'chmod -R u+w "$W"; rm -rf "$W"' EXIT
FAILS=0


mkdir -p "$W/kp" "$W/stubs" "$W/priv"
javac -nowarn -d "$W/kp" "$HERE"/patch/src/app/cabinwright/tweaks/projection/patch/*.java 2>/dev/null
REAL_MD5=$(command -v md5sum || command -v md5)
REAL_CAT=$(command -v cat)
md5of() { case "$REAL_MD5" in *md5sum) md5sum "$1" | cut -d' ' -f1 ;; *) "$REAL_MD5" -q "$1" ;; esac; }
cat >"$W/stubs/md5" <<EOF
#!/bin/sh
[ -f "\$1" ] || { echo "could not open \$1" >&2; exit 1; }
case "$REAL_MD5" in *md5sum) s=\$($REAL_MD5 "\$1" | cut -d' ' -f1) ;; *) s=\$($REAL_MD5 -q "\$1") ;; esac
echo "\$s  \$1"
EOF
cat >"$W/stubs/getprop" <<'EOF'
#!/bin/sh
cat "$KT_TEST_ROOT/props/$1" 2>/dev/null
EOF
# only kt has setprop
cat >"$W/priv/setprop" <<'EOF'
#!/bin/sh
mkdir -p "$KT_TEST_ROOT/props" "$KT_TEST_ROOT/data/property"
printf '%s' "$2" > "$KT_TEST_ROOT/props/$1"
case "$1" in persist.*) printf '%s' "$2" > "$KT_TEST_ROOT/data/property/$1" ;; esac
EOF
printf '#!/bin/sh\nexit 0\n' >"$W/stubs/sleep"
cat >"$W/stubs/cat" <<EOF
#!/bin/sh
case "\$1" in /proc/sys/kernel/random/boot_id) echo test-boot ;; *) $REAL_CAT "\$@" ;; esac
EOF
cp "$HERE/tests/fake-kt.sh" "$W/stubs/kt"
chmod 755 "$W"/stubs/* "$W"/priv/*

export KT_TEST_ROOT="$W/root" KT_JOURNAL="$W/journal" KT_LOG="$W/kt.log" KT_TEST_SETPROP="$W/priv/setprop"
export KT_TEST_KP="java -cp $W/kp app.cabinwright.tweaks.projection.patch.Main"
export PATH="$W/stubs:/usr/bin:/bin:/usr/sbin:/sbin"
M=$KT_TEST_ROOT

mock() {   # a stock /system, read-only to the scripts, and a runner with nothing recorded
    [ -d "$M" ] && chmod -R u+w "$M"
    rm -rf "$M" "$KT_JOURNAL" "$W/data"
    : >"$KT_LOG"
    mkdir -p "$M/system/app" "$M/system/lib" "$M/system/onebin/cvev_us" "$M/system/etc/permissions" \
        "$M/system/bin" "$M/data/nemesis/backup" "$M/data/property" "$M/props"
    for a in HKMC_GPM HKMC_DiPO Iap2ServerApp HKMC_Navi_ExSL; do cp "$STOCK/projection.tbt/$a.apk" "$STOCK/projection.tbt/$a.odex" "$M/system/app/"; done
    cp "$STOCK"/projection.menu/HKMC_BtSettings.apk "$STOCK"/projection.menu/HKMC_BtSettings.odex "$M/system/app/"
    cp "$STOCK/projection.tbt/libautoreceiver_infobank.so" "$STOCK/wireless.carplay.bt/libCarPlayCore.so" \
        "$STOCK/carplay.wifi.audio/libCarPlayAudio.so" "$STOCK/carplay.wifi.audio/libCarPlayUtils.so" "$M/system/lib/"
    cp "$STOCK/wireless.projection/featurexml.cfg" "$M/system/onebin/cvev_us/"
    # a deterministic stand-in for dexopt
    cat >"$M/system/bin/dexopt" <<'EOF'
#!/bin/sh
[ "$1" = --preopt ] || exit 1
{ echo odex; cat "$2"; } > "$3"
EOF
    chmod 755 "$M/system/bin/dexopt"
    find "$M/system" -type d -exec chmod a-w {} +
}

sums() {
    (cd "$M" && find system -type f ! -name dexopt | sort | while read -r f; do echo "$(md5of "$f") $f"; done
     for p in persist.sys.iap2.wifi persist.iap2.iden.wireless; do
         echo "prop $p=[$(cat props/$p 2>/dev/null)] file=$([ -e data/property/$p ] && echo y || echo n)"
     done)
}

# what HMG Leafia Plus's wireless.carplay.aa v1.0.2 left on the car (md5s read from the car)
LEAFIA="329946b20cd51855d7da6056dbfbc4db system/app/HKMC_GPM.apk
cd240c40c923eaff5da5b41a7aacbbe6 system/app/HKMC_DiPO.apk
75d7fea4d2009be6aa5c840118f58c94 system/app/Iap2ServerApp.apk
496ef30d2c7f8260f25bd14d62c646c2 system/app/HKMC_Navi_ExSL.apk
93ecaa97597a79be2a10728e45c72b33 system/app/HKMC_BtSettings.apk
c08410a8d32a615b1aa805cd8a243d52 system/lib/libautoreceiver_infobank.so
c537d5849f1fa881b0c79333ecfd83e4 system/lib/libCarPlayCore.so
81402f9bb2c74840f953c05d27291b23 system/lib/libCarPlayAudio.so
8bdf0a2a178abf79a2cbda881d5e8264 system/lib/libCarPlayUtils.so
badc26bd4c40a1c3e543b733a8ec5028 system/lib/libev6aac.so
9ff5d15286e1af75e2b7fbf9ca2502d9 system/onebin/cvev_us/featurexml.cfg
fa91812d3eeee415768018ab6ee6804a system/etc/permissions/com.hkmc.software.connectivity.androidauto_wireless.xml
95ff801a064526de56059dba10960b05 system/etc/permissions/com.hkmc.software.connectivity.carplay_wireless.xml
prop persist.sys.iap2.wifi=[t] file=y
prop persist.iap2.iden.wireless=[t] file=y"

ok() { echo "  ok: $1"; }
bad() {
    echo "  FAILED: $1"
    FAILS=$((FAILS + 1))
}
# as <tweak> <command...>: runs a command with the tweak's runner environment
as() {
    id=$1
    shift
    mkdir -p "$W/data/$id"
    TWEAK_ID=$id TWEAK_DIR=$T/$id TWEAK_DATA=$W/data/$id "$@"
}
status() { echo "$(as cluster-directions sh "$T/cluster-directions/status.sh") | $(as wireless-projection sh "$T/wireless-projection/status.sh")"; }
expect() {   # <directions state> <wireless state>
    s=$(status)
    case "$s" in "$1 "*"| $2 "*) ok "status: $s" ;; *) bad "status: $s (want $1 / $2)" ;; esac
}
on() {   # <tweak> [fail]: enable.sh, as the runner runs it
    if as "$1" sh "$T/$1/enable.sh" >"$W/log" 2>&1; then
        if [ "$2" = fail ]; then
            bad "$1 on should have failed"
            cat "$W/log"
        else
            ok "$1 on: $(grep -v '^built\|^installed\|^took over\|^applied\|^kept\| on$' "$W/log" | tr '\n' ' ')"
        fi
    elif [ "$2" = fail ]; then
        ok "$1 on refused/failed as it should: $(grep FAIL "$W/log" | tr '\n' ' ')"
    else
        bad "$1 on"
        cat "$W/log"
    fi
}
off() {   # <tweak>: its disable.sh, then the runner's replay of its journal
    if [ -f "$T/$1/disable.sh" ]; then as "$1" sh "$T/$1/disable.sh" >/dev/null 2>&1 || bad "$1 disable.sh"; fi
    as "$1" kt --off "$1"
    ok "$1 off"
}
is_leafia() {
    sums | grep -v '\.odex$' | sort >"$W/now"
    echo "$LEAFIA" | sort >"$W/want"
    if diff "$W/want" "$W/now" >/dev/null; then ok "files match the car's Leafia install"; else
        bad "files differ from the car's Leafia install"
        diff "$W/want" "$W/now" || true
    fi
}
is_stock() {
    if sums | diff "$W/stock" - >/dev/null; then ok "byte-identical to stock"; else
        bad "not stock"
        sums | diff "$W/stock" - || true
    fi
}
unchanged() {   # <snapshot>
    if sums | diff "$1" - >/dev/null; then ok "nothing on /system changed"; else
        bad "/system changed"
        sums | diff "$1" - || true
    fi
}
declared() {
    if grep DENIED "$KT_LOG"; then bad "kt calls outside the needs"; else ok "every kt call was declared"; fi
}

echo "A. stock car: each tweak on and off, in every order"
mock
sums >"$W/stock"
expect off off
on cluster-directions; expect on off
on wireless-projection; expect on on; is_leafia
off cluster-directions; expect off on
off wireless-projection; expect off off; is_stock
on wireless-projection; expect off on
on cluster-directions; expect on on; is_leafia
off wireless-projection; expect on off
off cluster-directions; expect off off; is_stock
on cluster-directions; on wireless-projection
off wireless-projection; expect on off
off cluster-directions; expect off off; is_stock
on wireless-projection; on cluster-directions
off cluster-directions; expect off on
off wireless-projection; expect off off; is_stock
declared

echo "B. the car as Leafia left it: taken over, then turned off in either order"
leafia_car() {
    mock
    for d in projection.tbt wireless.carplay.bt carplay.wifi.audio projection.menu; do cp -R "$STOCK/$d" "$M/data/nemesis/backup/"; done
    as cluster-directions sh "$T/cluster-directions/enable.sh" >/dev/null 2>&1
    as wireless-projection sh "$T/wireless-projection/enable.sh" >/dev/null 2>&1
    # what Leafia's package did, without a record of it in the runner
    rm -rf "$KT_JOURNAL" "$W/data"
    : >"$KT_LOG"
    sums >"$W/leafia"
}
leafia_car
is_leafia; expect on on
on cluster-directions fail
on wireless-projection; unchanged "$W/leafia"
on cluster-directions; unchanged "$W/leafia"; expect on on
rm -rf "$M/data/nemesis/backup"   # taken over: Leafia's backups aren't needed any more
off wireless-projection; expect on off
off cluster-directions; expect off off; is_stock
leafia_car
on wireless-projection; on cluster-directions; unchanged "$W/leafia"
off cluster-directions; expect off on
off wireless-projection; expect off off; is_stock
declared

echo "C. a failure while turning on: turning off puts back what was changed"
mock
KT_TEST_FAIL=/system/onebin/cvev_us/featurexml.cfg on wireless-projection fail
off wireless-projection; expect off off; is_stock

echo "D. a file changed by something else is left alone"
mock
chmod u+w "$M/system/lib"; echo x >>"$M/system/lib/libCarPlayAudio.so"; chmod u-w "$M/system/lib"
sums >"$W/changed"
on wireless-projection fail; expect off error; unchanged "$W/changed"

echo "E. the Android Auto watcher: restarts the receiver on a stuck loop, not on old lines arriving at once"
mock
stuck='E/AAProjection( 1234): current Already AA Starting mode'
# old lines, all at once
printf '#!/bin/sh\nfor i in 1 2 3 4 5 6 7 8; do echo "%s"; done\n' "$stuck" >"$W/logcat"
# the loop as it happens: a line every second
printf '#!/bin/sh\nfor i in 1 2 3 4 5 6 7; do echo "%s"; /bin/sleep 1; done\n' "$stuck" >"$W/logcat-live"
chmod 755 "$W/logcat" "$W/logcat-live"
# run.sh's "watching again in 10 s" ends the test run
cat >"$W/stubs/sleep" <<'EOF'
#!/bin/sh
kill $PPID
EOF
chmod 755 "$W/stubs/sleep"
KT_TEST_LOGCAT=$W/logcat as wireless-projection sh "$T/wireless-projection/run.sh" >/dev/null 2>&1 || true
if grep -q ' kill ' "$KT_LOG"; then bad "restarted on old lines"; else ok "old lines in one burst: left alone"; fi
KT_TEST_LOGCAT=$W/logcat-live as wireless-projection sh "$T/wireless-projection/run.sh" >/dev/null 2>&1 || true
if grep -qx 'wireless-projection kill com.google.android.projection.sink' "$KT_LOG"; then ok "stuck receiver restarted through kt"; else bad "receiver not restarted"; fi
if grep -q "restarted the stuck" "$W/data/wireless-projection/last"; then ok "the last action is kept for status.sh"; else bad "no last action"; fi
printf '#!/bin/sh\nexit 0\n' >"$W/stubs/sleep"
declared

if [ $FAILS = 0 ]; then echo "all passed"; else
    echo "$FAILS failed"
    exit 1
fi
