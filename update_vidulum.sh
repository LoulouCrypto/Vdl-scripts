#!/bin/bash
# Script done by LoulouCrypto
# https://www.louloucrypto.fr
COIN_PATH='/usr/local/bin/'
#64 bit only
COIN_TGZ='https://github.com/vidulum/vidulum/releases/download/v2.2.0/VDL-Linux.zip'
COIN_DAEMON="vidulumd"
COIN_CLI="vidulum-cli"
COIN_TX="vidulum-tx"
COIN_NAME='vidulum'

#update lunch
  echo -e "Updating your System"
  apt-get update > /dev/null 2>&1
  apt-get upgrade -y > /dev/null 2>&1
  echo -e "Prepare to download $COIN_NAME update"
  cd ~/
  TMP_FOLDER=$(mktemp -d)
  cd $TMP_FOLDER
  wget --progress=bar:force $COIN_TGZ 2>&1
  COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
  unzip $COIN_ZIP >/dev/null 2>&1
  cd VDL-Linux
  chmod +x $COIN_DAEMON $COIN_CLI $COIN_TX
  echo -e "Stoping your VDL Nodes"
  systemctl stop Vidulum
  systemctl stop vidulum-*
  $COIN_CLI stop > /dev/null 2>&1
  killall $COIN_DAEMON > /dev/null 2>&1 
  echo -e "Updating $COIN_NAME"
  cp -pf $COIN_DAEMON $COIN_CLI $COIN_TX $COIN_PATH
  cd ..
  rm -f $COIN_ZIP >/dev/null 2>&1
  cd ~/ >/dev/null
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  rm update_vidulum.sh

  systemctl start Vidulum >/dev/null 2>&1 && sleep 30
  systemctl start vidulum-vdl*
  echo -e "Update Done, If you are using Multi VDL Mn, Please Lunch the others"
$COIN_CLI getinfo
exit
# If you want to support me
# vdl wallet : 
# v1MYFzCiHPgbzFbesutnEwMs5Z37pACoVp4
