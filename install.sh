#!/bin/bash

mkdir /opt/cypherdrives
cp * /opt/cypherdrives
cd /etc/systemd/system
ln -s /opt/cypherdrives/encryptedfile.service
systemctl enable encryptedfile
systemctl start encryptedfile
sleep 2
systemclt status encryptedfile

