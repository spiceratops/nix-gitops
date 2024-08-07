#!/usr/bin/env bash

set -e

function yesno() {
    local prompt="$1"

    while true; do
        read -rp "$prompt [y/n] " yn
        case $yn in
            [Yy]* ) echo "y"; return;;
            [Nn]* ) echo "n"; return;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

cat << Introduction
This script will format the *entire* disk with a 1GB boot partition
(labelled NIXBOOT), 16GB of swap, then allocating the rest to ZFS.

The following ZFS datasets will be created:
    - rpool/local/root (mounted at / with blank snapshot)
    - rpool/local/nix (mounted at /nix)
    - rpool/safe/persist (mounted at /persist)

Introduction

# in a vm, special case
if [[ -b "/dev/vda" ]]; then
DISK="/dev/vda"

BOOTDISK="${DISK}3"
SWAPDISK="${DISK}2"
ZFSDISK="${DISK}1"
# normal disk
else
cat << FormatWarning
Please enter the disk by id to be formatted *without* the part number.
(e.g. nvme-eui.0123456789). Your devices are shown below:

FormatWarning

ls -al /dev/disk/by-id

echo ""

read -r DISKINPUT

DISK="/dev/disk/by-id/${DISKINPUT}"

BOOTDISK="${DISK}-part3"
SWAPDISK="${DISK}-part2"
ZFSDISK="${DISK}-part1"
fi

echo "Boot Partiton: $BOOTDISK"
echo "SWAP Partiton: $SWAPDISK"
echo "ZFS Partiton: $ZFSDISK"

do_format=$(yesno "This irreversibly formats the entire disk. Are you sure?")
if [[ $do_format == "n" ]]; then
    exit
fi

echo "Creating partitions"
sudo blkdiscard -f "$DISK"

sudo sgdisk -n3:1M:+1G -t3:EF00 "$DISK"
sudo sgdisk -n2:0:+16G -t2:8200 "$DISK"
sudo sgdisk -n1:0:0 -t1:BF01 "$DISK"

# notify kernel of partition changes
sudo sgdisk -p "$DISK" > /dev/null
sleep 5

echo "Creating Swap"
sudo mkswap "$SWAPDISK" --label "SWAP"
sudo swapon "$SWAPDISK"

echo "Creating Boot Disk"
sudo mkfs.fat -F 32 "$BOOTDISK" -n EFI

# setup encryption
use_encryption=$(yesno "Use encryption? (Encryption must also be enabled within host config.)")
if [[ $use_encryption == "y" ]]; then
    encryption_options=(-O encryption=aes-256-gcm -O keyformat=passphrase -O keylocation=prompt)
else
    encryption_options=()
fi

echo "Creating base zpool"
sudo zpool create -f \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=zstd \
    -O acltype=posixacl \
    -O atime=off \
    -O xattr=sa \
    -O normalization=formD \
    -O mountpoint=none \
    "${encryption_options[@]}" \
    rpool "$ZFSDISK"

echo "Creating /"
sudo zfs create -o mountpoint=legacy rpool/local
sudo zfs create -o mountpoint=legacy rpool/local/root
sudo zfs snapshot rpool/local/root@blank
sudo mount -t zfs rpool/local/root /mnt

# create the boot parition after creating root
echo "Mounting /boot (efi)"
sudo mount --mkdir "$BOOTDISK" /mnt/boot

echo "Creating /nix"
sudo zfs create -o mountpoint=legacy rpool/local/nix
sudo mount --mkdir -t zfs rpool/local/nix /mnt/nix

# handle persist, possibly from snapshot
restore_snapshot=$(yesno "Do you want to restore from a persist snapshot?")
if [[ $restore_snapshot == "y" ]]; then
    echo "Enter full path to snapshot: "
    read -r snapshot_file_path
    echo

    echo "Creating /persist"
    # disable shellcheck (sudo doesn't affect redirects)
    # shellcheck disable=SC2024
    sudo zfs receive -o mountpoint=legacy rpool/safe/persist < "$snapshot_file_path"

else
    echo "Creating /persist"
    sudo zfs create -o mountpoint=legacy rpool/safe
    sudo zfs create -o mountpoint=legacy rpool/safe/persist
fi
sudo mount --mkdir -t zfs rpool/safe/persist /mnt/persist

while true; do
    read -rp "Which host to install? (mnas / nixstation) " host
    case $host in
        mnas|nixstation ) break;;
        * ) echo "Invalid host. Please select a valid host.";;
    esac
done

read -rp "Enter git rev for flake (default: main): " git_rev
echo "Installing NixOS"
# nixos minimal iso does not have git
nix-shell -p git nixFlakes --command \
    "sudo nixos-install --no-write-lock-file --flake \"github:spiceratops/nix-gitops/${git_rev:-main}#$host\""

echo "To setup secrets, run \"install-remote-secrets\" on another host. Otherwise, it is now safe to reboot."