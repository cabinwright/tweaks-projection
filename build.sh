#!/bin/sh
# Builds the tweaks.projection NEMESIS package (a tweak pack for cabinwright.tweaks):
# dist/tweaks.projection.zip from package/ (NEMESIS.data, tweaks/<id>/, lib/) and the patch
# tool (patch/, into lib/projpatch.jar). Needs the Android SDK (build-tools 29.0.2, platform 23)
# and a JDK for that, plus zip. lib/leafia/libev6aac.so is committed, not rebuilt (it is built
# from native/ev6aac/ with clang + lld).
# Install over ADB (cabinwright.tweaks 1.4 or newer must be installed; its tweaksd runs the tweaks):
#   adb push dist/tweaks.projection.zip /data/local/tmp/
#   adb shell "nemesis install [--update] /data/local/tmp/tweaks.projection.zip"
set -e
ROOT=$(cd "$(dirname "$0")" && pwd)
P=$ROOT/package
md5of() { if command -v md5sum >/dev/null; then md5sum "$1" | cut -d' ' -f1; else md5 -q "$1"; fi; }

# The head unit's shell (mksh) has no printf, sed, awk or head
if grep -rnE '(^[[:space:]]*|[|;&(][[:space:]]*|\$\([[:space:]]*)(printf|sed|awk|head|tail)[[:space:]]' --include='*.sh' "$P" | grep -vE ':[0-9]+:[[:space:]]*#'; then
    echo "build.sh: a command the head unit doesn't have, in the scripts above" >&2
    exit 1
fi
# the payload must be the files the scripts' checksums expect
[ "$(md5of "$P/lib/leafia/libev6aac.so")" = badc26bd4c40a1c3e543b733a8ec5028 ] || { echo "build.sh: libev6aac.so isn't Leafia's build" >&2; exit 1; }
for f in androidauto_wireless:fa91812d3eeee415768018ab6ee6804a carplay_wireless:95ff801a064526de56059dba10960b05; do
    [ "$(md5of "$P/lib/leafia/com.hkmc.software.connectivity.${f%%:*}.xml")" = "${f#*:}" ] || { echo "build.sh: ${f%%:*}.xml changed" >&2; exit 1; }
done

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R "$P/." "$STAGE/"
sh "$ROOT/patch/build.sh" "$STAGE/lib/projpatch.jar" >/dev/null
find "$STAGE" -name .DS_Store -delete
mkdir -p "$ROOT/dist" && rm -f "$ROOT/dist/tweaks.projection.zip"
(cd "$STAGE" && zip -qrX "$ROOT/dist/tweaks.projection.zip" .)
echo "$ROOT/dist/tweaks.projection.zip"
