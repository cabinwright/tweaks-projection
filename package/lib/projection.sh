# Tweak pack tweaks.projection: shared by its tweaks wireless-projection and cluster-directions
# (sourced; $D is the tweak's folder). Reproduces, file for file, what HMG Leafia Plus's NEMESIS package
# wireless.carplay.aa (v1.0.2) installs on a 2023 Kia EV6, firmware 260507:
#
#   wireless-projection   wireless CarPlay/Android Auto feature flags (featurexml.cfg, two
#                         permission files; from the NEMESIS community package
#                         wireless.projection, hotspot only), the CarPlay Bluetooth bridge
#                         builds of HKMC_DiPO and Iap2ServerApp, the Wi-Fi session patch in
#                         libCarPlayCore.so, the Wi-Fi audio patches in libCarPlayAudio.so and
#                         libCarPlayUtils.so plus libev6aac.so, the Phone Projection menu fix
#                         in HKMC_BtSettings, and the iAP2 Wi-Fi properties
#   cluster-directions    turn-by-turn builds of HKMC_GPM, HKMC_Navi_ExSL, HKMC_DiPO,
#                         Iap2ServerApp and libautoreceiver_infobank.so (the NEMESIS community
#                         package projection.tbt)
#
# HKMC_DiPO and Iap2ServerApp are shared: their bridge build is made on top of the
# turn-by-turn build (Leafia has no bridge build without it). They are stock with both tweaks
# off, the turn-by-turn build with only cluster-directions on, and the bridge build whenever
# wireless-projection is on.
#
# Nothing of Kia's is shipped (lib/leafia/): every changed file is rebuilt here from the car's
# own stock copy with this pack's projpatch (patch/), from Leafia's deltas (.lpd) and byte recipes, and checked
# against the md5 Leafia's own build gives, before and after it is written. The stock files are
# backed up first (B below), taken from Leafia's own backups when its package put them there,
# and turning a tweak off puts the exact stock bytes back. Never reboots.
#
# Derived from the scripts of HMG Leafia Plus (packages/wireless-carplay-aa, GPL-3.0,
# https://github.com/VysseCodes/HMG-Leafia-Plus), which build on the NEMESIS community packages
# wireless.projection and projection.tbt (AGPL-3.0). See NOTICE.md.
#
# Head unit shell: mksh, no sed/awk/head/printf. KT_TEST_ROOT runs it against a copy of the
# file system (host tests only).
R=${KT_TEST_ROOT:-}
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
[ -n "$R" ] && PATH=$KT_TEST_PATH:$PATH
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
export ANDROID_ROOT=/system ANDROID_ASSETS=/system/app
export BOOTCLASSPATH=/system/framework/core.jar:/system/framework/conscrypt.jar:/system/framework/okhttp.jar:/system/framework/core-junit.jar:/system/framework/bouncycastle.jar:/system/framework/ext.jar:/system/framework/framework.jar:/system/framework/framework2.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/mms-common.jar:/system/framework/android.policy.jar:/system/framework/services.jar:/system/framework/apache-xml.jar:/system/framework/webviewchromium.jar:/system/framework/automotive.jar

LIB=$D/../../lib                               # this pack's lib/ (tweaks.projection)
P=$LIB/leafia                                  # Leafia's patch data
KP=$LIB/projpatch.jar                          # this pack's patch tool (patch/)
B=$R/data/nemesis/backup/tweaks.projection     # our stock backup
LB=$R/data/nemesis/backup                      # Leafia's backups: projection.tbt, wireless.carplay.bt,
                                               # carplay.wifi.audio, projection.menu
STATE=$R/data/nemesis/tweaks.projection        # <id>.pending
WORK=$STATE/work
NEMESIS=$R/system/xbin/nemesis
DEXOPT=$R/system/bin/dexopt
FX=$R/system/onebin/cvev_us/featurexml.cfg     # ro.mobis.targetdir on this firmware
PROPS="persist.sys.iap2.wifi persist.iap2.iden.wireless"

