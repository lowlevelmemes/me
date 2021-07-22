#!/bin/bash

set -e
set -x

if ! [ -d limine ]; then
    git clone https://github.com/limine-bootloader/limine.git --depth=1 --branch=v2.0-branch-binary
    ( cd limine && make )
fi

rm -f me.hdd
dd if=/dev/zero bs=1M count=0 seek=64 of=me.hdd

parted -s me.hdd mklabel msdos
parted -s me.hdd mkpart primary 1 100%

echfs-utils -m -p0 me.hdd quick-format 32768

# Install Limine
./limine/limine-install me.hdd
echfs-utils -m -p0 me.hdd import limine/limine.sys limine.sys
echfs-utils -m -p0 me.hdd import limine.cfg limine.cfg

gcc -O2 ./cc/tointel.c -o ./cc/tointel

# compile the C files into assembly first
./cc/cc32 kernel/drivers/graphics.c

nasm userland/generic_program.asm -f bin -o generic_program.bin
echfs-utils -m -p0 me.hdd import generic_program.bin generic_program.bin

nasm kernel/stub.asm -f bin -o me.bin
echfs-utils -m -p0 me.hdd import me.bin me.bin

exit 0
