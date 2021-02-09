#!/usr/bin/env bash

set -eu

apt update &> /dev/null && apt install -y curl &> /dev/null

ADOPTOPENJDK_API='https://api.adoptopenjdk.net'

echo "Fetching latest Java ${JAVA_VERSION} JDK for Linux"
printf "\n\n"

jdk_download_url="$ADOPTOPENJDK_API/v3/binary/latest/$JAVA_VERSION/ga/linux/x64/jdk/hotspot/normal/adoptopenjdk?project=jdk"

echo "Fetching ${jdk_download_url}"
(
  mkdir -p jdk/ && cd jdk/
  curl -JLO "${jdk_download_url}"
)