# md5 of each file: stock (firmware CVEV.USA.0000.V015.012.260507) and as Leafia builds it
known() {   # <name> <stock|tbt|bridge|menu|ours>
    case "$1:$2" in
        HKMC_GPM.apk:stock) echo c155b0fb97384e645987dc1bd0f85922 ;;
        HKMC_GPM.odex:stock) echo 96cd7c27a9db19acb3900f21f57ea9f0 ;;
        HKMC_GPM.apk:tbt) echo 329946b20cd51855d7da6056dbfbc4db ;;
        HKMC_Navi_ExSL.apk:stock) echo 19559e742b1d21550aa8f0324e8e6d36 ;;
        HKMC_Navi_ExSL.odex:stock) echo 9cf41f78ce312b3762b354714d12eec3 ;;
        HKMC_Navi_ExSL.apk:tbt) echo 496ef30d2c7f8260f25bd14d62c646c2 ;;
        HKMC_DiPO.apk:stock) echo 01446fb79dc4fcfc826271ba18158fa4 ;;
        HKMC_DiPO.odex:stock) echo a565e180fdb0b73d6520f28c91cdba63 ;;
        HKMC_DiPO.apk:tbt) echo c40739d474cd39ff3625ed73bfcd5b1c ;;
        HKMC_DiPO.apk:bridge) echo cd240c40c923eaff5da5b41a7aacbbe6 ;;
        Iap2ServerApp.apk:stock) echo fde208439f993986a60396e759797a01 ;;
        Iap2ServerApp.odex:stock) echo 03950e4b691f846e5478a5a69818c65e ;;
        Iap2ServerApp.apk:tbt) echo 7e90fa7d8a161ade71e11dc15e56c410 ;;
        Iap2ServerApp.apk:bridge) echo 75d7fea4d2009be6aa5c840118f58c94 ;;
        HKMC_BtSettings.apk:stock) echo ac6621eee9cf05592859af95455c3429 ;;
        HKMC_BtSettings.odex:stock) echo 9096dec592a9959291dffa00b23e1a52 ;;
        HKMC_BtSettings.apk:menu) echo 93ecaa97597a79be2a10728e45c72b33 ;;
        libautoreceiver_infobank.so:stock) echo 48ee793af8b86052503b8c952b034731 ;;
        libautoreceiver_infobank.so:tbt) echo c08410a8d32a615b1aa805cd8a243d52 ;;
        libCarPlayCore.so:stock) echo d3a47296437df56fb1ffc7ac3dfca4cb ;;
        libCarPlayCore.so:ours) echo c537d5849f1fa881b0c79333ecfd83e4 ;;
        libCarPlayAudio.so:stock) echo fca4c75b1ae39a88b83912f083ce7dda ;;
        libCarPlayAudio.so:ours) echo 81402f9bb2c74840f953c05d27291b23 ;;
        libCarPlayUtils.so:stock) echo 246865164c625a55705d5239577b7c89 ;;
        libCarPlayUtils.so:ours) echo 8bdf0a2a178abf79a2cbda881d5e8264 ;;
        libev6aac.so:ours) echo badc26bd4c40a1c3e543b733a8ec5028 ;;
        featurexml.cfg:stock) echo 2ec95448fa20221c60a145b41b516deb ;;
        featurexml.cfg:ours) echo 9ff5d15286e1af75e2b7fbf9ca2502d9 ;;
        androidauto_wireless.xml:ours) echo fa91812d3eeee415768018ab6ee6804a ;;
        carplay_wireless.xml:ours) echo 95ff801a064526de56059dba10960b05 ;;
    esac
}

# where each file lives
live() {
    case "$1" in
        *.apk|*.odex) echo "$R/system/app/$1" ;;
        *.so) echo "$R/system/lib/$1" ;;
        featurexml.cfg) echo "$FX" ;;
        *_wireless.xml) echo "$R/system/etc/permissions/com.hkmc.software.connectivity.$1" ;;
    esac
}

# Leafia's stock copy of a file, where its package backed one up
leafia_backup() {
    case "$1" in
        HKMC_GPM.*|HKMC_Navi_ExSL.*|HKMC_DiPO.*|Iap2ServerApp.*|libautoreceiver_infobank.so) echo "$LB/projection.tbt/$1" ;;
        libCarPlayCore.so) echo "$LB/wireless.carplay.bt/$1" ;;
        libCarPlayAudio.so|libCarPlayUtils.so) echo "$LB/carplay.wifi.audio/$1" ;;
        HKMC_BtSettings.*) echo "$LB/projection.menu/$1" ;;
    esac
}

sum() { [ -f "$1" ] && md5 "$1" 2>/dev/null | while read -r s f; do echo "$s"; done; }

