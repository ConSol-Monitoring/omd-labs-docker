#!/usr/bin/env bash
source /root/.sitename.env
export OMD_ROOT=/opt/omd/sites/$SITENAME

echo "Config and start OMD site: $SITENAME"
echo "--------------------------------------"

trap "omd stop $SITENAME; exit 0" SIGKILL SIGTERM SIGHUP SIGINT



# mounts empty => sync dirs in mounts        / lsyncd dir->mount
# mounts not empty => sync mounts in dirs    / lsyncd dir->mount
# no mounts => do nothing                    / no lsyncd

echo "Checking for volume mounts..."
echo "--------------------------------------"
for dir in "local" "etc" "var"; do
  d_local="$OMD_ROOT/$dir"
  d_mount="$OMD_ROOT/${dir}.mount"
  if [ ! -d "$d_mount" ]; then
    # no volume mount
    echo " * $dir/: [No Volume]"
  else
    # volume mount exists
    echo " * $dir/: [EXTERNAL Volume] at $d_mount"
    if su - $SITENAME -c "test -w '$d_mount'" ; then
        echo "   * mounted volume is writable"
    else
        echo "   * ERROR: Mounted volume is not writeable: $d_mount" && exit -1
    fi
    if [ ! "$(ls -A $d_mount)" ]; then
        # mount is empty => sync dir in mount
        echo "   => $dir.mount is empty; initial sync from local $dir ..."
        su - $SITENAME -c "rsync -rlptD --quiet $d_local/ $d_mount"
        [ $? -gt 0 ] && echo "ERROR: sync $d_local -> $d_mount!" && exit -1
    else
        # mount contains data => sync mount in dir
        echo "   <= Volume contains data; sync into local $dir ..."
        su - $SITENAME -c "rsync -rlptD --quiet $d_mount/ $d_local"
        [ $? -gt 0 ] && echo "ERROR: sync $d_mount -> $d_local" && exit -1
    fi
    echo "   * writing the lsyncd config for $dir.mount..."
    cat >>$OMD_ROOT/.lsyncd <<EOF
sync {
   default.rsync,
   source = "${d_local}/",
   target = "${d_mount}",
   delay  = 0
}
EOF
    chown $SITENAME:$SITENAME $OMD_ROOT/.lsyncd
  fi
done

echo

if [ -f $OMD_ROOT/.lsyncd ]; then
  echo "lsyncd: writing the global settings..."
  cat >>$OMD_ROOT/.lsyncd <<EOF
settings {
   statusFile  = "$OMD_ROOT/.lsyncd_status",
   inotifyMode = "CloseWrite or Modify"
}
EOF

  echo "lsyncd: Starting  ..."
  echo "--------------------------------------"
  su - $SITENAME -c 'lsyncd ~/.lsyncd'
fi

echo

echo "Checking for Ansible drop-in..."
echo "--------------------------------------"
if [ -r "$ANSIBLE_DROPIN/playbook.yml" ]; then
  echo "Executing Ansible drop-in..."
  test -e /etc/ansible/ansible.cfg || {
    mkdir -p /etc/ansible
    echo -e "[defaults]\ngather_timeout = 30" > /etc/ansible/ansible.cfg
  }
  ansible-playbook -i localhost, "$ANSIBLE_DROPIN/playbook.yml" -c local -e SITENAME=$SITENAME || exit 1
else
  echo "Nothing to do ($ANSIBLE_DROPIN/playbook.yml not found)."
fi

echo

echo "crond: Starting ..."
echo "--------------------------------------"
test -x /usr/sbin/crond && /usr/sbin/crond
test -x /usr/sbin/cron  && /usr/sbin/cron

echo

echo "omd-labs: Starting site $SITENAME..."
echo "--------------------------------------"
omd start $SITENAME

echo

echo "omd-labs: Starting Apache web server..."
echo "--------------------------------------"

$APACHE_CMD &
wait
