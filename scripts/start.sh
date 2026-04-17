#!/usr/bin/bash

source /root/.sitename.env

export OMD_ROOT=/omd/sites/$SITENAME

echo "Config and start OMD site: $SITENAME"
echo "--------------------------------------"

################################################################################
# stop site on exit
_cleanup() {
  [ -n $APACHE_PID ] && kill $APACHE_PID >/dev/null 2>&1
  omd stop $SITENAME
  exit 0
}
trap _cleanup SIGKILL SIGTERM SIGHUP SIGINT

################################################################################
# mounts empty     => sync dirs in mounts
# mounts not empty => do nothing
# no mounts        => do nothing
echo "Checking for volume mounts..."
echo "--------------------------------------"
if [ $(ls -1A $OMD_ROOT/ | grep -cP '(etc|var|local|version)$') -ne 4 ]; then
  printf " * %-15s [empty, initializing...]\n" "$SITENAME/"
  chown $SITENAME:omd $OMD_ROOT/.
  omd create --reuse $SITENAME || exit 1
else
  # already populated
  printf " * %-15s [OK]\n" "$SITENAME/"
fi

LEGACY_MOUNTS_FOUND=0
for dir in "etc" "var" "local"; do
  TARGET="$OMD_ROOT/$dir/"
  if [ -z "$(ls -A $TARGET)" ]; then
    printf " * %-15s [empty, initializing...]\n" "$SITENAME/$dir/"
    chown $SITENAME:omd $TARGET
    if ! su - $SITENAME -c "test -w '$dir/.'" ; then
        echo "   * ERROR: Mounted volume is not writeable: $dir" && exit -1
    fi
    # populate folder
    su - $SITENAME -c "omd reset $dir/"
    if [ "$dir" = "etc" ]; then
      # reset admin password
      PW=$(echo "$RANDOM$(date)" | sha256sum | awk '{ print $1 }')
      su - $SITENAME -c "set_admin_password $PW" >/dev/null
    fi
  else
    # already populated
    printf " * %-15s [OK]\n" "$SITENAME/$dir/"
  fi
  if [ -e "$OMD_ROOT/${dir}.mount" ]; then
    LEGACY_MOUNTS_FOUND=1
    printf " * %-15s.mount [ERROR: .mount folder are no longer supported]\n" "$SITENAME/$dir/"
  fi
done
if [ $LEGACY_MOUNTS_FOUND != 0 ]; then
  echo "ERROR: site folder should be directly mounted now."
  echo "ERROR: see https://github.com/ConSol-Monitoring/omd-labs-docker/#use-data-containers"
  exit 1
fi

################################################################################
echo
echo "Checking for Ansible drop-in..."
echo "--------------------------------------"
if [ -r "$ANSIBLE_DROPIN/playbook.yml" ]; then
  echo " * Executing Ansible drop-in..."
  ansible-playbook -i localhost, "$ANSIBLE_DROPIN/playbook.yml" -c local -e SITENAME=$SITENAME || exit 1
else
  echo " * Skipping... ($ANSIBLE_DROPIN/playbook.yml not found)."
fi

################################################################################
echo
echo "crond: Starting ..."
echo "--------------------------------------"
test -x /usr/sbin/crond && /usr/sbin/crond
test -x /usr/sbin/cron  && /usr/sbin/cron

################################################################################
echo
echo "omd-labs: Starting site $SITENAME..."
echo "--------------------------------------"
omd start $SITENAME

################################################################################
echo
echo "omd-labs: Starting Apache web server..."
echo "--------------------------------------"
test -x /usr/libexec/httpd-ssl-gencerts && /usr/libexec/httpd-ssl-gencerts
$APACHE_CMD &
APACHE_PID=$!

################################################################################
sleep infinity
