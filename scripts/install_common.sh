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
  dnf -y install \
    which \
    lsof \
    vim \
    git \
    openssh-server \
    tree \
    file \
    make \
    sudo \
    wget \
    unzip \
    tmux \
    ansible-core \
    glibc-langpack-en \

  popd
}

function install_common_debian() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get update
  apt-get install -y procps

  apt-get install -y locales apt-utils
  sed -i -r '/de_DE|en_US/s/^# *//' /etc/locale.gen
  dpkg-reconfigure --frontend=noninteractive locales

  test -f /etc/sysctl.conf || touch /etc/sysctl.conf
  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.all.disable_ipv6 = 1'    >> /etc/sysctl.d/20-ipv6-disable.conf
  echo 'net.ipv6.conf.lo.disable_ipv6 = 1'     >> /etc/sysctl.d/20-ipv6-disable.conf
  sysctl -p

  apt-get install -y \
    python3 \
    ansible \
    lsof \
    vim \
    git \
    openssh-server \
    tree \
    tcpdump \
    file \
    make \
    sudo \
    tmux \
    curl \
    gnupg2 \
    lsb-release \

  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

main $@
