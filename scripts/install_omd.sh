#!/usr/bin/env bash
# $1 = OS
# $2 = OMD version (master/latest/vX.XX)

# script must fail on errors, otherwise build would just continue and result in a broker image
set -e

function main() {
  case $1 in
    centos) install_omd_centos $1 $2;;
    debian) install_omd_debian $2;;
    ubuntu) install_omd_ubuntu $2;;
    *) { echo "$1: Unknown OS type!"; exit 1; }
  esac

  # Logrotate settings
  find /omd/versions/default/skel/etc/logrotate.d -type f -exec sed -i 's/rotate [0-9]*/rotate 0/' {} \;
}

function pkgName() {
  REPOVERSION=$1
  case $1 in
    "master")
      echo "omd-labs-edition-daily"
      ;;
    "latest")
      echo "omd-labs-edition"
      ;;
    *)
      echo "omd-${1}-labs-edition"
      ;;
  esac
}

function repoVersion() {
  if [ "x$1" == "xlatest" ] || [[ "x$1" =~ [0-9].[0-9]{2} ]]; then
    echo "stable"
  else
    echo "testing"
  fi
}

function install_omd_centos() {
  OS=$1
  VERSION=$2
  PACKAGENAME=`pkgName $VERSION`
  REPOVERSION=`repoVersion $VERSION`

  rpm -Uvh "https://labs.consol.de/repo/${REPOVERSION}/rhel7/x86_64/labs-consol-${REPOVERSION}.rhel7.noarch.rpm"
  yum update
  yum -y install $PACKAGENAME
}

function install_omd_debian() {
  VERSION=$1
  PACKAGENAME=`pkgName $VERSION`
  REPOVERSION=`repoVersion $VERSION`

  export DEBIAN_FRONTEND=noninteractive
  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

  apt-get update
  apt-get install -y lsof vim git openssh-server tree tcpdump libevent-2.0-5 file make sudo lsyncd screen curl

  curl -s "https://labs.consol.de/repo/testing/RPM-GPG-KEY" | apt-key add -
  echo "deb http://labs.consol.de/repo/testing/debian $(cat /etc/os-release  | grep 'VERSION=' | tr '(' ')' | cut -d ')' -f2) main" > /etc/apt/sources.list.d/labs-consol-testing.list
  apt-get update
  apt-get install -y omd-labs-edition-daily
  apt-get clean

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}


function install_omd_ubuntu() {
  VERSION=$1
  PACKAGENAME=`pkgName $VERSION`
  REPOVERSION=`repoVersion $VERSION`
  export DEBIAN_FRONTEND=noninteractive

  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
  cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

  apt-get update
  apt-get install -y lsof vim git openssh-server tree tcpdump libevent-2.0-5 file make sudo lsyncd screen curl

  curl -s "https://labs.consol.de/repo/testing/RPM-GPG-KEY" | apt-key add -
  echo "deb http://labs.consol.de/repo/testing/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d'=' -f2) main" >> /etc/apt/sources.list
  apt-get update
  apt-get install -y omd-labs-edition-daily
  apt-get clean

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

main $@
