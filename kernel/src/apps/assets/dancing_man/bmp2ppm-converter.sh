#!/bin/bash
#delete all previous files
rm *.ppm
#convert all files to ppm
ls | xargs -I % sh -c "magick % %.ppm && rm %"
#rename all the files
mmv "00*.bmp*" "#1.ppm"
echo "Converted all the files !"
ls
