#!/bin/bash

if [ -r $ANSIBLE_DROPIN/playbook.yml ]; then
  echo "omd-labs: Executing Ansible drop-in..."
  echo "--------------------------------------"
  /omd/versions/default/bin/ansible-playbook -i localhost, $ANSIBLE_DROPIN/playbook.yml -c local $ANSIBLE_VERBOSITY -e SITENAME=$SITENAME
else
  echo "No Ansible drop-in defined, nothing to do."
fi

echo "omd-labs: Starting site $SITENAME..."
echo "--------------------------------------"
omd start $SITENAME
echo "--------------------------------------"

echo "omd-labs: Starting Apache web server..."
exec /usr/sbin/apache2ctl -D FOREGROUND
