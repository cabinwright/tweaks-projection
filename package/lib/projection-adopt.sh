# Taking over what HMG Leafia Plus's wireless.carplay.aa package installed (sourced by
# lib/projection.sh). Leafia's package keeps the stock files it replaced in
# /data/nemesis/backup/{projection.tbt, wireless.carplay.bt, carplay.wifi.audio, projection.menu}.
# A file that is already this tweak's build is taken over with kt file adopt, giving the runner
# Leafia's stock copy (it must have the stock md5) as the original: nothing on /system changes,
# and turning the tweak off puts the stock file back as if this tweak had made the change.
# Files Leafia's package added (the feature files, libev6aac.so) are taken over as absent, and
# the stock featurexml.cfg is rebuilt from the live one. Leafia's backups are only read (their
# md5 through kt file md5, since the tweak's uid may not be able to read them) and are no longer
# needed once taken over.
LB=/data/nemesis/backup

# Leafia's stock copy of a file, where its package backed one up
leafia_backup() {
    case "$1" in
        HKMC_GPM.*|HKMC_Navi_ExSL.*|HKMC_DiPO.*|Iap2ServerApp.*|libautoreceiver_infobank.so) echo "$LB/projection.tbt/$1" ;;
        libCarPlayCore.so) echo "$LB/wireless.carplay.bt/$1" ;;
        libCarPlayAudio.so|libCarPlayUtils.so) echo "$LB/carplay.wifi.audio/$1" ;;
        HKMC_BtSettings.*) echo "$LB/projection.menu/$1" ;;
    esac
}

# leafia_stock <name>: prints Leafia's stock copy of <name>, if it has the stock md5
leafia_stock() {
    local b
    b=$(leafia_backup "$1")
    [ -n "$b" ] && [ "$(kt file md5 "$b" 2>/dev/null)" = "$(known "$1" stock)" ] && echo "$R$b"
}

plan_adopt() {   # <name>
    local s
    s=$(leafia_stock "$1") || {
        echo "FAIL: $1 was changed by another package, and HMG Leafia Plus's backups have no stock copy of it"
        return 1
    }
    step adopt "$1" "$s"
}

plan_adopt_app() {   # <App>: its apk and odex
    if [ -z "$(leafia_stock "$1.apk")" ] || [ -z "$(leafia_stock "$1.odex")" ]; then
        echo "FAIL: $1 was changed by another package, and HMG Leafia Plus's backups have no stock copy of it"
        return 1
    fi
    step appadopt "$1"
}
