#!/usr/bin/env bash
source /root/.sitename.env
export OMD_ROOT=/opt/omd/sites/$SITENAME

echo "Config and start OMD site: $SITENAME"
echo "--------------------------------------"

_cleanup() {
  [ -n $APACHE_PID ] && kill $APACHE_PID >/dev/null 2>&1
  omd stop $SITENAME
  exit 0
}

trap _cleanup SIGKILL SIGTERM SIGHUP SIGINT

# mounts empty     => sync dirs in mounts
# mounts not empty => do nothing
# no mounts        => do nothing
echo "Checking for volume mounts..."
echo "--------------------------------------"
if [ -z "$(ls -A $OMD_ROOT/. | grep -v bash_history)" ]; then
  echo " * $OMD_ROOT/: [empty, initializing...]"
  chown $SITENAME:omd $OMD_ROOT/.
  omd create --reuse $SITENAME
else
  for dir in "etc" "var" "local"; do
    TARGET="$OMD_ROOT/$dir/"
    if [ -z "$(ls -A $TARGET)" ]; then
      echo " * $dir/: [empty, initializing...]"
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
      printf " * %-8s [OK]\n" "$dir/"
    fi
  done
fi

echo
echo "Checking for Ansible drop-in..."
echo "--------------------------------------"
if [ -r "$ANSIBLE_DROPIN/playbook.yml" ]; then
  echo " * Executing Ansible drop-in..."
  ansible-playbook -i localhost, "$ANSIBLE_DROPIN/playbook.yml" -c local -e SITENAME=$SITENAME || exit 1
else
  echo " * Skipping... ($ANSIBLE_DROPIN/playbook.yml not found)."
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
test -x /usr/libexec/httpd-ssl-gencerts && /usr/libexec/httpd-ssl-gencerts
$APACHE_CMD &
APACHE_PID=$!

sleep infinity
