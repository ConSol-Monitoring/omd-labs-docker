#!/usr/bin/env bash
# install common packages

# script must fail on errors, otherwise build would just continue and result in a broker image
set -e

function main() {
  case $1 in
    rocky)  install_common_rocky;;
    debian) install_common_debian;;
    *) { echo "$1: Unknown OS type!"; exit 1; }
  esac
}

function install_common_rocky() {
  pushd /tmp
  dnf -y install dnf-plugins-core
  dnf -y install epel-release
  dnf config-manager --set-enabled crb
  dnf clean all
  dnf -y update
  dnf -y install which lsof vim git openssh-server tree file make sudo wget unzip screen ansible-core lsyncd
  # install missing dependencies, should be come along with next omd release
  dnf -y install boost-atomic boost-chrono perl-Module-Load perl-Text-Balanced perl-Thread-Queue
  dnf -y install glibc-langpack-en # required for locale en_US.UTF-8
  popd
}

function install_common_debian() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get update
  apt-get install -y procps

  apt-get install -y locales apt-utils
  sed -i -r '/de_DE|en_US/s/^# *//' /etc/locale.gen
  dpkg-reconfigure --frontend=noninteractive locales

  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

set +e
set -x
apt-get install -y python3
type python3.11
python3.11 -VV
python3.11 -c 'import imp; print(imp.get_tag())'
set +x
set +e

  apt-get install -y lsof vim git openssh-server tree tcpdump file make sudo lsyncd screen curl gnupg2 lsb-release ansible

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

main $@
