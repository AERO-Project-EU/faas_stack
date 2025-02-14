#!/bin/bash
set -ex

DATA_DIR=/var/lib/containerd/devmapper
POOL_NAME=kata_fc_devpool

mkdir -p ${DATA_DIR}

# Create data file
touch "${DATA_DIR}/data"
truncate -s 50G "${DATA_DIR}/data"

# Create metadata file
touch "${DATA_DIR}/meta"
truncate -s 5G "${DATA_DIR}/meta"

# Allocate loop devices
DATA_DEV=$(losetup --find --show "${DATA_DIR}/data")
META_DEV=$(losetup --find --show "${DATA_DIR}/meta")

# Define thin-pool parameters.
# See https://www.kernel.org/doc/Documentation/device-mapper/thin-provisioning.txt for details.
SECTOR_SIZE=512
DATA_SIZE="$(blockdev --getsize64 -q ${DATA_DEV})"
LENGTH_IN_SECTORS=$(bc <<< "${DATA_SIZE}/${SECTOR_SIZE}")
DATA_BLOCK_SIZE=128
LOW_WATER_MARK=32768

# Create a thin-pool device
dmsetup create "${POOL_NAME}" \
    --table "0 ${LENGTH_IN_SECTORS} thin-pool ${META_DEV} ${DATA_DEV} ${DATA_BLOCK_SIZE} ${LOW_WATER_MARK}"

