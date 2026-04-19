#!/bin/bash

if [ "$USER" != "root" ]
then
  echo Must run as root
  exit 1
fi

BUILD_VERSION=$1

if [ "$BUILD_VERSION" = "" ]
then
    BUILD_VERSION=$(curl -s -I https://cdn.amazonlinux.com/al2023/os-images/latest/ |grep -i location |cut -d '/' -f6)
fi

if [ "$BUILD_VERSION" = "" ]
then
  echo "Cannot automatically determine latest build version. Please provide it as an argument."
  exit 1
fi

echo Building for version $BUILD_VERSION

./build.sh x86_64 $BUILD_VERSION || exit 1
./build.sh arm64 $BUILD_VERSION || exit 1

echo To publish, run: ./publish.sh $BUILD_VERSION
