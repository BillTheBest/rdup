#!/bin/sh

# Build a hdup2 distribution tar from the SVN repository.
# Adapted from NSD to hdup2 by Miek Gieben

# Abort script on unexpected errors.
set -e

# Remember the current working directory.
cwd=`pwd`

# Utility functions.
usage () {
    cat >&2 <<EOF
Usage $0: [-h] [-s] [-d SVN_root]
Generate a distribution tar file for hdup2.

    -h           This usage information.
    -s           Build a snapshot distribution file.  The current date is
                 automatically appended to the current hdup version number.
    -d SVN_root  Retrieve the hdup source from the specified repository.
EOF
    exit 1
}

info () {
    echo "$0: info: $1"
}

error () {
    echo "$0: error: $1" >&2
    exit 1
}

question () {
    printf "%s (y/n) " "$*"
    read answer
    case "$answer" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Only use cleanup and error_cleanup after generating the temporary
# working directory.
cleanup () {
    info "Deleting temporary working directory."
    cd $cwd && rm -rf $temp_dir
}

error_cleanup () {
    echo "$0: error: $1" >&2
    cleanup
    exit 1
}

replace_text () {
    (cp "$1" "$1".orig && \
        sed -e "s/$2/$3/g" < "$1".orig > "$1" && \
        rm "$1".orig) || error_cleanup "Replacement for $1 failed."
}

replace_all () {
    info "Updating '$1' with the version number."
    replace_text "$1" "@version@" "$version"
    info "Updating '$1' with today's date."
    replace_text "$1" "@date@" "`date +'%b %e, %Y'`"
}
    

SNAPSHOT="no"

# Parse the command line arguments.
while [ "$1" ]; do
    case "$1" in
        "-h")
            usage
            ;;
        "-d")
            SVNROOT="$2"
            shift
            ;;
        "-s")
            SNAPSHOT="yes"
            ;;
        *)
            error "Unrecognized argument -- $1"
            ;;
    esac
    shift
done

# Check if SVNROOT is specified.
if [ -z "$SVNROOT" ]; then
    error "SVNROOT must be specified (using -d)"
fi

# Start the packaging process.
info "SVNROOT  is $SVNROOT"
info "SNAPSHOT is $SNAPSHOT"

#question "Do you wish to continue with these settings?" || error "User abort."


# Creating temp directory
info "Creating temporary working directory"
temp_dir=`mktemp -d hdup-dist-XXXXXX`
info "Directory '$temp_dir' created."
cd $temp_dir

info "Exporting source from SVN."
svn export "$SVNROOT" hdup2 || error_cleanup "SVN command failed"

cd hdup2 || error_cleanup "hdup2 not exported correctly from SVN"

info "Building configure script (autoconf)."
autoconf || error_cleanup "Autoconf failed."

rm -r autom4te* || error_cleanup "Failed to remove autoconf cache directory."

find . -name .c-mode-rc.el -exec rm {} \;
find . -name .cvsignore -exec rm {} \;
rm makedist.sh || error_cleanup "Failed to remove makedist.sh."

info "Determining hdup2 version."
version=`./configure --version | head -1 | awk '{ print $3 }'` || \
    error_cleanup "Cannot determine version number."

info "hdup2 version: $version"

if [ "$SNAPSHOT" = "yes" ]; then
    info "Building hdup2 snapshot."
    version="$version-`date +%Y%m%d`"
    info "Snapshot version number: $version"
fi

info "Renaming hdup directory to hdup-$version."
cd ..
mv hdup2 hdup-$version || error_cleanup "Failed to rename hdup directory."

tarfile="../hdup-$version.tar.gz"

if [ -f $tarfile ]; then
    (question "The file $tarfile already exists.  Overwrite?" \
        && rm -f $tarfile) || error_cleanup "User abort."
fi

info "Deleting the tpkg and test directory"
rm -rf hdup-$version/tpkg/
rm -rf hdup-$version/test/

info "Deleting the other fluff"
rm -rf hdup-$version/.svn
rm -f hdup-$version/core
rm -f hdup-$version/tar-exclude
rm -f hdup-$version/config.log 
rm -f hdup-$version/config.status
rm -f hdup-$version/tags hdup-$version/src/tags

info "Creating tar hdup-$version.tar.bz2"
tar cjf ../hdup-$version.tar.bz2 hdup-$version || error_cleanup "Failed to create tar file."

cleanup

case $OSTYPE in
        linux*)
                sha=`sha1sum hdup-$version.tar.bz2 |  awk '{ print $1 }'`
                ;;
        freebsd*)
                sha=`sha1  hdup-$version.tar.bz2 |  awk '{ print $5 }'`
                ;;
esac
echo $sha > hdup-$version.tar.bz2.sha1

info "hdup2 distribution created successfully."
info "SHA1sum: $sha"
