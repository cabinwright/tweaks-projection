#!/system/bin/sh
# Turn on: rebuild the wireless Android Auto and CarPlay files from the car's own stock files and install them
# (see lib/projection.sh). Never reboots; exit 0 = on.
D=${0%/*}
. $D/../../lib/projection.sh
turn wireless on wireless-projection
