#!/system/bin/sh
# One line: on|off|error <text>. Reads only (checksums and properties); recognises what HMG
# Leafia Plus's wireless.carplay.aa package installed as "on".
D=${TWEAK_DIR:-${0%/*}}
. "$D/../../lib/projection.sh"
wireless_state
case $ST in
    on) if pending; then echo "on restart the head unit to apply"; else echo "on phones connect without a cable"; fi ;;
    off) if pending; then echo "off restart the head unit to apply"; else echo "off phones need a cable"; fi ;;
    partial) echo "error only partly installed - leaving it alone" ;;
    *) echo "error files changed by something else:$WHY - leaving them alone" ;;
esac
