#!/bin/bash -e
# pi-gen Stage-Init: kopiert die Root-FS aus der vorherigen Stage als Ausgang
# in unser Work-Verzeichnis. Standard-pi-gen-Pattern.

if [ ! -d "${ROOTFS_DIR}" ]; then
    copy_previous
fi