# state of a live file: one of the names known() has for it, absent, or other
state() {
    local f s v
    f=$(live "$1")
    [ -e "$f" ] || { echo absent; return; }
    s=$(sum "$f")
    for v in stock tbt bridge menu ours; do
        [ -n "$s" ] && [ "$s" = "$(known "$1" $v)" ] && { echo $v; return; }
    done
    echo other
}

prop_state() {   # on (both t), off (neither is t), mixed
    local p v on=0 n=0
    for p in $PROPS; do
        n=$((n + 1))
        v=$(getprop $p)
        case "$v" in t|T) on=$((on + 1)) ;; esac
    done
    [ $on = $n ] && echo on || { [ $on = 0 ] && echo off || echo mixed; }
}

say() { echo "$1"; }
fail() {
    echo "FAIL: $1"
    $NEMESIS remount ro >/dev/null 2>&1
    rm -rf "$WORK"
    exit 1
}

# ---- backups

backup_ok() { [ "$(sum "$B/$1")" = "$(known "$1" stock)" ]; }

# a stock copy of <name> in $B: kept if there, else from Leafia's backup, else from /system
ensure_backup() {
    local src
    backup_ok "$1" && return 0
    mkdir -p "$B" || return 1
    for src in "$(leafia_backup "$1")" "$(live "$1")"; do
        [ -n "$src" ] && [ "$(sum "$src")" = "$(known "$1" stock)" ] || continue
        cp "$src" "$B/$1.tmp" && mv "$B/$1.tmp" "$B/$1" || { rm -f "$B/$1.tmp"; return 1; }
        backup_ok "$1" && { say "backed up stock $1 (from $src)"; return 0; }
    done
    rm -f "$B/$1"
    echo "FAIL: no stock copy of $1 (not on /system, not in $B or Leafia's backups)"
    return 1
}

# a stock copy exists somewhere (cheap: no checksums; status.sh uses it)
has_backup() {
    [ -s "$B/$1" ] || { local l; l=$(leafia_backup "$1"); [ -n "$l" ] && [ -s "$l" ]; }
}

# ---- building, in $WORK (nothing on /system changes)

# the patch tool runs in its own dalvik (root here can't write /data/dalvik-cache)
kp() {
    if [ -n "$KT_TEST_KP" ]; then $KT_TEST_KP "$@"; return; fi
    ANDROID_DATA=$WORK/data CLASSPATH=$KP app_process /system/bin dev.kiatweaks.projection.patch.Main "$@"
}

fresh_work() { rm -rf "$WORK" && mkdir -p "$WORK/data/dalvik-cache"; }

# build_app <App> <tbt|bridge|menu>: $WORK/<App>.apk from the stock apk and odex
build_app() {
    local lpd
    case "$2" in
        menu) lpd=$P/HKMC_BtSettings.menu.9096dec5.lpd ;;
        *) lpd=$P/ev6/$1.$2.lpd ;;
    esac
    ensure_backup "$1.apk" && ensure_backup "$1.odex" || return 1
    rm -f "$WORK/classes.dex"
    kp delta "$lpd" "$B/$1.odex" "$WORK/classes.dex" || { echo "FAIL: rebuilding $1 ($2)"; return 1; }
    kp lpzipadd "$B/$1.apk" "$WORK/classes.dex" "$WORK/$1.apk" || { echo "FAIL: packing $1.apk"; return 1; }
    rm -f "$WORK/classes.dex"
    [ "$(sum "$WORK/$1.apk")" = "$(known "$1.apk" "$2")" ] || { echo "FAIL: rebuilt $1.apk isn't Leafia's $2 build"; return 1; }
    say "built $1 ($2)"
}

# build_lib <lib>: $WORK/<lib> from the stock library
build_lib() {
    local want
    ensure_backup "$1" || return 1
    case "$1" in
        libautoreceiver_infobank.so) want=tbt; kp delta "$P/libautoreceiver_infobank.tbt.lpd" "$B/$1" "$WORK/$1" ;;
        libCarPlayCore.so) want=ours; kp apply "$P/carplay-core-wifi.recipe" "$B/$1" "$WORK/$1" ;;
        libCarPlayAudio.so) want=ours; kp apply "$P/carplay-audio-formats.recipe" "$B/$1" "$WORK/$1" ;;
        libCarPlayUtils.so) want=ours; kp apply "$P/carplay-utils-converter.recipe" "$B/$1" "$WORK/$1" ;;
    esac || { echo "FAIL: patching $1"; return 1; }
    [ "$(sum "$WORK/$1")" = "$(known "$1" $want)" ] || { echo "FAIL: patched $1 isn't Leafia's build"; return 1; }
    say "built $1"
}

