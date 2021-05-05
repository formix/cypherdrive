#!/bin/bash

MOUNT_POINT=/home/user/cypherdrive

umount $MOUNT_POINT
cryptsetup close brrp_clear
losetup -d /dev/loop0

