#!/bin/bash

trap 'exit 130' INT


export REPO_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


export targetVersion="16.04"
export CUDA_VER="9.1"
export UBUNTU_VER="ubuntu16.04"

isLinux=$(uname -a | grep -E 'Linux' | wc | awk '{print $1}')
ubuntuVersion=$(lsb_release -r | awk '{print $2}')

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   sudo $REPO_HOME/install.sh
   exit 1
fi

if [ "$ubuntuVersion" != "$targetVersion"  -o  "$isLinux" != "1"  ]; then
	   echo "This script must be run on Ubuntu 16.04" 1>&2
   	   ##exit 1
fi

## Clean up.
rm ~/.cudaconf

## Slurp helpers
## Clean up Dockerfiles
function fixfile () {
        sed -i '/^LABEL/d' $1 #remove unparsable lines
        sed -i '/^MAINTAINER/d' $1 #remove unparsable lines
        sed -i '/^FROM/d' $1 #remove unparsable lines
        sed -i '/</d' $1 #remove unparsable lines
        sed -i "/apt-get remove/d" $1 ## prevent removing of pkgs
        sed -i "s/RUN //g" $1
        chmod +x $1 #make it hot
}

## Map functions Dockerfile will use to install
function ENV () {
	export $1="$2" ## Export into running shell
	echo "export $1=$2" >> ~/.cudaconf ## append to conf for later
}

## SYSTEM STUFF
function sudo () {
	$@ ## this script assumes root, just wrap
}

## NO OPS for system commands
function rm () {
	:
}

function ARG () {
        :
}

## Make a home for our downloaded Dockerfiles
BUILDDIR=/tmp/Dockerfiles
mkdir -p $BUILDDIR
## Make a home for our downloaded tar files
DOWNLOADS=/tmp/Downloads
mkdir -p $DOWNLOADS

cd $DOWNLOADS

apt-get update
apt-get install -y vim curl git

base="$BUILDDIR/base.sh"
curl -o $base -fsSL https://gitlab.com/nvidia/cuda/raw/$UBUNTU_VER/$CUDA_VER/base/Dockerfile
fixfile $base

runtime="$BUILDDIR/runtime.sh"
curl -o $runtime -fsSL https://gitlab.com/nvidia/cuda/raw/$UBUNTU_VER/$CUDA_VER/runtime/Dockerfile
fixfile $runtime

devel="$BUILDDIR/devel.sh"
curl -o $devel -fsSL https://gitlab.com/nvidia/cuda/raw/$UBUNTU_VER/$CUDA_VER/devel/Dockerfile
fixfile $devel

cudnn="$BUILDDIR/cudnn.sh"
curl -o $cudnn -fsSL https://gitlab.com/nvidia/cuda/raw/$UBUNTU_VER/$CUDA_VER/devel/cudnn7/Dockerfile
sed -i '/</d' $cudnn
fixfile $cudnn

. $base
. $runtime
. $devel
. $cudnn

cd
##Clean up
rm -rf $DOWNLOADS
## We'll need this later
unset -f rm


git clone https://github.com/torch/distro torch
cd ~/torch
## Knockout patch to use older GCC
sed -i 's/Found GCC 5, installing GCC 4.9/Leaving stock GCC in place.../g' install-deps
sed -i '/sudo apt-get install -y gcc-4.9 libgfortran-4.9-dev g++-4.9/d' install-deps
. install-deps ##Torch will install everything we need, fire inside this environment

## pickup cuda stuff
echo "source ~/.cudaconf" >> ~/.bashrc
source ~/.bashrc
cd ~/torch
## Install torch!
./install.sh
