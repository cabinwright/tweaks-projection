#!/system/bin/sh
# Turn off: the runner puts every file and property this tweak changed back. This only notes
# that the change shows after the next start (status.sh).
D=${TWEAK_DIR:-${0%/*}}
. "$D/../../lib/projection.sh"
mark_pending
