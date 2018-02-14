#!/bin/bash

set -e
set -x

nasm bootloader/bootloader.asm -f bin -o me.img
dd bs=32768 count=256 if=/dev/zero >> me.img
truncate --size=-4096 me.img
echfs-utils me.img format 32768

nasm kernel/stub.asm -f bin -o me.bin
echfs-utils me.img import me.bin me.bin

exit 0
