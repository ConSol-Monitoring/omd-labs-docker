#!/usr/bin/env bash
# $1 = OS
# $2 = OMD version (master/latest/vX.XX)

# script must fail on errors, otherwise build would just continue and result in a broken image
set -e
set -x

function main() {
  BRANCH=$2
  BRANCH=${BRANCH#refs/heads/}
  BRANCH=${BRANCH#v}

  case $1 in
    rocky)  install_omd_rocky  $BRANCH;;
    debian) install_omd_debian $BRANCH;;
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

function install_omd_rocky() {
  VERSION=$1
  PACKAGENAME=`pkgName $VERSION`
  REPOVERSION=`repoVersion $VERSION`

  rpm -Uvh "https://labs.consol.de/repo/${REPOVERSION}/rhel9/x86_64/labs-consol-${REPOVERSION}.rhel9.noarch.rpm"
  yum update
  yum -y install $PACKAGENAME
  test -f /usr/bin/ping && chmod +s /usr/bin/ping
}

function install_omd_debian() {
  VERSION=$1
  PACKAGENAME=`pkgName $VERSION`
  REPOVERSION=`repoVersion $VERSION`

  export DEBIAN_FRONTEND=noninteractive
  curl -s "https://labs.consol.de/repo/stable/GPG-KEY-4096" -o /etc/apt/auth.conf.d/labs.consol.de-GPG-KEY-4096
  curl -s "https://labs.consol.de/repo/stable/RPM-GPG-KEY"  -o /etc/apt/auth.conf.d/labs.consol.de-RPM-GPG-KEY
  echo "deb http://labs.consol.de/repo/${REPOVERSION}/debian $(lsb_release -cs) main" > /etc/apt/sources.list.d/labs-consol-${REPOVERSION}.list
  apt-get update
  apt-get install -y ${PACKAGENAME}
  apt-get clean

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}


main $@
