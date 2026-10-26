# Shared by enable.sh and status.sh (sourced; $D is this folder). Replaces the
# /system/bin/ifconfig -> toolbox link with lib/ifconfig, which narrows the stock ADB TCP
# address on eth0 (192.168.0.123) to /32 so it never overlaps the projection hotspot's
# 192.168.0.0/24 (see lib/ifconfig). The runner keeps the link and puts it back exactly when the
# tweak is turned off. KT_TEST_ROOT: host tests.
R=${KT_TEST_ROOT:-}
PATH=$PATH:/system/bin:/system/xbin
IFC=/system/bin/ifconfig
SUM_OURS=a517bb36ed82fa52a5591ff6a27cb090

sum() { [ -f "$1" ] && md5 "$1" 2>/dev/null | while read -r s _; do echo "$s"; done; }
fail() { echo "FAIL: $1"; exit 1; }

# stock: a symbolic link to toolbox
is_stock() {
    local l
    [ -h "$R$IFC" ] || return 1
    l=$(ls -l "$R$IFC")
    case "$l" in *"-> toolbox") return 0 ;; esac
    return 1
}
is_ours() { [ ! -h "$R$IFC" ] && [ "$(sum "$R$IFC")" = $SUM_OURS ]; }

# eth0 has the stock ADB TCP address as a /24 right now
eth0_clashes() {
    netcfg 2>/dev/null | while read -r i _ a _; do
        [ "$i" = eth0 ] && [ "$a" = 192.168.0.123/24 ] && echo y
    done
}
