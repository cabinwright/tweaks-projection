# Shared by enable.sh, disable.sh and status.sh (sourced; $D is this folder). Replaces the
# /system/bin/ifconfig -> toolbox link with lib/ifconfig, which narrows the stock ADB TCP
# address on eth0 (192.168.0.123) to /32 so it never overlaps the projection hotspot's
# 192.168.0.0/24 (see lib/ifconfig). This is the root-cause fix for what kia-tweaks'
# eth0-guard repairs after the fact. Off puts the link back exactly. KT_TEST_ROOT: host tests.
R=${KT_TEST_ROOT:-}
export PATH=/data/nemesis/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin
[ -n "$R" ] && PATH=$KT_TEST_PATH:$PATH
IFC=$R/system/bin/ifconfig
OURS=$D/../../lib/ifconfig
SUM_OURS=a517bb36ed82fa52a5591ff6a27cb090
NEMESIS=$R/system/xbin/nemesis

sum() { [ -f "$1" ] && md5 "$1" 2>/dev/null | while read -r s f; do echo "$s"; done; }
fail() { echo "FAIL: $1"; $NEMESIS remount ro >/dev/null 2>&1; exit 1; }

# stock: a symbolic link to toolbox
is_stock() {
    local l
    [ -h "$IFC" ] || return 1
    l=$(ls -l "$IFC")
    case "$l" in *"-> toolbox") return 0 ;; esac
    return 1
}
is_ours() { [ ! -h "$IFC" ] && [ "$(sum "$IFC")" = $SUM_OURS ]; }

# eth0 has the stock ADB TCP address as a /24 right now
eth0_clashes() {
    netcfg 2>/dev/null | while read -r i s a rest; do
        [ "$i" = eth0 ] && [ "$a" = 192.168.0.123/24 ] && echo y
    done
}
