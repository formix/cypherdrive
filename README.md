# Saving Sensitive Data In a Linux File System

Sometimes, we need to make sure our data at rest is safe from prying eyes. This article explains how to make an encrypted loopback block device mounted by systemd. To execute most of these commands, you have to be root. I recommend opening a root session with `sudo su -`. Having the encrypted file within a folder masked 700 and owned by root:root is the best way to go.

Over time, I plan to integrate as much of that documentation into some command line python script or UI thing if that makes sense. Come back often and ask questions in the issue tab if you need help actionning all this.

I documented my process of doing an ecrypted mount point on a RHEL7 (Red Hat Enterprise Linux 7) system. I tried to make the documentation and scripts as universal as possible but distro variations may require some tweaking. I'll try it on my Debian based machine at home as soon as possible and mark any distro dependent commands in the future, if any. Have fun!

## Install required packages

```bash
yum install cryptsetup parted
```

## Create and attach the loopback block device

The following line will create a 10 megabytes file filled with zeros. Obviously you should create a file with a size that makes sense for your needs. Then it will attach that file as a loopback device named *loop0*.

```bash
dd if=/dev/zero of=encryptedfile.img bs=1M count=10
sudo losetup loop0 -P encryptedfile.img
```

You can check if the loop device was attached properly by running the following command:

```bash
losetup -a
```

It shall display:

```text
/dev/loop0: []: (/root/encryptedfile.img)
```

Does it show up properly? Then we have it! A new block device now exists in your system. From there you could already format it, mount it, etc. But that is not what we want. We want an encrypted file system. Read-on...

## Initialize and map the encrypted device

We will use LUKS to encrypt our block device. The next step is to prepare our blank device to be encrypted:

```bash
cryptsetup luksFormat /dev/loop0
```

That command will ask you for a passphrase. Enter a secure passphrase and don't forget it. Doing that creates a secure symmetric key encoded with this password. Do not forget that our goal is to mount that volume automatically at boot. We need a way to provide the password without typing it. To do that, we have to add a keyfile to store a secure password:

```bash
dd if=/dev/random bs=32 count=1 of=/root/encryptedfile.key
cryptsetup luksAddKey /dev/loop0 /root/encryptedfile.key
```

When prompted, enter the password you created earlier. It takes a few seconds to apply that new key. Now both your initial password and that new key file can unlock your encrypted device.

Next we will create a new mapped device to handle the encryption and decryption. We will leverage that new keyfile to see if that works. Execute the following command:

```bash
cryptsetup open /dev/loop0 encryptedfile -d /root/encryptedfile.key
```

It should create a new device at /dev/mapper/encryptedfile. Nice work!

## Formatting the drive for your needs

Next, just format that new device with the file system you like. In this case, I'll use ext4fs because why not. In your case vfat might be something desirable, or else.

```bash
mkfs -t ext4 /dev/mapper/encryptedfile
```

## Configure fstab with restricted permissions

For this one, I'll drop the line here without explaining it much. If you want more information on how fstab works, just check at the reference links at the end of the article. Edit `/etc/fstab` and add that line:

```bash
/dev/mapper/encryptedfile  /home/<user>/mnt   ext4    defaults,noauto      0 0
```

The file system could as well be mounted somewhere in `/var` for a more general use case. In the case I have in mind, I'm targetting a usage where a particular application for a given service has to work with that data exclusively. That is why I mount it into a private user directory.

Note that we don't want to automount that drive at boot since there is a lot of commands to execute to bring the loopback and mapper devices into existence. To do that, we will create a systemd service to mount and unmount that device in the next section.

## Create Systemd scripts to mount the device

You can dowload the scripts [here](https://github.com/formix/cypherdrive/archive/refs/tags/1.0.0.tar.gz). Change the values inside of it to fit your needs. You probably want to change the directory and the file name if the IMG file, the directory and key file name, loop and mapper device names, etc. Make it your own. Once ready, call the install shell script as root and it should work!

## References

1. [How to create virtual block device in linux](https://www.thegeekdiary.com/how-to-create-virtual-block-device-loop-device-filesystem-in-linux/)
2. [Encrypting block devices using LUKS](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/encrypting-block-devices-using-luks_security-hardening)
3. [Adding a key file to an existing LUKS volume](https://access.redhat.com/solutions/230993)
4. [fstab man page](https://man7.org/linux/man-pages/man5/fstab.5.html)
