#!/usr/bin/env bash
# $1 = OS
# $2 = OMD version (master/latest/vX.XX)

# script must fail on errors, otherwise build would just continue and result in a broken image
set -e

function main() {
  BRANCH=$2
  BRANCH=${BRANCH#refs/heads/}
  BRANCH=${BRANCH#v}

  case $1 in
    centos) install_omd_centos $1 $BRANCH;;
    debian) install_omd_debian $BRANCH;;
    ubuntu) install_omd_ubuntu $BRANCH;;
    *) { echo "$1: Unknown OS type!"; exit 1; }
  esac

  # Logrotate settings
  find /omd/versions/default/skel/etc/logrotate.d -type f -exec sed -i 's/rotate [0-9]*/rotate 0/' {} \;
}

function pkgName() {
  case $1 in
    "master")
      echo "omd-labs-edition-daily"
      ;;
    "latest")
      echo "omd-labs-edition"
      ;;
    *)
      echo "omd-${STR}-labs-edition"
      ;;
  esac
}

function repoVersion() {
  STR=${STR#v}
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

  rpm -Uvh "https://labs.consol.de/repo/${REPOVERSION}/rhel8/x86_64/labs-consol-${REPOVERSION}.rhel8.noarch.rpm"
  yum update
  yum -y install $PACKAGENAME
}

function install_omd_debian() {
  VERSION=$1
  PACKAGENAME=`pkgName $VERSION`
  REPOVERSION=`repoVersion $VERSION`

  export DEBIAN_FRONTEND=noninteractive
  curl -s "https://labs.consol.de/repo/${REPOVERSION}/RPM-GPG-KEY" | apt-key add -
  echo "deb http://labs.consol.de/repo/${REPOVERSION}/debian $(lsb_release -cs) main" > /etc/apt/sources.list.d/labs-consol-${REPOVERSION}.list
  apt-get update
  apt-get install -y ${PACKAGENAME}
  apt-get clean

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}


function install_omd_ubuntu() {
  VERSION=$1
  PACKAGENAME=`pkgName $VERSION`
  REPOVERSION=`repoVersion $VERSION`
  export DEBIAN_FRONTEND=noninteractive

  curl -s "https://labs.consol.de/repo/${REPOVERSION}/RPM-GPG-KEY" | apt-key add -
  echo "deb http://labs.consol.de/repo/${REPOVERSION}/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/labs-consol-${REPOVERSION}.list
  apt-get update
  apt-get install -y ${PACKAGENAME}
  apt-get clean

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

main $@
