#!/bin/bash
#
# Copyright (c) 2005, 2006 Miek Gieben
# See LICENSE for the license
#
# Exclude certain FILES from getting back upped 
# use bash' regular expressions to avoid forking grep
# watch out with this, if you remove parent directories
# without removing the files, you will get problem when
# trying mirror the files

declare -a fileexcludelist
declare -a direxcludelist

# copied from my hdup.conf
fileexcludelist=".slide_img.* .thumb_img.*"
direxcludelist="lost+found/ /proc/ /dev/ /sys/ .Trash/ .Cache/ tmp/"

. ./shared.sh
backup_defines
declare -a path # catch spacing in the path

while read mode uid gid path
do
        dump=${mode:0:1}        # to add or remove
        mode=${mode:1}          # st_mode bits
        typ=0
        if [[ $(($mode & $S_ISDIR)) == $S_ISDIR ]]; then
                typ=1;
        fi
        if [[ $(($mode & $S_ISLNK)) == $S_ISLNK ]]; then
                typ=2;
        fi
        
        case $typ in
                0|2)      # reg file or link
                for file in $fileexcludelist; do 
                        if [[ "$path" =~ $i ]]; then
                                continue;
                        fi
                done
                # don't exclude, print it
                echo "$dump$mode $uid $gid $path"
                ;;
                1)      # directory
                for i in $direxcludelist; do 
                        if [[ "$path" =~ $i ]]; then
                                continue;
                        fi
                done
                # don't exclude, print it
                echo "$dump$mode $uid $gid $path"
                ;;
        esac
done 
