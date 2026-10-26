#!/system/bin/sh
# Install lib/ifconfig in place of the toolbox link (see common.sh). Never reboots.
D=${0%/*}
. $D/common.sh
is_ours && { echo "already on"; exit 0; }
is_stock || fail "/system/bin/ifconfig isn't the stock toolbox link - leaving it alone"
[ "$(sum "$OURS")" = $SUM_OURS ] || fail "lib/ifconfig in the package is damaged"
$NEMESIS remount rw >/dev/null 2>&1 || fail "remount /system rw"
rm -f "$IFC.kt"
cp "$OURS" "$IFC.kt" && chmod 755 "$IFC.kt" && mv "$IFC.kt" "$IFC" || { rm -f "$IFC.kt"; fail "writing $IFC"; }
sync
$NEMESIS remount ro >/dev/null 2>&1
is_ours || fail "$IFC isn't ours after the copy"
echo "installed the ifconfig wrapper"
# ADB TCP already gave eth0 its /24 this boot: run the stock service again, now through the
# wrapper, so it becomes /32 at once (init runs it; this service can't change eth0 itself)
if [ -n "$(eth0_clashes)" ]; then
    setprop ctl.start set_adb_ip
    sleep 2
    [ -n "$(eth0_clashes)" ] && echo "eth0 still has 192.168.0.123/24 - it is narrowed at the next start" \
        || echo "narrowed eth0 to 192.168.0.123/32"
fi
exit 0
