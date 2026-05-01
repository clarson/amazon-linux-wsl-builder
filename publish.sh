#!/bin/bash

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

if ! gh auth status >/dev/null 2>&1
then
  echo You must be authenticated with the GitHub CLI to publish. Please run 'gh auth login' and try again.
  exit 1
fi

if gh release view AL$BUILD_VERSION --repo clarson/amazon-linux-wsl>/dev/null 2>&1
then
  echo "Release AL$BUILD_VERSION already exists"
  exit 1
fi

if [ ! -f "AL2023-arm64.wsl" ]
then
    echo AL2023-arm64.wsl not found
    exit 1
fi

if [ ! -f "AL2023-x86_64.wsl" ]
then
    echo AL2023-x86_64.wsl not found
    exit 1
fi

./distribution_info.sh $BUILD_VERSION || exit 1

if [ ! -f "DistributionInfo.json" ]
then
    echo DistributionInfo.json not found
    exit 1
fi

cat << EOC > /tmp/wsl_publish.sh
gh release create AL$BUILD_VERSION \
    ./AL2023-x86_64.wsl ./AL2023-arm64.wsl ./DistributionInfo.json \
    --repo clarson/amazon-linux-wsl \
    --title 'AL$BUILD_VERSION' \
    --notes 'Release of Amazon Linux WSL distribution for version $BUILD_VERSION' \
    --target main
EOC

trap "rm -f /tmp/wsl_publish.sh" EXIT SIGINT SIGTERM

if [ "$SUDO_USER" != "" ]
then
  su $SUDO_USER -c 'bash /tmp/wsl_publish.sh'
else
  bash /tmp/wsl_publish.sh
fi

rm /tmp/wsl_publish.sh