build_featurexml() {   # <on|off>
    kp delta "$P/featurexml.$1.lpd" "$FX" "$WORK/featurexml.cfg" || { echo "FAIL: featurexml.cfg isn't the file this firmware has"; return 1; }
}

# ---- writing /system (between sys_rw and sys_ro)

sys_rw() { $NEMESIS remount rw >/dev/null 2>&1 || fail "remount /system rw"; }
sys_ro() { sync; $NEMESIS remount ro >/dev/null 2>&1; true; }

# put <src> <dst>: copy beside it, then rename over it (a running app keeps its old copy)
put() {
    rm -f "$2.kt"
    cp "$1" "$2.kt" && chmod 644 "$2.kt" && mv "$2.kt" "$2" && cmp "$1" "$2" >/dev/null 2>&1 \
        || { rm -f "$2.kt"; echo "FAIL: writing $2"; return 1; }
}

# install_app <App>: $WORK/<App>.apk in place, its odex re-optimized
install_app() {
    local apk odex
    apk=$(live "$1.apk"); odex=$(live "$1.odex")
    put "$WORK/$1.apk" "$apk" || return 1
    rm -f "$odex"
    if $DEXOPT --preopt "$apk" "$odex" "m=y,u=n" >/dev/null 2>&1 && [ -s "$odex" ]; then
        chmod 644 "$odex"
    else
        rm -f "$odex"
        say "dexopt failed for $1 - the next start optimizes it"
    fi
    say "installed $1"
}

restore_app() {   # <App>: the stock apk and odex from the backup
    ensure_backup "$1.apk" && ensure_backup "$1.odex" || return 1
    put "$B/$1.apk" "$(live "$1.apk")" && put "$B/$1.odex" "$(live "$1.odex")" || return 1
    say "restored stock $1"
}

restore_lib() {   # <lib>
    ensure_backup "$1" || return 1
    put "$B/$1" "$(live "$1")" || return 1
    say "restored stock $1"
}

# best effort: a stale optimized copy in dalvik-cache (only there if dexopt ever failed)
wipe_dalvik() {
    local a c=
    for a in "$@"; do c="$c /data/dalvik-cache/*@$a.apk@* /cache/dalvik-cache/*@$a.apk@*"; done
    [ -n "$R" ] || $NEMESIS root 1000 -c "rm -f$c" >/dev/null 2>&1
    true
}

props_on() {
    local p
    for p in $PROPS; do
        setprop $p t
        [ "$(getprop $p)" = t ] || { echo "FAIL: $p didn't take"; return 1; }
    done
    say "iAP2 Wi-Fi properties on"
}

# back to unset, as on stock firmware (empty reads as off; the persist file goes too)
props_off() {
    local p
    for p in $PROPS; do setprop $p ""; done
    sleep 1
    for p in $PROPS; do rm -f "$R/data/property/$p"; done
    say "iAP2 Wi-Fi properties back to unset"
}

# a change made during this boot only shows after a restart
mark_pending() { mkdir -p "$STATE" && cat /proc/sys/kernel/random/boot_id > "$STATE/$1.pending"; }
pending() { [ -f "$STATE/$1.pending" ] && [ "$(cat "$STATE/$1.pending")" = "$(cat /proc/sys/kernel/random/boot_id)" ]; }

# ---- the two tweaks' states, in $ST: on, off, partial (only some of the tweak's files are in; every
# file is known) or error (a file is neither stock nor Leafia's build: $WHY names them)

directions_state() {
    local n on=0 off=0
    WHY=
    for n in HKMC_GPM.apk HKMC_Navi_ExSL.apk libautoreceiver_infobank.so HKMC_DiPO.apk Iap2ServerApp.apk; do
        case "$n:$(state $n)" in
            *:tbt) on=$((on + 1)) ;;
            *:stock) off=$((off + 1)) ;;
            HKMC_DiPO.apk:bridge|Iap2ServerApp.apk:bridge) ;;   # wireless-projection's (turn-by-turn included)
            *) WHY="$WHY $n" ;;
        esac
    done
    if [ -n "$WHY" ]; then ST=error
    elif [ $off = 0 ]; then ST=on
    elif [ $on = 0 ]; then ST=off
    else ST=partial
    fi
}

