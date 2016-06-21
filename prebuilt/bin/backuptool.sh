#!/sbin/sh
#
# Backup and restore addon /system files
#

export C=/tmp/backupdir
export S=/system
export SUCHECK=/data/.supersu

# Scripts in /system/addon.d expect to find backuptool.functions in /tmp
cp -f /tmp/install/bin/backuptool.functions /tmp

# Preserve /system/addon.d in /tmp/addon.d
preserve_addon_d() {
  mkdir -p /tmp/addon.d/
  cp -a /system/addon.d/* /tmp/addon.d/
  chmod 755 /tmp/addon.d/*.sh
}

# Restore /system/addon.d in /tmp/addon.d
restore_addon_d() {
  cp -a /tmp/addon.d/* /system/addon.d/
  rm -rf /tmp/addon.d/
}

su_systemless() {
    cat > /data/.supersu << EOF
SYSTEMLESS=true
BINDSYSTEMXBIN=false
EOF
}

# Check for user defined system or systemless su
check_sutype() {
   if [  -f "$SUCHECK" ]; then
      echo "found "$SUCHECK" ..using user defined su choice"
   else
    su_systemless
   fi
}

# Execute /system/addon.d/*.sh scripts with $1 parameter
run_stage() {
for script in $(find /tmp/addon.d/ -name '*.sh' |sort -n); do
  $script $1
done
}

case "$1" in
  backup)
    mkdir -p $C
    preserve_addon_d
    run_stage pre-backup
    run_stage backup
    run_stage post-backup
  ;;
  restore)
    run_stage pre-restore
    run_stage restore
    run_stage post-restore
    restore_addon_d
    rm -rf $C
    sync
  ;;
  susystemless)
	check_sutype
    sync
  ;;
  *)
    echo "Usage: $0 {backup|restore|susystemless}"
    exit 1
esac

exit 0
