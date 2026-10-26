#!/system/bin/sh
# One line: on|off|error <text>. Shows run.sh's last action, if any.
L=$TWEAK_DATA/last
if [ -s "$L" ]; then
    read -r when what < "$L"
    ago=$(( ($(date +%s) - when) / 60 ))
    # before the clock is set at start-up, times are meaningless
    if [ "$when" -lt 1577836800 ]; then at="at start-up"
    elif [ $ago -lt 120 ]; then at="$ago min ago"
    else at="$((ago / 60)) h ago"
    fi
    echo "on $what ($at)"
else
    echo "on watching the Android Auto receiver"
fi
