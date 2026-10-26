#!/system/bin/sh
# Turn off: put the stock files back from the backup (see lib/projection.sh). Never reboots;
# exit 0 = off.
D=${0%/*}
. $D/../../lib/projection.sh
turn wireless off wireless-projection
