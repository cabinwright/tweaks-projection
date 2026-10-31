#!/system/bin/sh
# One line: on|off|error <text>. Reads checksums and properties, recognises what HMG Leafia
# Plus's wireless.carplay.aa package installed as "on", and changes nothing on /system. Starts
# apps that an interrupted run left stopped.
D=${0%/*}
. $D/../../lib/projection.sh
apps_recover
wireless_state
case $ST in
    on)
        if pending wireless-projection; then echo "on restart the head unit to apply"
        elif ! backups_for $WIRELESS_STOCK; then echo "on phones connect without a cable (no stock backup, so it can't be turned off)"
        elif [ "$(state HKMC_DiPO.apk)" = oldbridge ]; then echo "on update ready: turn off and on again"
        else echo "on phones connect without a cable"
        fi ;;
    off) pending wireless-projection && echo "off restart the head unit to apply" || echo "off phones need a cable" ;;
    partial) echo "error only partly installed - leaving it alone" ;;
    *) echo "error files changed by something else:$WHY - leaving them alone" ;;
esac
