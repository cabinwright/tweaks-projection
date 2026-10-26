#!/system/bin/sh
# Turn off: the runner puts the stock toolbox link back. Running set_adb_ip again (enable.sh) left
# nothing to undo: an eth0 address it narrowed stays /32 until the next start, which ADB TCP
# and the hotspot are both fine with.
echo "eth0 keeps its address until the next start"
