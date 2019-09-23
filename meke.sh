#!/bin/bash

set -e
set -x

gcc -O2 ./cc/tointel.c -o ./cc/tointel

nasm bootloader/bootloader.asm -f bin -o me.img
dd bs=32768 count=256 if=/dev/zero >> me.img
truncate --size=-4096 me.img
echfs-utils me.img format 512

# compile the C files into assembly first
./cc/cc32 kernel/drivers/graphics.c

nasm userland/generic_program.asm -f bin -o generic_program.bin
echfs-utils me.img import generic_program.bin generic_program.bin

nasm kernel/stub.asm -f bin -o me.bin
echfs-utils me.img import me.bin me.bin

exit 0
