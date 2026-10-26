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
# wireless-projection is on. The runner keeps one stack of changes per file, so each tweak puts
# its own build in its place in that stack: wireless-projection's bridge build goes on top of
# cluster-directions' turn-by-turn build, and cluster-directions turned on while the bridge
# build is in puts its build under it (kt file replace --under). Turning either off leaves the
# other's build in place.
#
# Nothing of the head unit's is shipped (lib/leafia/): every changed file is rebuilt in
# $TWEAK_DATA from the car's own stock copy with this pack's projpatch (patch/), from Leafia's
# deltas (.lpd) and byte recipes, and checked against the md5 Leafia's own build gives before kt
# puts it in place. The runner keeps the stock files and puts them back when a tweak is turned
# off. A file that Leafia's package already changed is taken over instead (lib/projection-adopt.sh).
# Never reboots.
#
# Derived from the scripts of HMG Leafia Plus (packages/wireless-carplay-aa, GPL-3.0,
# https://github.com/VysseCodes/HMG-Leafia-Plus), which build on the NEMESIS community packages
# wireless.projection and projection.tbt (AGPL-3.0). See NOTICE.md.
#
# Runs as the tweak's own uid: reads /system, writes only $TWEAK_DATA, and changes the head unit
# only through kt. Head unit shell: mksh, no sed/awk/head/printf. KT_TEST_ROOT runs it against a
# copy of the file system (host tests only).
R=${KT_TEST_ROOT:-}
PATH=$PATH:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/vendor/lib:/system/lib
export ANDROID_ROOT=/system ANDROID_ASSETS=/system/app
export BOOTCLASSPATH=/system/framework/core.jar:/system/framework/conscrypt.jar:/system/framework/okhttp.jar:/system/framework/core-junit.jar:/system/framework/bouncycastle.jar:/system/framework/ext.jar:/system/framework/framework.jar:/system/framework/framework2.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/mms-common.jar:/system/framework/android.policy.jar:/system/framework/services.jar:/system/framework/apache-xml.jar:/system/framework/webviewchromium.jar:/system/framework/automotive.jar

LIB=$D/../../lib                               # this pack's lib/ (tweaks.projection)
P=$LIB/leafia                                  # Leafia's patch data
KP=$LIB/projpatch.jar                          # this pack's patch tool (patch/)
WORK=$TWEAK_DATA/work
DEXOPT=$R/system/bin/dexopt
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
        *.apk|*.odex) echo "/system/app/$1" ;;
        *.so) echo "/system/lib/$1" ;;
        featurexml.cfg) echo /system/onebin/cvev_us/featurexml.cfg ;;   # ro.mobis.targetdir on this firmware
        *_wireless.xml) echo "/system/etc/permissions/com.hkmc.software.connectivity.$1" ;;
    esac
}

sum() { [ -f "$1" ] && md5 "$1" 2>/dev/null | while read -r s _; do echo "$s"; done; }

# state of a live file: one of the names known() has for it, absent, or other
state() {
    local f s v
    f=$R$(live "$1")
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
        v=$(getprop "$p")
        case "$v" in t|T) on=$((on + 1)) ;; esac
    done
    if [ $on = $n ]; then echo on; elif [ $on = 0 ]; then echo off; else echo mixed; fi
}

say() { echo "$1"; }
fail() {
    echo "FAIL: $1"
    rm -rf "$WORK"
    exit 1
}

# a change made during this boot only shows after a restart
mark_pending() { cat /proc/sys/kernel/random/boot_id > "$TWEAK_DATA/pending"; }
pending() { [ -f "$TWEAK_DATA/pending" ] && [ "$(cat "$TWEAK_DATA/pending")" = "$(cat /proc/sys/kernel/random/boot_id)" ]; }

. "$LIB/projection-adopt.sh"

# ---- building, in $WORK (nothing on the head unit changes)

# the patch tool runs in its own dalvik, with its cache in $WORK
kp() {
    if [ -n "$KT_TEST_KP" ]; then $KT_TEST_KP "$@"; return; fi
    ANDROID_DATA=$WORK/data CLASSPATH=$KP app_process /system/bin app.cabinwright.tweaks.projection.patch.Main "$@"
}

# stock_src <name>: prints a stock copy of <name>: the live file when it is stock, else the
# original the runner keeps for it (the other tweak of this pack changed it), copied into $WORK
stock_src() {
    local f
    f=$R$(live "$1")
    if [ "$(sum "$f")" = "$(known "$1" stock)" ]; then echo "$f"; return 0; fi
    kt file original "$(live "$1")" "$WORK/$1.stock" >/dev/null 2>&1 \
        && [ "$(sum "$WORK/$1.stock")" = "$(known "$1" stock)" ] && echo "$WORK/$1.stock"
}