wireless_state() {
    local n on=0 off=0
    WHY=
    for n in featurexml.cfg androidauto_wireless.xml carplay_wireless.xml libCarPlayCore.so libCarPlayAudio.so \
             libCarPlayUtils.so libev6aac.so HKMC_BtSettings.apk HKMC_DiPO.apk Iap2ServerApp.apk; do
        case "$n:$(state $n)" in
            *:ours|*:menu|*:bridge) on=$((on + 1)) ;;
            *:stock|*.xml:absent|libev6aac.so:absent|HKMC_DiPO.apk:tbt|Iap2ServerApp.apk:tbt) off=$((off + 1)) ;;
            *) WHY="$WHY $n" ;;
        esac
    done
    case "$(prop_state)" in
        on) on=$((on + 1)) ;;
        off) off=$((off + 1)) ;;
        *) WHY="$WHY iAP2-properties" ;;
    esac
    if [ -n "$WHY" ]; then ST=error
    elif [ $off = 0 ]; then ST=on
    elif [ $on = 0 ]; then ST=off
    else ST=partial
    fi
}

# stock copies for turning a tweak off exist (no checksums: for status.sh)
backups_for() {
    local n
    for n in "$@"; do has_backup $n || return 1; done
}
WIRELESS_STOCK="HKMC_DiPO.apk HKMC_DiPO.odex Iap2ServerApp.apk Iap2ServerApp.odex HKMC_BtSettings.apk HKMC_BtSettings.odex libCarPlayCore.so libCarPlayAudio.so libCarPlayUtils.so"
DIRECTIONS_STOCK="HKMC_GPM.apk HKMC_GPM.odex HKMC_Navi_ExSL.apk HKMC_Navi_ExSL.odex HKMC_DiPO.apk HKMC_DiPO.odex Iap2ServerApp.apk Iap2ServerApp.odex libautoreceiver_infobank.so"

check_firmware() {
    [ -n "$R" ] || [ "$(getprop ro.build.product)" = CVEV.USA.0000.V015.012.260507 ] || fail "made for other head unit software"
}

# ---- turning them on and off. *_build checks and builds into $WORK (no /system change);
# *_install and *_remove run between sys_rw and sys_ro, file by file, skipping files that
# are already where they should be, so a half-done run can be finished or undone.

wireless_build() {
    local n
    for n in $WIRELESS_STOCK; do ensure_backup $n || return 1; done
    W_APPS= W_LIBS= W_FX=
    for n in Iap2ServerApp HKMC_DiPO; do
        [ "$(state $n.apk)" = bridge ] || { build_app $n bridge || return 1; W_APPS="$W_APPS $n"; }
    done
    [ "$(state HKMC_BtSettings.apk)" = menu ] || { build_app HKMC_BtSettings menu || return 1; W_APPS="$W_APPS HKMC_BtSettings"; }
    for n in libCarPlayUtils.so libCarPlayAudio.so libCarPlayCore.so; do
        [ "$(state $n)" = ours ] || { build_lib $n || return 1; W_LIBS="$W_LIBS $n"; }
    done
    [ "$(state featurexml.cfg)" = ours ] || { build_featurexml on || return 1; W_FX=1; }
    [ "$(sum "$P/libev6aac.so")" = "$(known libev6aac.so ours)" ] || { echo "FAIL: libev6aac.so in the package is damaged"; return 1; }
}

wireless_install() {
    local n
    # the converter first: the patched libCarPlayUtils looks for it by name
    if [ "$(state libev6aac.so)" != ours ]; then put "$P/libev6aac.so" "$(live libev6aac.so)" || return 1; say "installed libev6aac.so"; fi
    for n in $W_LIBS; do put "$WORK/$n" "$(live $n)" || return 1; say "installed patched $n"; done
    for n in $W_APPS; do install_app $n || return 1; done
    for n in androidauto_wireless.xml carplay_wireless.xml; do
        [ "$(state $n)" = ours ] || { put "$P/com.hkmc.software.connectivity.$n" "$(live $n)" || return 1; say "added $n"; }
    done
    if [ -n "$W_FX" ]; then put "$WORK/featurexml.cfg" "$FX" || return 1; say "wireless projection features on in featurexml.cfg"; fi
    wipe_dalvik $W_APPS
    [ "$(prop_state)" = on ] || props_on
}

