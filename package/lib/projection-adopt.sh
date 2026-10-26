#!/system/bin/sh
# Copies the stock files that HMG Leafia Plus's wireless.carplay.aa package backed up
# (/data/nemesis/backup/projection.tbt, wireless.carplay.bt, carplay.wifi.audio,
# projection.menu) into the projection tweaks' own backup, each checked against its stock md5,
# so wireless-projection and cluster-directions can still be turned off once that package and
# its backups are gone. Writes only /data/nemesis/backup/tweaks.projection; leaves
# Leafia's folders as they are. Safe to run more than once. As root:
#   nemesis root -c 'sh /data/nemesis/apps/tweaks.projection/lib/projection-adopt.sh'
D=${0%/*}/../tweaks/wireless-projection
. ${0%/*}/projection.sh
miss=
for n in HKMC_GPM.apk HKMC_GPM.odex HKMC_Navi_ExSL.apk HKMC_Navi_ExSL.odex HKMC_DiPO.apk HKMC_DiPO.odex \
         Iap2ServerApp.apk Iap2ServerApp.odex HKMC_BtSettings.apk HKMC_BtSettings.odex \
         libautoreceiver_infobank.so libCarPlayCore.so libCarPlayAudio.so libCarPlayUtils.so; do
    if backup_ok $n; then echo "have $n"; else ensure_backup $n || miss="$miss $n"; fi
done
[ -z "$miss" ] || { echo "missing:$miss"; exit 1; }
echo "all stock files are in $B"
