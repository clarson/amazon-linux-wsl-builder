#!/bin/bash

if [ "$1" = "clean" ]
then
  echo Cleaning
  for file in AL2023-arm64.wsl AL2023-x86_64.wsl DistributionInfo.json
  do
      [ ! -f $file ] || rm $file
  done
  exit
fi

if [ "$1" = "" ]
then
  echo arch required. Can be x86_64 or arm64
  exit 1
fi

if [ "$1" != "x86_64" ] && [ "$1" != "arm64" ]
then
  echo Invalid arch. Can be x86_64 or arm64
  exit 1
fi

BUILD_ARCH="$1"
BUILD_VERSION="$2"

if [ "$USER" != "root" ]
then
  echo Must run as root
  exit 1
fi

if [ ! -f terminal-profile.json ] || [ ! -f wsl.conf ] || [ ! -f wsl-distribution.conf ] || [ ! -f ec2icon.svg ]
then
  echo Working directory does not contain all files to include in distro
  exit 1
fi

if [ "$BUILD_VERSION" = "" ]
then
  BUILD_VERSION=$(curl -s -I https://cdn.amazonlinux.com/al2023/os-images/latest/ |grep -i location |cut -d '/' -f6)
fi

if [ "$BUILD_VERSION" = "" ]
then
  echo "Cannot automatically determine latest build version. Please provide it as an argument."
  exit 1
fi

BUILD_DISTRO=AL2023
CONTAINER="container"

if [ "$BUILD_ARCH" = "arm64" ]
then
  CONTAINER="container-arm64"
fi

BUILD_URL="https://cdn.amazonlinux.com/al2023/os-images/$BUILD_VERSION/$CONTAINER/al2023-container-$BUILD_VERSION-$BUILD_ARCH.tar.xz"
XZFILE=$(echo $BUILD_URL |sed -e 's:.*/::')

if [ "$XZFILE" = "" ]
then
  echo Cannot determine XZFILE from $BUILD_URL
  exit 1
fi

if ! type -P convert >/dev/null
then
  echo Cannot find convert. Please install ImageMagick
  exit 1
fi

LASTDIR="$PWD"

[ ! -f "$BUILD_DISTRO-$BUILD_ARCH.wsl" ] || rm $BUILD_DISTRO-$BUILD_ARCH.wsl

TEMP_DIR=$(mktemp -d -t $(basename $0).XXXXXX)

trap 'rm -rf "$TEMP_DIR"' EXIT

echo
echo -------- Building $BUILD_DISTRO-$BUILD_ARCH.wsl "($BUILD_VERSION)" --------
echo
echo BUILD_ARCH: $BUILD_ARCH
echo BUILD_DISTRO: $BUILD_DISTRO
echo BUILD_VERSION: $BUILD_VERSION
echo TEMP_DIR: $TEMP_DIR
echo XZFILE: $XZFILE
echo BUILD_URL: $BUILD_URL
echo

cd $TEMP_DIR || exit 1

echo Downloading $XZFILE
wget -q "$BUILD_URL"

if [ ! -f $XZFILE ]
then
    echo $XZFILE not found
    echo ------
    ls
    exit 1
fi

mkdir rootfs || exit 1
cd rootfs || exit 1
mkdir -p usr/lib/wsl || exit 1

echo Extracting $XZFILE

tar -xf ../$XZFILE || exit 1

echo Adding adm group to sudoers

mkdir -p etc/sudoers.d/ || exit 1

echo '%adm	ALL=(ALL)	NOPASSWD: ALL' > etc/sudoers.d/adm
chmod 400 etc/sudoers.d/adm || exit 1

echo Adding etc/wsl-distribution.conf

sed -e "s/{BUILD_DISTRO}/$BUILD_DISTRO/g" \
  $LASTDIR/wsl-distribution.conf > etc/wsl-distribution.conf || exit 1

echo Adding etc/terminal-profile.json

cp $LASTDIR/terminal-profile.json usr/lib/wsl/terminal-profile.json || exit 1

echo Adding etc/oobe.sh

cp $LASTDIR/oobe.sh etc/oobe.sh || exit 1

chmod a+x etc/oobe.sh || exit 1

echo Adding etc/wsl.conf

cp $LASTDIR/wsl.conf etc/wsl.conf || exit 1

echo Creating usr/lib/wsl/ec2.ico

convert -density 256x256 -background transparent \
  -define icon:auto-resize=256,128,96,64,48,32,16 $LASTDIR/ec2icon.svg usr/lib/wsl/ec2.ico

echo Creating root/.bash_profile
echo 'bash /etc/oobe.sh || exit 1' > root/.bash_profile
chmod u+x root/.bash_profile

echo Creating $BUILD_DISTRO-$BUILD_ARCH.wsl

tar --numeric-owner --absolute-names -c * | \
  gzip --best > $LASTDIR/$BUILD_DISTRO-$BUILD_ARCH.wsl || exit 1

cd $LASTDIR || exit 1

echo
echo Created $BUILD_DISTRO-$BUILD_ARCH.wsl "($BUILD_VERSION)"
