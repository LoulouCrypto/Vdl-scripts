#!/bin/bash
# Script done by LoulouCrypto
# https://www.louloucrypto.fr

CONFIG_FILE='vidulum.conf'
CONFIGFOLDER='/home/$USER/.vidulum'
PARAMFOLDER='/home/$USER/.vidulum-params'
COIN_PATH='/usr/local/bin'
#64 bit only
COIN_TGZ='https://github.com/vidulum/vidulum/releases/download/v2.2.0/VDL-Linux.zip'
BOOTSTRAP_TGZ='https://downloads.vidulum.app/bootstrap.zip'
COIN_DAEMON="vidulumd"
COIN_CLI="vidulum-cli"
COIN_TX"vidulum-tx"
COIN_NAME='vidulum'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

progressfilt () {
  local flag=false c count cr=$'\r' nl=$'\n'
  while IFS='' read -d '' -rn 1 c
  do
    if $flag
    then
      printf '%c' "$c"
    else
      if [[ $c != $cr && $c != $nl ]]
      then
        count=0
      else
        ((count++))
        if ((count > 1))
        then
          flag=true
        fi
      fi
    fi
  done
}

function detect_ubuntu() {
 if [[ $(lsb_release -d) == *18.04* ]]; then
   UBUNTU_VERSION=18
 elif [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
 elif [[ $(lsb_release -d) == *14.04* ]]; then
   UBUNTU_VERSION=14
else
   echo -e "${RED}You are not running Ubuntu 14.04, 16.04 or 18.04 Installation is cancelled.${NC}"
   exit 1
fi
}

function configure_startup() {
  cat << EOF > /etc/init.d/$COIN_NAME-$USER
#! /bin/bash
### BEGIN INIT INFO
# Provides: $COIN_NAME
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: $COIN_NAME
# Description: This file starts and stops $COIN_NAME MN server
#
### END INIT INFO
case "\$1" in
 start)
   sleep $TIMER
   $COIN_PATH/$COIN_DAEMON -daemon -conf=/home/$USER/.vidulum/$CONFIG_FILE -datadir=/home/$USER/.vidulum
   sleep 5
   ;;
 stop)
   $COIN_PATH/$COIN_CLI -conf=/home/$USER/.vidulum/$CONFIG_FILE -datadir=/home/$USER/.vidulum stop
   ;;
 restart)
   $COIN_CLI stop
   sleep 10
   $COIN_PATH/$COIN_CLI -conf=/home/$USER/.vidulum/$CONFIG_FILE -datadir=/home/$USER/.vidulum restart
   ;;
 *)
   echo "Usage: $COIN_NAME-$USER {start|stop|restart}" >&2
   exit 3
   ;;
esac
EOF
chmod +x /etc/init.d/$COIN_NAME-$USER >/dev/null 2>&1
update-rc.d $COIN_NAME-$USER defaults >/dev/null 2>&1
/etc/init.d/$COIN_NAME-$USER start >/dev/null 2>&1
if [ "$?" -gt "0" ]; then
 sleep 5
 /etc/init.d/$COIN_NAME-$USER start >/dev/null 2>&1
fi
}

