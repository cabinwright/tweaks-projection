#!/system/bin/sh
# Turn on: rebuild the turn-by-turn files from the car's own stock files and install them
# (see lib/projection.sh). Never reboots; exit 0 = on.
D=${0%/*}
. $D/../../lib/projection.sh
turn directions on cluster-directions
