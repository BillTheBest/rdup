#!/bin/bash
#
# Copyright (c) 2005, 2006 Miek Gieben
# See LICENSE for the license
#
# This script implement a mirroring backup scheme

. ./shared.sh

backup_defines
backup_cmd_options $@
backup_create_top $backupdir
declare -a path # catch spacing in the path

while read mode uid gid path
do
        dump=${mode:0:1}        # to add or remove
        mode=${mode:1}          # st_mode bits
        bits=$(($mode & $S_MMASK)) # permission bits
        bits=`printf "%o" $bits` # and back to octal again
        typ=0
        if [[ $(($mode & $S_ISDIR)) == $S_ISDIR ]]; then
                typ=1;
        fi
        if [[ $(($mode & $S_ISLNK)) == $S_ISLNK ]]; then
                typ=2;
        fi
        
        if [[ $dump == "+" ]]; then
                # add
                case $typ in
                        0)      # reg file
                        [ -f "$backupdir/$path" ] && mv "$backupdir/$path" "$backupdir/$path.$suffix"
                        if [[ -z $gzip ]]; then
                                cat "$path" > "$backupdir/$path"
                        else 
                                cat "$path" | gzip -c > "$backupdir/$path"
                        fi
                        ;;
                        1)      # directory
                        [ ! -d "$backupdir/$path" ] && mkdir -p "$backupdir/$path"
                        ;;
                        2)      # link
                        [ -L "$backupdir/$path" ] && mv "$backupdir/$path" "$backupdir/$path.$suffix"
                        cp -a "$path" "$backupdir/$path"
                        ;;
                esac
                chown $uid:$gid "$backupdir/$path"
                chmod $bits "$backupdir/$path"
        else
                # remove
                mv "$backupdir/$path" "$backupdir/$path.$suffix"
        fi
done 
