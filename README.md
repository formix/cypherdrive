# Saving Sensitive Data In a Linux File System
Sometimes, we need to make sure our data at rest is safe from prying eyes. This article explains how to make an encrypted loopback block device mounted by systemd.
To execute most of these commands, you have to be root. I recommend opening a root session with "sudo su -". Having the encrypted file within a folder masked 700 and owned by root:root is the best way to go.

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

```
/dev/loop0: []: (/root/encryptedfile.img)
```

There we have it! A new block device now exists in your system. From there you could already format it, mount it, etc. But that is not what we want. We want an encrypted file system. Read-on...

## Initialize and map the encrypted device
We will use LUKS to encrypt our block device. The next step is to prepare our blank device to be encrypted:

```bash
cryptsetup luksFormat /dev/loop0
```

That command will ask you for a passphrase. Enter a secure passphrase and don't forget it. Doing that creates a secure symmetric key encoded with this password. Do not forget that our goal is to mount that volume automatically at boot. We need a way to provide the password without typing it. Now lets add a keyfile to store a secure password: 

```bash
dd if=/dev/random bs=32 count=1 of=/root/encryptedfile.key
cryptsetup luksAddKey /dev/loop0 /root/encryptedfile.key
```

When prompted, enter the password you created earlier. I takes a few seconds to apply that new key. Now both your initial password and that new key file can unlock your volume.

Next we will create a new mapped device to handle the encryption and decryption. We will leverag that new keyfile to see if that works. Execute the following command:

# cryptsetup open /dev/loop0 encryptedfile -d /root/encryptedfile.key

It should create a new device at /dev/mapper/encryptedfile. Nice work!

Formatting the drive for your needs
Next, just format that new device with the file system you like. In this case, I'll use ext4fs because why not. In your case vfat might be something desirable or else.

# mkfs -t ext4 /dev/mapper/encryptedfile

Configure fstab with correct permissions
For this one, I'll drop the line here without explaining it much. If you want more information on how fstab works, just check at the reference links at the end of the article.
/dev/mapper/cypherdrive  /home/<user>/mnt   ext4fs    defaults,noauto,umask=007,uid=<user>,gid=<user_group>      0 0

The file system could as well be mounted somewhere in /var for a more general use case. In the case I have in mind here, Im targetting a usage where a particular application for a given service has to work with tat data exclusively. That is why I mount into a private user directory and severely restricted the access to that account directory.

Note that we don't want to automount that drive at boot since there is a lot of command to execute before the loopback and mapper devices exist. To do that, we will create a mounting, an unmounting and a systemd service scripts in the next section.

Create Systemd scripts to mount the device
You can dowload the scripts here. Change the values inside of it to fit your needs. You probably want to change the directory and the file name if the IMG file, the directory and key file name, loop and mapper device names, etc. Make it your own. Once ready, call the install shell script as root and it should work!

References
[1] How to create virtual block device in linux
[2] Encrypting block devices using LUKS
[3] Adding a key file to an existing LUKS volume
[4] fstab man page