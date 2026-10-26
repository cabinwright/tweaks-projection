#!/system/bin/sh
# One line: on|off|error <text>. Reads only (checksums and properties); recognises what HMG
# Leafia Plus's wireless.carplay.aa package installed as "on".
D=${0%/*}
. $D/../../lib/projection.sh
wireless_state
case $ST in
    on)
        if pending wireless-projection; then echo "on restart the head unit to apply"
        elif backups_for $WIRELESS_STOCK; then echo "on phones connect without a cable"
        else echo "on phones connect without a cable (no stock backup, so it can't be turned off)"
        fi ;;
    off) pending wireless-projection && echo "off restart the head unit to apply" || echo "off phones need a cable" ;;
    partial) echo "error only partly installed - leaving it alone" ;;
    *) echo "error files changed by something else:$WHY - leaving them alone" ;;
esac
