#!/system/bin/sh
# One line: on|off|error <text>. Reads checksums, recognises what HMG Leafia Plus's
# wireless.carplay.aa package installed as "on", and changes nothing on /system. Starts apps
# that an interrupted run left stopped.
D=${0%/*}
. $D/../../lib/projection.sh
apps_recover
directions_state
case $ST in
    on)
        if pending cluster-directions; then echo "on restart the head unit to apply"
        elif ! backups_for $DIRECTIONS_STOCK; then echo "on phone directions in the cluster (no stock backup, so it can't be turned off)"
        elif case "$(state HKMC_GPM.apk) $(state HKMC_Navi_ExSL.apk) $(state HKMC_DiPO.apk)" in *oldtbt*) true ;; *) false ;; esac; then
            echo "on update ready: turn off and on again"
        else echo "on phone directions in the cluster"
        fi ;;
    off)
        if pending cluster-directions; then echo "off restart the head unit to apply"
        # the wireless CarPlay build of the CarPlay apps carries the CarPlay part
        elif [ "$(state HKMC_DiPO.apk)" = bridge ]; then echo "off CarPlay may still show directions while wireless CarPlay is on"
        else echo "off only the car's own navigation in the cluster"
        fi ;;
    partial) echo "error only partly installed - leaving it alone" ;;
    *) echo "error files changed by something else:$WHY - leaving them alone" ;;
esac
