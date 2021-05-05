#!/bin/bash

MOUNT_POINT=/home/user/cypherdrive

losetup loop0 -P /root/encryptedfile.img
cryptsetup open /dev/loop0 encryptedfile -d /root/encryptedfile.key
mount $MOUNT_POINT
