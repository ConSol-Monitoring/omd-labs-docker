#!/usr/bin/env bash
# Changing /etc/hosts in Docker containers is restricted by design - but possible if we keep the inode.
cp /etc/hosts{,.tmp}
sed -i '/::/d' /etc/hosts.tmp
cat /etc/hosts.tmp > /etc/hosts

service apache2 start
omd start
while true; do sleep 100000000; done