# build_app <App> <tbt|bridge|menu>: $WORK/<App>.apk and its optimized $WORK/<App>.odex, from the
# stock apk and odex
build_app() {
    local lpd apk odex
    case "$2" in
        menu) lpd=$P/HKMC_BtSettings.menu.9096dec5.lpd ;;
        *) lpd=$P/ev6/$1.$2.lpd ;;
    esac
    apk=$(stock_src "$1.apk") || { echo "FAIL: no stock copy of $1.apk"; return 1; }
    odex=$(stock_src "$1.odex") || { echo "FAIL: no stock copy of $1.odex"; return 1; }
    rm -f "$WORK/classes.dex"
    kp delta "$lpd" "$odex" "$WORK/classes.dex" || { echo "FAIL: rebuilding $1 ($2)"; return 1; }
    kp lpzipadd "$apk" "$WORK/classes.dex" "$WORK/$1.apk" || { echo "FAIL: packing $1.apk"; return 1; }
    rm -f "$WORK/classes.dex" "$WORK/$1.apk.stock" "$WORK/$1.odex.stock"
    [ "$(sum "$WORK/$1.apk")" = "$(known "$1.apk" "$2")" ] || { echo "FAIL: rebuilt $1.apk isn't Leafia's $2 build"; return 1; }
    rm -f "$WORK/$1.odex"
    if ! "$DEXOPT" --preopt "$WORK/$1.apk" "$WORK/$1.odex" "m=y,u=n" >/dev/null 2>&1 || [ ! -s "$WORK/$1.odex" ]; then
        echo "FAIL: dexopt for $1"
        return 1
    fi
    say "built $1 ($2)"
}

# build_lib <lib>: $WORK/<lib> from the stock library
build_lib() {
    local src want
    src=$(stock_src "$1") || { echo "FAIL: no stock copy of $1"; return 1; }
    case "$1" in
        libautoreceiver_infobank.so) want=tbt; kp delta "$P/libautoreceiver_infobank.tbt.lpd" "$src" "$WORK/$1" ;;
        libCarPlayCore.so) want=ours; kp apply "$P/carplay-core-wifi.recipe" "$src" "$WORK/$1" ;;
        libCarPlayAudio.so) want=ours; kp apply "$P/carplay-audio-formats.recipe" "$src" "$WORK/$1" ;;
        libCarPlayUtils.so) want=ours; kp apply "$P/carplay-utils-converter.recipe" "$src" "$WORK/$1" ;;
    esac || { echo "FAIL: patching $1"; return 1; }
    rm -f "$WORK/$1.stock"
    [ "$(sum "$WORK/$1")" = "$(known "$1" $want)" ] || { echo "FAIL: patched $1 isn't Leafia's build"; return 1; }
    say "built $1"
}

build_featurexml() {   # <on|off>: $WORK/featurexml.cfg from the live one
    kp delta "$P/featurexml.$1.lpd" "$R$(live featurexml.cfg)" "$WORK/featurexml.cfg" \
        || { echo "FAIL: featurexml.cfg isn't the file this firmware has"; return 1; }
}

# ---- the plan: what to do, gathered first so that a check that fails changes nothing

STEPS=
CHANGES=
step() { STEPS="$STEPS $1:$2:$3"; }   # <put|app|under|adopt|appadopt|prop|propadopt> <name> [<file>]

run_steps() {
    local s v n f
    for s in $STEPS; do
        v=${s%%:*}; s=${s#*:}; n=${s%%:*}; f=${s#*:}
        case $v in
            put) kt file replace "$(live "$n")" "$f" || return 1; CHANGES=1; say "installed $n" ;;
            app)
                kt file replace "$(live "$n.apk")" "$WORK/$n.apk" && kt file replace "$(live "$n.odex")" "$WORK/$n.odex" || return 1
                CHANGES=1; say "installed $n" ;;
            under)
                kt file replace --under "$(live "$n.apk")" "$WORK/$n.apk" && kt file replace --under "$(live "$n.odex")" "$WORK/$n.odex" || return 1
                say "kept the turn-by-turn build of $n for when wireless projection is turned off" ;;
            adopt) kt file adopt "$(live "$n")" "$f" || return 1; say "took over $n" ;;
            appadopt)
                kt file adopt "$(live "$n.apk")" "$(leafia_stock "$n.apk")" && kt file adopt "$(live "$n.odex")" "$(leafia_stock "$n.odex")" || return 1
                say "took over $n" ;;
            prop)
                if ! kt prop set "$n" t || [ "$(getprop "$n")" != t ]; then echo "FAIL: $n didn't take"; return 1; fi
                CHANGES=1; say "$n on" ;;
            propadopt) kt prop adopt "$n" "" || return 1; say "took over $n" ;;
        esac
    done
}

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

