#!/system/bin/sh
# One line: on|off|error <text>. Reads only.
D=${TWEAK_DIR:-${0%/*}}
. "$D/common.sh"
if is_ours; then
    if [ -n "$(eth0_clashes)" ]; then echo "on eth0 is narrowed at the next start"; else echo "on ADB TCP can't block wireless projection"; fi
elif is_stock; then
    if [ -n "$(eth0_clashes)" ]; then echo "off ADB TCP is blocking wireless projection"; else echo "off stock"; fi
else
    echo "error /system/bin/ifconfig was changed by something else - leaving it alone"
fi
