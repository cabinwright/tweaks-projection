#!/system/bin/sh
# One line: on|off|error <text>. Reads only.
D=${0%/*}
. $D/common.sh
if is_ours; then
    [ -n "$(eth0_clashes)" ] && echo "on eth0 is narrowed at the next start" || echo "on ADB TCP can't block wireless projection"
elif is_stock; then
    [ -n "$(eth0_clashes)" ] && echo "off ADB TCP is blocking wireless projection" || echo "off stock"
else
    echo "error /system/bin/ifconfig was changed by something else - leaving it alone"
fi
