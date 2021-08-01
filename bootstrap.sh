
#!/bin/bash
# Script done by LoulouCrypto
# https://www.louloucrypto.fr
cd ~
sleep 1
cd .vidulum
sudo systemctl stop vidulum-$USER
sleep 1
vidulum-cli stop
sleep 2
rm -r blocks chainstate database
sleep 2 
wget https://zang.ovh/vdl/bootstrap.zip
sleep 1 
unzip bootstrap.zip
sleep 1
rm -r bootstrap*
sleep 2
sudo systemctl start vidulum-$USER
