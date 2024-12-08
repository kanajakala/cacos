#!/bin/bash

#compiling the apps:
echo "\n\nCOMPILING APPS"
FILES="./kernel/src/apps/asm/*.asm"
for f in $FILES
do
  echo "Compiling"
  # take action on each file. $f store current file name
  nasm "$f" -o "${f::-4}.bin"
done
cd kernel/src/apps/asm/
mv *.bin ../../filesystem/binaries
