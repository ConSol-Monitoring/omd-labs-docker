#!/usr/bin/env bash
# install common packages

function main() {
  case $1 in
    centos) install_common_centos;;
    debian) install_common_debian;;
    ubuntu) install_common_debian;;
    *) { echo "$1: Unknown OS type!"; exit 1; }
  esac
}

function install_common_centos() {
  pushd /tmp
  rpm -Uvh "http://ftp.uni-stuttgart.de/epel/epel-release-latest-7.noarch.rpm"
  yum clean all 
  yum -y update
  yum -y install which lsof vim git openssh-server tree file make sudo lsyncd unzip screen
  popd
}

function install_common_debian() {
  export DEBIAN_FRONTEND=noninteractive

  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

  apt-get update
  apt-get install -y lsof vim git openssh-server tree tcpdump libevent-2.0-5 file make sudo lsyncd screen

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

main $@