function configure_systemd() {
cd ~/

sudo cat << EOF > $COIN_NAME-$USER.service
[Unit]
Description=$COIN_NAME-$USER service
After=network.target
[Service]
User=$USER
Type=forking
#PIDFile=/home/$USER/.vidulum/$COIN_NAME.pid
TimeoutStartSec=infinity
ExecStartPost=/bin/sleep $TIMER
ExecStart=$COIN_PATH/$COIN_DAEMON -daemon -conf=/home/$USER/.vidulum/$CONFIG_FILE -datadir=/home/$USER/.vidulum
ExecStop=-$COIN_PATH/$COIN_CLI -conf=/home/$USER/.vidulum/$CONFIG_FILE -datadir=/home/$USER/.vidulum stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
sudo mv $COIN_NAME-$USER.service /etc/systemd/system/

  sudo systemctl daemon-reload
  sleep 3
  sudo systemctl start $COIN_NAME-$USER.service
  sudo systemctl enable $COIN_NAME-$USER.service >/dev/null 2>&1
  
  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME-$USER.service"
    echo -e "systemctl status $COIN_NAME-$USER.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}


function create_config() {
  cd ~/
  mkdir /home/$USER/.vidulum >/dev/null 2>&1
  mkdir /home/$USER/.vidulum-params >/dev/null 2>&1
  echo "Downloading $COIN_NAME params"
  cd /home/$USER/.vidulum-params
  wget https://github.com/vidulum/sapling-params/releases/download/sapling/sprout-proving.key >/dev/null 2>&1
  wget https://github.com/vidulum/sapling-params/releases/download/sapling/sprout-verifying.key >/dev/null 2>&1
  wget https://github.com/vidulum/sapling-params/releases/download/sapling/sprout-groth16.params >/dev/null 2>&1
  wget https://github.com/vidulum/sapling-params/releases/download/sapling/sapling-spend.params >/dev/null 2>&1
  wget https://github.com/vidulum/sapling-params/releases/download/sapling/sapling-output.params >/dev/null 2>&1
  cd ..
  sleep 2
  sleep 2
  cd .vidulum
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > vidulum.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
listen=1
server=1
txindex=1
daemon=1
rpcport=$RPC_PORT
port=$COIN_PORT
EOF
cd ~/
}

function create_key() {
  echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}.\nLeave it blank to generate a new ${RED}$COIN_NAME Masternode Private Key${NC} for you:"
  read -e COINKEY
  echo -e "Enter your ${RED}$COIN_NAME TX_OUTPUT${NC}.\nLeave it blank if you want to put it manualy"
  read -e TX_OUTPUT
  echo -e "Enter your ${RED}$COIN_NAME TX_INDEX${NC}.\nLeave it blank if you want to put it manualy"
  read -e TX_INDEX
  sleep 2
  if [[ -z "$COINKEY" ]]; then
	$COIN_DAEMON -daemon
      sleep 30
    COINKEY=$($COIN_CLI -conf=/home/$USER/.vidulum/vidulum.conf -datadir=/home/$USER/.vidulum masternode genkey)
    if [ "$?" -gt "0" ];
      then
      echo -e "${RED}Wallet not fully loaded. Let us wait for 30s and try again to generate the Private Key${NC}"
      sleep 30
      COINKEY=$($COIN_CLI -conf=/home/$USER/.vidulum/vidulum.conf -datadir=/home/$USER/.vidulum masternode genkey)
      if [ "$?" -gt "0" ];
      then
        echo -e "${RED}Wallet not fully loaded. Let us wait for another 30s and try again to generate the Private Key${NC}"
        sleep 30
        COINKEY=$($COIN_CLI -conf=/home/$USER/.vidulum/vidulum.conf -datadir=/home/$USER/.vidulum masternode genkey)
      fi
    fi
  $COIN_CLI stop
fi
clear
}

function update_config() {
  cat << EOF >> /home/$USER/.vidulum/vidulum.conf
logintimestamps=1
maxconnections=256
#bind=
staking=0
masternode=1
externalip=[$NODEIP]
masternodeaddr=[$NODEIP]:7676
masternodeprivkey=$COINKEY

# Seed Nodes
addnode=51.79.86.4
addnode=54.39.23.85
addnode=207.148.8.58
addnode=[2607:5300:203:272d::25]
addnode=[2607:5300:203:272d::19]
addnode=[2a02:c207:2033:990::2]
addnode=[2a02:c207:2030:2446::11:10]

#User : $USER
# $USER [$NODEIP]:7676 $COINKEY  $TX_OUTPUT $TX_INDEX
EOF
sleep 1
  cd /home/$USER/.vidulum/
  rm -rf blocks 
  rm -rf chainstate 
  sleep 1
  echo -e "Downloading BootStrap"
  wget --progress=bar:force $BOOTSTRAP_TGZ 2>&1 | progressfilt
  echo -e "Extracting BootStrap"
  unzip bootstrap.zip >/dev/null 2>&1
  rm -f bootstrap.zip
  mv -f bootstrap/blocks /home/$USER/.vidulum/
  mv -f bootstrap/chainstate /home/$USER/.vidulum/
  sleep 2
}

