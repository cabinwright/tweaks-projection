#!/bin/sh
# Host test: runs the two tweaks' enable/disable/status scripts against a mock /system made
# from a 2023 Kia EV6 (260507)'s stock files, with the pack's projpatch run by the host JVM and
# stubs for md5, getprop/setprop, nemesis and dexopt. Passes only if every result has the
# checksums HMG Leafia Plus's own install has on the car, and turning off restores /system
# byte for byte.
#
# usage: tests/host-test.sh <stock dir>
#   <stock dir> is laid out like Leafia's backups on the car (adb pull /data/nemesis/backup):
#   projection.tbt/ (HKMC_GPM, HKMC_DiPO, Iap2ServerApp, HKMC_Navi_ExSL .apk/.odex and
#   libautoreceiver_infobank.so), wireless.carplay.bt/libCarPlayCore.so,
#   carplay.wifi.audio/libCarPlayAudio.so and libCarPlayUtils.so, projection.menu/
#   HKMC_BtSettings.apk/.odex, wireless.projection/featurexml.cfg. Kia's files: keep them private.
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
STOCK=$(cd "$1" && pwd)
T=$HERE/package/tweaks
W=$(mktemp -d)
trap 'chmod -R u+w "$W"; rm -rf "$W"' EXIT
FAILS=0

md5of() { if command -v md5sum >/dev/null; then md5sum "$1" | cut -d' ' -f1; else md5 -q "$1"; fi; }

