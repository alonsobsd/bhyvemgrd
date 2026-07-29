#!/bin/sh 

set -e

# Build parameters
# debug - compiling in debug mode
# release - compile in release mode

# Set fpc installation path
export fpc=/usr/local/bin/fpc

build_release()
{
  $fpc src/bhyvemgrd.lpr
}

build_debug()
{
  $fpc -O- src/bhyvemgrd.lpr
}


case $1 in
       debug)  build_debug;;
       release) build_release;;
           *)  exit 1;;
esac
