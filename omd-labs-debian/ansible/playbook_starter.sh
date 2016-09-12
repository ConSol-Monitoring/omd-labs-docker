#!/bin/bash

echo "omd-labs: Executing ansible-playbook..."
echo "========================================"
/omd/sites/demo/bin/ansible-playbook -i localhost, /root/ansible/playbook.yml -c local -e ANSIBLE_DROPIN_ROLE=$ANSIBLE_DROPIN_ROLE $ANSIBLE_VERBOSITY
echo "omd-labs: Starting Apache web server..."
echo "========================================"
exec /usr/sbin/apache2ctl -D FOREGROUND