mkdir -p "$W/kp" "$W/stubs"
javac -nowarn -d "$W/kp" "$HERE"/patch/src/dev/kiatweaks/projection/patch/*.java 2>/dev/null
REAL_MD5=$(command -v md5sum || command -v md5)
REAL_CAT=$(command -v cat)
cat > "$W/stubs/md5" <<EOF
#!/bin/sh
[ -f "\$1" ] || { echo "could not open \$1" >&2; exit 1; }
case "$REAL_MD5" in *md5sum) s=\$($REAL_MD5 "\$1" | cut -d' ' -f1) ;; *) s=\$($REAL_MD5 -q "\$1") ;; esac
echo "\$s  \$1"
EOF
cat > "$W/stubs/getprop" <<'EOF'
#!/bin/sh
cat "$KT_TEST_ROOT/props/$1" 2>/dev/null
EOF
cat > "$W/stubs/setprop" <<'EOF'
#!/bin/sh
mkdir -p "$KT_TEST_ROOT/props" "$KT_TEST_ROOT/data/property"
printf '%s' "$2" > "$KT_TEST_ROOT/props/$1"
case "$1" in persist.*) printf '%s' "$2" > "$KT_TEST_ROOT/data/property/$1" ;; esac
EOF
printf '#!/bin/sh\nexit 0\n' > "$W/stubs/sleep"
printf '#!/bin/sh\ncase "$1" in /proc/sys/kernel/random/boot_id) echo test-boot ;; *) %s "$@" ;; esac\n' "$REAL_CAT" > "$W/stubs/cat"
chmod 755 "$W"/stubs/*

export KT_TEST_ROOT=$W/root KT_TEST_PATH=$W/stubs:/usr/bin:/bin:/usr/sbin:/sbin
export KT_TEST_KP="java -cp $W/kp dev.kiatweaks.projection.patch.Main"
M=$KT_TEST_ROOT

mock() {   # a stock /system
    rm -rf "$M"
    mkdir -p $M/system/app $M/system/lib $M/system/onebin/cvev_us $M/system/etc/permissions $M/system/xbin \
        $M/system/bin $M/data/nemesis/backup $M/data/property $M/props
    for a in HKMC_GPM HKMC_DiPO Iap2ServerApp HKMC_Navi_ExSL; do cp "$STOCK/projection.tbt/$a.apk" "$STOCK/projection.tbt/$a.odex" $M/system/app/; done
    cp "$STOCK"/projection.menu/HKMC_BtSettings.apk "$STOCK"/projection.menu/HKMC_BtSettings.odex $M/system/app/
    cp "$STOCK/projection.tbt/libautoreceiver_infobank.so" "$STOCK/wireless.carplay.bt/libCarPlayCore.so" \
        "$STOCK/carplay.wifi.audio/libCarPlayAudio.so" "$STOCK/carplay.wifi.audio/libCarPlayUtils.so" $M/system/lib/
    cp "$STOCK/wireless.projection/featurexml.cfg" $M/system/onebin/cvev_us/
    printf '#!/bin/sh\nexit 0\n' > $M/system/xbin/nemesis
    # a deterministic stand-in for dexopt
    printf '#!/bin/sh\n[ "$1" = --preopt ] || exit 1\n{ echo odex; cat "$2"; } > "$3"\n' > $M/system/bin/dexopt
    chmod 755 $M/system/xbin/nemesis $M/system/bin/dexopt
}

sums() {
    (cd "$M" && find system -type f ! -name nemesis ! -name dexopt | sort | while read -r f; do echo "$(md5of "$f") $f"; done
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
bad() { echo "  FAILED: $1"; FAILS=$((FAILS + 1)); }
status() { echo "$(sh $T/cluster-directions/status.sh) | $(sh $T/wireless-projection/status.sh)"; }
expect() {   # <directions state> <wireless state>
    local s
    s=$(status)
    case "$s" in "$1 "*"| $2 "*) ok "status: $s" ;; *) bad "status: $s (want $1 / $2)" ;; esac
}
run() {   # <tweak> <enable|disable> [fail]
    if sh $T/$1/$2.sh > "$W/log" 2>&1; then
        [ "$3" = fail ] && { bad "$1 $2 should have failed"; cat "$W/log"; } || ok "$1 $2"
    else
        [ "$3" = fail ] && ok "$1 $2 refused/failed as it should" || { bad "$1 $2"; cat "$W/log"; }
    fi
}
is_leafia() { sums | grep -v '\.odex$' > "$W/now"; echo "$LEAFIA" | sort > "$W/want"; sort "$W/now" | diff "$W/want" - > /dev/null && ok "files match the car's Leafia install" || { bad "files differ from the car's Leafia install"; sort "$W/now" | diff "$W/want" - || true; }; }
is_stock() { sums | diff "$W/stock" - > /dev/null && ok "byte-identical to stock" || { bad "not stock"; sums | diff "$W/stock" - || true; }; }

echo "A. stock car: each tweak on and off, in both orders"
mock; sums > "$W/stock"; expect off off
run cluster-directions enable; expect on off
run wireless-projection enable; expect on on; is_leafia
run cluster-directions disable; expect off on
run wireless-projection disable; expect off off; is_stock
run wireless-projection enable; expect off on
run cluster-directions enable; expect on on; is_leafia
run wireless-projection disable; expect on off
run cluster-directions disable; expect off off; is_stock
run cluster-directions disable

echo "B. the car as Leafia left it: no backup of ours, Leafia's backups in place"
mock
for d in projection.tbt wireless.carplay.bt carplay.wifi.audio projection.menu; do cp -R "$STOCK/$d" $M/data/nemesis/backup/; done
sh $T/cluster-directions/enable.sh > /dev/null 2>&1; sh $T/wireless-projection/enable.sh > /dev/null 2>&1
rm -rf $M/data/nemesis/backup/tweaks.projection $M/data/nemesis/tweaks.projection
is_leafia; expect on on
sh $HERE/package/lib/projection-adopt.sh > "$W/log" 2>&1 && ok "projection-adopt.sh" || { bad "projection-adopt.sh"; cat "$W/log"; }
rm -rf $M/data/nemesis/backup/tweaks.projection   # turning off must also work from Leafia's backups alone
run wireless-projection disable; expect on off
run cluster-directions disable; expect off off; is_stock

echo "C. a failure while turning on is undone"
mock; chmod 555 $M/system/onebin/cvev_us
run wireless-projection enable fail
chmod 755 $M/system/onebin/cvev_us; expect off off; is_stock

echo "D. a file changed by something else is left alone"
mock; echo x >> $M/system/lib/libCarPlayAudio.so
run wireless-projection enable fail; expect off error

echo "E. adb-tcp-hotspot: the ifconfig wrapper in and out"
mock
printf '#!/bin/sh\necho "toolbox $*" >> %s/toolbox.log\n' "$M" > $M/system/bin/toolbox; chmod 755 $M/system/bin/toolbox
ln -s toolbox $M/system/bin/ifconfig
printf '#!/bin/sh\necho "eth0     UP    192.168.0.123/24  0x00001043 0a:d0:0d:00:0b:ad"\n' > "$W/stubs/netcfg"; chmod 755 "$W/stubs/netcfg"
A=$T/adb-tcp-hotspot
case "$(sh $A/status.sh)" in "off ADB TCP is blocking"*) ok "status off (clash seen)" ;; *) bad "status: $(sh $A/status.sh)" ;; esac
run adb-tcp-hotspot enable
[ ! -h $M/system/bin/ifconfig ] && cmp -s $M/system/bin/ifconfig $HERE/package/lib/ifconfig && ok "wrapper installed" || bad "wrapper not installed"
[ "$(cat $M/props/ctl.start 2>/dev/null)" = set_adb_ip ] && ok "stock set_adb_ip re-run through the wrapper" || bad "set_adb_ip not re-run"
case "$(sh $A/status.sh)" in on*) ok "status on" ;; *) bad "status: $(sh $A/status.sh)" ;; esac
# the wrapper itself: only the stock call changes
sed 's#/system/bin/toolbox#'$M'/system/bin/toolbox#' $HERE/package/lib/ifconfig > "$W/ifc"
: > $M/toolbox.log; sh "$W/ifc" eth0 192.168.0.123; sh "$W/ifc" usb0 up; sh "$W/ifc" eth0 192.168.0.123 netmask 255.255.255.255
printf 'toolbox ifconfig eth0 192.168.0.123 netmask 255.255.255.255\ntoolbox ifconfig usb0 up\ntoolbox ifconfig eth0 192.168.0.123 netmask 255.255.255.255\n' | diff - $M/toolbox.log > /dev/null \
    && ok "wrapper: /32 for set_adb_ip's call, everything else unchanged" || { bad "wrapper calls"; cat $M/toolbox.log; }
run adb-tcp-hotspot disable
[ -h $M/system/bin/ifconfig ] && [ "$(readlink $M/system/bin/ifconfig)" = toolbox ] && ok "toolbox link back" || bad "link not restored"
rm -f "$W/stubs/netcfg"

[ $FAILS = 0 ] && echo "all passed" || { echo "$FAILS failed"; exit 1; }