# ---- what turning each tweak on does, file by file: a file already in this tweak's state is
# taken over, every other file is built and put in

wireless_plan() {
    local n
    case $(state libev6aac.so) in
        ours) step adopt libev6aac.so absent ;;
        *)
            [ "$(sum "$P/libev6aac.so")" = "$(known libev6aac.so ours)" ] || { echo "FAIL: libev6aac.so in the package is damaged"; return 1; }
            step put libev6aac.so "$P/libev6aac.so" ;;   # first: the patched libCarPlayUtils looks for it by name
    esac
    for n in libCarPlayUtils.so libCarPlayAudio.so libCarPlayCore.so; do
        case $(state $n) in
            ours) plan_adopt $n || return 1 ;;
            *) build_lib $n || return 1; step put $n "$WORK/$n" ;;
        esac
    done
    for n in Iap2ServerApp HKMC_DiPO; do
        case $(state $n.apk) in
            bridge) plan_adopt_app $n || return 1 ;;
            tbt)
                [ -n "$(stock_src $n.apk)" ] || {
                    echo "FAIL: $n has the turn-by-turn build from HMG Leafia Plus: turn on Navigation directions in the instrument cluster first"
                    return 1
                }
                build_app $n bridge || return 1; step app $n ;;
            *) build_app $n bridge || return 1; step app $n ;;
        esac
    done
    case $(state HKMC_BtSettings.apk) in
        menu) plan_adopt_app HKMC_BtSettings || return 1 ;;
        *) build_app HKMC_BtSettings menu || return 1; step app HKMC_BtSettings ;;
    esac
    for n in androidauto_wireless.xml carplay_wireless.xml; do
        case $(state $n) in
            ours) step adopt $n absent ;;
            *) step put $n "$P/com.hkmc.software.connectivity.$n" ;;
        esac
    done
    case $(state featurexml.cfg) in
        ours) build_featurexml off || return 1; step adopt featurexml.cfg "$WORK/featurexml.cfg" ;;
        *) build_featurexml on || return 1; step put featurexml.cfg "$WORK/featurexml.cfg" ;;
    esac
    for n in $PROPS; do
        case $(getprop "$n") in
            t|T) step propadopt "$n" ;;   # set by Leafia's package; unset on stock firmware
            *) step prop "$n" ;;
        esac
    done
}

directions_plan() {
    local n
    for n in HKMC_GPM HKMC_Navi_ExSL; do
        case $(state $n.apk) in
            tbt) plan_adopt_app $n || return 1 ;;
            *) build_app $n tbt || return 1; step app $n ;;
        esac
    done
    for n in HKMC_DiPO Iap2ServerApp; do
        case $(state $n.apk) in
            stock) build_app $n tbt || return 1; step app $n ;;
            tbt) plan_adopt_app $n || return 1 ;;
            bridge)
                # wireless-projection's build, which has turn-by-turn in it: this tweak's build goes
                # under it, for when wireless-projection is turned off
                [ -n "$(stock_src $n.apk)" ] || {
                    echo "FAIL: wireless CarPlay was set up by HMG Leafia Plus: turn on Wireless Android Auto and CarPlay first"
                    return 1
                }
                build_app $n tbt || return 1; step under $n ;;
        esac
    done
    case $(state libautoreceiver_infobank.so) in
        tbt) plan_adopt libautoreceiver_infobank.so || return 1 ;;
        *) build_lib libautoreceiver_infobank.so || return 1; step put libautoreceiver_infobank.so "$WORK/libautoreceiver_infobank.so" ;;
    esac
}

# turn <wireless|directions>: the whole enable.sh
turn() {
    "${1}_state"
    [ "$ST" = error ] && fail "files neither stock nor this tweak's:$WHY - leaving them alone"
    { rm -rf "$WORK" && mkdir -p "$WORK/data/dalvik-cache"; } || fail "can't make $WORK"
    "${1}_plan" || fail "nothing changed"
    run_steps || fail "turning on stopped part way - turn it off to put back what changed"
    rm -rf "$WORK"
    "${1}_state"
    [ "$ST" = on ] || fail "files are $ST after the change:$WHY"
    if [ -n "$CHANGES" ]; then
        mark_pending
        say "turned on - restart the head unit to apply"
    else
        say "already installed by HMG Leafia Plus's package: taken over, nothing changed"
    fi
}
