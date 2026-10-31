#!/system/bin/sh
# One line: on|off|error <text>. Reads only (checksums and properties); recognises what HMG
# Leafia Plus's wireless.carplay.aa package installed as "on".
D=${TWEAK_DIR:-${0%/*}}
. "$D/../../lib/projection.sh"
# run.sh's last action, if any
last_action() {
    local when what ago
    [ -s "$TWEAK_DATA/last" ] || return 0
    read -r when what < "$TWEAK_DATA/last"
    ago=$(( ($(date +%s) - when) / 60 ))
    # before the clock is set at start-up, times are meaningless
    if [ "$when" -lt 1577836800 ]; then echo " - $what at start-up"
    elif [ $ago -lt 120 ]; then echo " - $what $ago min ago"
    else echo " - $what $((ago / 60)) h ago"
    fi
}
wireless_state
case $ST in
    on) if pending; then echo "on restart the head unit to apply"; else echo "on phones connect without a cable$(last_action)"; fi ;;
    off) if pending; then echo "off restart the head unit to apply"; else echo "off phones need a cable"; fi ;;
    partial) echo "error only partly installed - leaving it alone" ;;
    *) echo "error files changed by something else:$WHY - leaving them alone" ;;
esac
