#!/bin/bash

# Check if dropin role is defined
if [ `ls -1 /root/ansible_omd/dropin_role/ 2>/dev/null | wc -l` -gt 0 ]; then
  echo "omd-labs: Executing Ansible drop-in role..."
  /omd/versions/default/bin/ansible-playbook -i localhost, /root/ansible_omd/playbook.yml -c local -e ANSIBLE_DROPIN_ROLE=$ANSIBLE_DROPIN_ROLE $ANSIBLE_VERBOSITY
else
  echo "No Ansible drop-in role defined, nothing to do."
fi

echo "omd-labs: Starting site..."
echo "----------------------"
omd start $SITENAME
echo "----------------------"


echo "omd-labs: Starting Apache web server..."
exec /usr/sbin/httpd -D FOREGROUND