function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN} $COIN_PORT ${NC}"
  sudo ufw allow ssh >/dev/null 2>&1
  sudo ufw allow $COIN_PORT >/dev/null 2>&1
  sudo ufw default allow outgoing >/dev/null 2>&1
  echo "y" | sudo ufw enable >/dev/null 2>&1
  sudo ufw reload
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(curl --interface $ips --connect-timeout 2 hostname --all-ip-addresses || hostname -i)
  do
    NODE_IPS+=($(/sbin/ip -o addr show scope global | awk '{gsub(/\/.*/,"",$4); print $4}'))
    #NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com && curl --interface $ips --connect-timeout 2 -6 icanhazip.com))
  done
clear
  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
	echo -e "${YELLOW}"
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}


function detect_ubuntu() {
 if [[ $(lsb_release -d) == *18.04* ]]; then
   UBUNTU_VERSION=18
 elif [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
 elif [[ $(lsb_release -d) == *14.04* ]]; then
   UBUNTU_VERSION=14
else
   echo -e "${RED}You are not running Ubuntu 14.04, 16.04 or 18.04 Installation is cancelled.${NC}"
   exit 1
fi
}

function create_swap() {
 echo -e "Checking if swap space is needed."
 PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
 SWAP=$(swapon -s)
 if [[ "$PHYMEM" -lt "2"  &&  -z "$SWAP" ]]
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM without SWAP, creating 6G swap file.${NC}"
    SWAPFILE=$(mktemp)
    sudo dd if=/dev/zero of=$SWAPFILE bs=1024 count=6M
    sudo chmod 600 $SWAPFILE
    sudo mkswap $SWAPFILE
    sudo swapon -a $SWAPFILE
 else
  echo -e "${GREEN}The server running with at least 2G of RAM, or a SWAP file is already in place.${NC}"
 fi
 clear
}


function important_information() {
 echo
 echo -e "================================================================================"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${RED}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
   echo -e "Start: ${RED}systemctl start $COIN_NAME-$USER.service${NC}"
   echo -e "Stop: ${RED}systemctl stop $COIN_NAME-$USER.service${NC}"
   echo -e "Status: ${RED}systemctl status $COIN_NAME-$USER.service${NC}"
 else
   echo -e "Start: ${RED}/etc/init.d/$COIN_NAME_$USER start${NC}"
   echo -e "Stop: ${RED}/etc/init.d/$COIN_NAME_$USER stop${NC}"
   echo -e "Status: ${RED}/etc/init.d/$COIN_NAME_$USER status${NC}"
 fi
 echo -e "VPS_IP:PORT ${RED}[$NODEIP]:7676 ${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$COINKEY ${NC}"
 echo -e "Check if $COIN_NAME is running by using the following command:\n${RED}ps -ef | grep $COIN_DAEMON | grep -v grep${NC}"
  echo -e "copy to your masternode.conf wallet: ${RED}Your_Alias [$NODEIP]:7676 $COINKEY $TX_OUTPUT $TX_INDEX ${NC}"
 echo -e "================================================================================"
 echo -e "Lunching ${RED}Vidulum Masternode${NC}, it may take some time due to the${RED} $TIMER Sec Start Delay.${NC}"
}

function nbr_nodes() {
 NBR_DAEMON=$(ps -C vidulumd -o pid= | wc -l)
 figlet -f slant "Vidulum"
 echo -e "${RED}How many running $COIN_NAME nodes on this server ? $NBR_DAEMON ? ${NC}"
 read -e NBR_NODES
 COIN_PORT=$(expr 7676 + $NBR_NODES '*' 2)
 RPC_PORT=$(expr $COIN_PORT + 1)
 TIMER=$(($NBR_NODES * 30))
}

function prepare_system_for_download() {
echo -e "Prepare the system to install ${GREEN}$COIN_NAME${NC} master node."
sudo apt-get update >/dev/null 2>&1
#echo -e "Upgrading System, it may take some time.${NC}"
#sudo apt-get upgrade -y >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
sudo apt-get install -y curl systemd figlet >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt install -y curl sytemd figlet"
 exit 1
fi

clear
}

function setup_node() {
  nbr_nodes
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  important_information
  if (( $UBUNTU_VERSION == 16 || $UBUNTU_VERSION == 18 )); then
    configure_systemd
  else
    configure_startup
  fi
}


##### Main #####
clear
cd ~/
detect_ubuntu
create_swap
prepare_system_for_download
setup_node
cd ~/
rm -f vidulum-multi-install.sh

# If you want to support me
# vdl wallet : 
# v1MYFzCiHPgbzFbesutnEwMs5Z37pACoVp4
