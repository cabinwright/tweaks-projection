#!/system/bin/sh
# Turn on: rebuild the turn-by-turn files from the car's own stock files and put them in through
# kt, or take over what HMG Leafia Plus's package installed (see lib/projection.sh). Never
# reboots; exit 0 = on.
D=${TWEAK_DIR:-${0%/*}}
. "$D/../../lib/projection.sh"
turn directions
