#!/bin/bash

set -e
set -x

# Download and build qloader2's toolchain
if ! [ -d qloader2 ]; then
    git clone https://github.com/qword-os/qloader2.git
    ( cd qloader2/toolchain && ./make_toolchain.sh "$MAKEFLAGS" )
fi

rm -f me.hdd
dd if=/dev/zero bs=1M count=0 seek=64 of=me.hdd

parted -s me.hdd mklabel msdos
parted -s me.hdd mkpart primary 1 100%

echfs-utils -m -p0 me.hdd quick-format 32768

# Install qloader2
( cd qloader2 && make && ./qloader2-install ../me.hdd )

gcc -O2 ./cc/tointel.c -o ./cc/tointel

# compile the C files into assembly first
./cc/cc32 kernel/drivers/graphics.c

nasm userland/generic_program.asm -f bin -o generic_program.bin
echfs-utils -m -p0 me.hdd import generic_program.bin generic_program.bin

nasm kernel/stub.asm -f bin -o me.bin
echfs-utils -m -p0 me.hdd import me.bin me.bin

echfs-utils -m -p0 me.hdd import qloader2.cfg qloader2.cfg

exit 0
