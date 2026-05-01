#!/bin/bash

DISTRO_VERSION=$1

if [ "$DISTRO_VERSION" = "" ]
then
    DISTRO_VERSION=$(curl -s -I https://cdn.amazonlinux.com/al2023/os-images/latest/ |grep -i location |cut -d '/' -f6)
fi

if [ "$DISTRO_VERSION" = "" ]
then
    echo '"Distro"' version is required
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

BINARY_ARM_HASH=$(sha256sum -b AL2023-arm64.wsl |sed -e 's/\s\+.*//')
BINARY_X86_HASH=$(sha256sum -b AL2023-x86_64.wsl |sed -e 's/\s\+.*//')

echo Creating DistributionInfo.json with version $DISTRO_VERSION
echo arm64 hash: $BINARY_ARM_HASH
echo x86_64 hash: $BINARY_X86_HASH

cat << EOM > DistributionInfo.json
{
    "ModernDistributions": {
        "AmazonLinux": [
            {
                "Name": "AL2023",
                "FriendlyName": "AmazonLinux 2023",
                "Default": true,
                "Amd64Url": {
                    "Url": "https://github.com/clarson/amazon-linux-wsl/releases/download/AL$DISTRO_VERSION/AL2023-x86_64.wsl",
                    "Sha256": "$BINARY_ARM_HASH"
                },
                "Arm64Url": {
                    "Url": "https://github.com/clarson/amazon-linux-wsl/releases/download/AL$DISTRO_VERSION/AL2023-arm64.wsl",
                    "Sha256": "$BINARY_X86_HASH"
                }
            }
        ]
    }
}
EOM