# every wireless file back to stock; HKMC_DiPO and Iap2ServerApp to the turn-by-turn build
# while cluster-directions is on
wireless_remove() {
    local n
    mkdir -p "$WORK/data/dalvik-cache"
    if [ "$(state featurexml.cfg)" = ours ]; then
        build_featurexml off && put "$WORK/featurexml.cfg" "$FX" || return 1
        say "stock featurexml.cfg"
    fi
    for n in androidauto_wireless.xml carplay_wireless.xml; do
        [ "$(state $n)" = absent ] || { rm -f "$(live $n)" && say "removed $n" || return 1; }
    done
    for n in libCarPlayCore.so libCarPlayAudio.so libCarPlayUtils.so; do
        [ "$(state $n)" = stock ] || restore_lib $n || return 1
    done
    [ "$(state libev6aac.so)" = absent ] || { rm -f "$(live libev6aac.so)" && say "removed libev6aac.so" || return 1; }
    [ "$(state HKMC_BtSettings.apk)" = stock ] || restore_app HKMC_BtSettings || return 1
    for n in Iap2ServerApp HKMC_DiPO; do
        [ "$(state $n.apk)" = bridge ] || continue
        if [ "$(state HKMC_GPM.apk)" = tbt ]; then
            build_app $n tbt && install_app $n || return 1
        else
            restore_app $n || return 1
        fi
    done
    wipe_dalvik HKMC_BtSettings Iap2ServerApp HKMC_DiPO
    [ "$(prop_state)" = off ] || props_off
}

directions_build() {
    local n
    for n in $DIRECTIONS_STOCK; do ensure_backup $n || return 1; done
    D_APPS= D_LIB=
    for n in HKMC_GPM HKMC_Navi_ExSL; do
        [ "$(state $n.apk)" = tbt ] || { build_app $n tbt || return 1; D_APPS="$D_APPS $n"; }
    done
    # with wireless-projection on, these already carry turn-by-turn (bridge build)
    for n in HKMC_DiPO Iap2ServerApp; do
        [ "$(state $n.apk)" = stock ] && { build_app $n tbt || return 1; D_APPS="$D_APPS $n"; }
    done
    [ "$(state libautoreceiver_infobank.so)" = tbt ] || { build_lib libautoreceiver_infobank.so || return 1; D_LIB=1; }
    true
}

directions_install() {
    local n
    for n in $D_APPS; do install_app $n || return 1; done
    if [ -n "$D_LIB" ]; then put "$WORK/libautoreceiver_infobank.so" "$(live libautoreceiver_infobank.so)" || return 1; say "installed libautoreceiver_infobank.so (turn-by-turn)"; fi
    wipe_dalvik $D_APPS
}

# turn-by-turn files back to stock; the bridge builds stay while wireless-projection is on
directions_remove() {
    local n
    for n in HKMC_GPM HKMC_Navi_ExSL HKMC_DiPO Iap2ServerApp; do
        [ "$(state $n.apk)" = tbt ] && { restore_app $n || return 1; }
    done
    [ "$(state libautoreceiver_infobank.so)" = stock ] || restore_lib libautoreceiver_infobank.so || return 1
    wipe_dalvik HKMC_GPM HKMC_Navi_ExSL HKMC_DiPO Iap2ServerApp
}

# turn <wireless|directions> <on|off> <tweak id>: the whole enable.sh / disable.sh
turn() {
    local st want=$2
    check_firmware
    ${1}_state; st=$ST
    [ "$st" = error ] && fail "files neither stock nor this tweak's:$WHY - leaving them alone"
    [ "$st" = $want ] && { say "already $want"; exit 0; }
    fresh_work || fail "can't make $WORK"
    if [ $want = on ]; then
        ${1}_build || fail "nothing changed"
        sys_rw
        if ! ${1}_install; then
            echo "putting back what was changed"
            ${1}_remove || echo "FAIL: couldn't put everything back - see above"
            sys_ro
            fail "turning on failed"
        fi
    else
        sys_rw
        ${1}_remove || fail "turning off failed"
    fi
    sys_ro
    rm -rf "$WORK"
    ${1}_state; st=$ST
    [ "$st" = $want ] || fail "files are $st after the change:$WHY"
    mark_pending $3
    say "turned $want - restart the head unit to apply"
}
