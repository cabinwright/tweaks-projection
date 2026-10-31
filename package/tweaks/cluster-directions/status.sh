#!/system/bin/sh
# One line: on|off|error <text>. Reads only (checksums); recognises what HMG Leafia Plus's
# wireless.carplay.aa package installed as "on".
D=${TWEAK_DIR:-${0%/*}}
. "$D/../../lib/projection.sh"
directions_state
case $ST in
    on)
        if pending; then echo "on restart the head unit to apply"
        else echo "on phone directions in the cluster"
        fi ;;
    off)
        if pending; then echo "off restart the head unit to apply"
        # the wireless CarPlay build of the CarPlay apps carries the CarPlay part
        elif [ "$(state HKMC_DiPO.apk)" = bridge ]; then echo "off CarPlay may still show directions while wireless CarPlay is on"
        else echo "off only the car's own navigation in the cluster"
        fi ;;
    partial) echo "error only partly installed - leaving it alone" ;;
    *) echo "error files changed by something else:$WHY - leaving them alone" ;;
esac
