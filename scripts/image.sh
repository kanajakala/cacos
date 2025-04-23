#!/bin/bash

#this script is used to generate an initrd image (kernel/img/cacos.img) from the kernel/img/src directory

#first we test if the mkbootimg utility exists
FILE=.cache/mkbootimg
if test -f "$FILE"; then
    echo "$FILE exists, proceeding..."
else
    echo "The mkbootimg utility isn't installed, installing it..."
    zig build setup #this will install mkbootimg
fi

#now we are sure that there is a binary of mkbootimg in .cache

echo "=================="
echo "building the image"
echo "=================="

cd kernel/img
./../../.cache/mkbootimg ../bootboot.json cacos.img

echo "done"

