#!/system/bin/sh
# Put the stock /system/bin/ifconfig -> toolbox link back (see common.sh). Never reboots.
# An eth0 address already narrowed this boot stays /32 until the next start.
D=${0%/*}
. $D/common.sh
is_stock && { echo "already off"; exit 0; }
is_ours || fail "/system/bin/ifconfig isn't this tweak's - leaving it alone"
$NEMESIS remount rw >/dev/null 2>&1 || fail "remount /system rw"
rm -f "$IFC.kt"
ln -s toolbox "$IFC.kt" && mv "$IFC.kt" "$IFC" || { rm -f "$IFC.kt"; fail "putting the toolbox link back"; }
sync
$NEMESIS remount ro >/dev/null 2>&1
is_stock || fail "$IFC isn't the toolbox link after the change"
echo "stock ifconfig link restored"
