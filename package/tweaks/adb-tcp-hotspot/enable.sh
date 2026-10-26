#!/system/bin/sh
# Put lib/ifconfig in place of the toolbox link (see common.sh). Never reboots.
D=${TWEAK_DIR:-${0%/*}}
. "$D/common.sh"
OURS=$D/../../lib/ifconfig
is_ours && { echo "already on"; exit 0; }
is_stock || fail "/system/bin/ifconfig isn't the stock toolbox link - leaving it alone"
[ "$(sum "$OURS")" = $SUM_OURS ] || fail "lib/ifconfig in the package is damaged"
kt file replace $IFC "$OURS" 0755 || fail "kt couldn't replace $IFC"
is_ours || fail "$IFC isn't ours after the change"
echo "installed the ifconfig wrapper"
# ADB TCP already gave eth0 its /24 this boot: run the stock service again, now through the
# wrapper, so it becomes /32 at once
if [ -n "$(eth0_clashes)" ]; then
    kt service start set_adb_ip
    sleep 2
    if [ -n "$(eth0_clashes)" ]; then echo "eth0 still has 192.168.0.123/24 - it is narrowed at the next start"
    else echo "narrowed eth0 to 192.168.0.123/32"
    fi
fi
exit 0
