#!/bin/bash
#
# Copyright IBM Corporation 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Script to create a ramdisk and host a MongoDB database
#
# Prereqs:
# 1) MongoDB available and MONGO_ROOT var (below) set appropriately
# 2) You have permission to sudo (required to mount/umount a ramdisk)
# 3) (optional) You have the numactl package installed - see below.
# 
# The database can be started with affinity for servers which have multiple
# NUMA nodes (sockets), for better performance, or to coexist with processes on
# other nodes without interference.  This requires the 'numactl' package:
# 
#   sudo apt-get install numactl
#
# Set DB_AFFINITY (below) to something appropriate for your machine, or remove
# it if your machine is not NUMA (or you don't want affinity).
#
# If you want MongoDB to be remotely accessible, specify additional adapters
# (by IP address) in a comma-separated list in DB_ADAPTERS.
# 

DBNAME="hello_world"
MONGO_ROOT="$HOME/mongo3"
MOUNTPOINT="$HOME/ramdisk_${DBNAME}_mongodb"
MOUNTPOINT_TMPFS="${MOUNTPOINT}_tmpfs"
DB_DIR="${MOUNTPOINT}/${DBNAME}"
LOGFILE="${MOUNTPOINT}/mongod.log"
PIDFILE="${MOUNTPOINT}/mongod.pid"
DB_PORT="27017"
DB_AFFINITY="numactl --cpunodebind=1 --membind=1"
DB_ADAPTERS="127.0.0.1,192.168.0.81,192.168.1.40"

# Determine location of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function start {
  if [ -d "${DB_DIR}" ]; then
    echo "Error: ${DB_DIR} already exists (is server already running?)"
    exit 1
  fi
  # Create ramdisk
  let RAMDISK_SIZE_MB=4096
  let TMPFS_SIZE_MB=$RAMDISK_SIZE_MB+6
  let BLOCK_SIZE=4096
  let BLOCKS=$RAMDISK_SIZE_MB*1024*1024/$BLOCK_SIZE
  mkdir -p ${MOUNTPOINT} ${MOUNTPOINT_TMPFS}
  sudo mount -t tmpfs -o size=${TMPFS_SIZE_MB}M ${DBNAME} ${MOUNTPOINT_TMPFS}
  dd if=/dev/zero of=${MOUNTPOINT_TMPFS}/ramdisk.img bs=${BLOCK_SIZE} count=${BLOCKS}
  mke2fs -F -m 0 -b ${BLOCK_SIZE} -L ext2_${DBNAME} ${MOUNTPOINT_TMPFS}/ramdisk.img ${BLOCKS}
  sudo mount ${MOUNTPOINT_TMPFS}/ramdisk.img ${MOUNTPOINT} -t ext2 -o loop
  if [ $? != 0 ]; then
    echo "Error creating ramdisk"
    exit $?
  fi
  sudo chmod 777 ${MOUNTPOINT}

  # Create database
  mkdir ${DB_DIR}
  ${DB_AFFINITY} ${MONGO_ROOT}/bin/mongod --dbpath ${DB_DIR} --logpath ${LOGFILE} --pidfilepath ${PIDFILE} --port ${DB_PORT} --bind_ip ${DB_ADAPTERS} --nojournal --fork
  if [ $? -ne 0 ]; then
    echo "Error - could not start mongod"
    exit $?
  fi
  
  # Populate database
  ${MONGO_ROOT}/bin/mongo < $SCRIPT_DIR/create.js
}

function stop {
  ${MONGO_ROOT}/bin/mongod --dbpath ${DB_DIR} --logpath ${LOGFILE} --pidfilepath ${PIDFILE} --port ${DB_PORT} --shutdown
  if [ $? -ne 0 ]; then
    echo "Error - mongod did not shut down"
    # But try to unmount the ramdisk anyway (in case mongo was just dead)
  fi
  sudo umount ${MOUNTPOINT} ${MOUNTPOINT_TMPFS}
  if [ $? -ne 0 ]; then
    echo "Error - could not unmount ramdisk"
    exit $?
  else
    echo "Ramdisk unmounted"
  fi
}

function status {
  ${MONGO_ROOT}/bin/mongo --port ${DB_PORT} ${DBNAME} --quiet --eval "{ping: 1}" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Ramdisk server is running"
    exit 0
  else
    echo "Ramdisk server appears not to be running"
    exit 1
  fi
}

function shell {
  exec ${DB_AFFINITY} ${MONGO_ROOT}/bin/mongo --port ${DB_PORT} ${DBNAME}
}

case "$1" in
start)
  start
  ;;
stop)
  stop
  ;;
status)
  status
  ;;
shell)
  shell
  ;;
*)
  echo "Usage: $0 start | stop | status"
esac

