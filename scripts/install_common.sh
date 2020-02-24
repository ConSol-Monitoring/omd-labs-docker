#!/usr/bin/env bash
# install common packages

# script must fail on errors, otherwise build would just continue and result in a broker image
set -e

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
  yum -y install epel-release
  yum -y install 'dnf-command(config-manager)'
  yum config-manager --set-enabled PowerTools
  yum clean all
  yum -y update
  yum -y install which lsof vim git openssh-server tree file make sudo wget unzip screen
  # HACK: lsyncd is not available on centos 8 so far, using the one from centos 7 seems to work fine
  wget "http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/l/lsyncd-2.2.2-1.el7.x86_64.rpm"
  yum -y install lsyncd-2.2.2-1.el7.x86_64.rpm
  popd
}

function install_common_debian() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get update
  apt-get install -y procps

  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

  apt-get install -y lsof vim git openssh-server tree tcpdump file make sudo lsyncd screen curl gnupg2 lsb-release

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

main $@
