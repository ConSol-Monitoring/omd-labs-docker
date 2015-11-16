#!/usr/bin/env bash
cp /etc/hosts{,.tmp}
sed -i '/::/d' /etc/hosts.tmp
cat /etc/hosts.tmp > /etc/hosts
service apache2 start
omd start
while true; do sleep 100000000; done
