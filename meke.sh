#!/bin/bash

set -e
set -x

if [ ! -f ./echfs-utils.c ]; then
    wget https://raw.githubusercontent.com/echidnaOS/echidnaOS/master/echidnafs/echfs-utils.c
fi
if [ ! -f ./echfs-utils ]; then
    gcc -O2 echfs-utils.c -o echfs-utils
fi
if [ ! -f ./cc/tointel ]; then
    gcc -O2 ./cc/tointel.c -o ./cc/tointel
fi

nasm bootloader/bootloader.asm -f bin -o me.img
dd bs=32768 count=256 if=/dev/zero >> me.img
truncate --size=-4096 me.img
./echfs-utils me.img format 512

# compile the system.c library
./cc/cc16 cc/system.c

# compile the C files into assembly first
./cc/cc16 kernel/ctest.c

nasm kernel/stub.asm -f bin -o me.bin
./echfs-utils me.img import me.bin me.bin

nasm userland/generic_program.asm -f bin -o generic_program.bin
./echfs-utils me.img import generic_program.bin generic_program.bin

exit 0
