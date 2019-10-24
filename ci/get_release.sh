#!/usr/bin/env bash

set -eu

apt update &> /dev/null && apt install -y curl &> /dev/null

ADOPTOPENJDK_API='https://api.adoptopenjdk.net'

echo "Fetching latest Java ${JAVA_VERSION} JRE & JDK for Linux"
printf "\n\n"

jre_download_url="$ADOPTOPENJDK_API/v2/binary/releases/openjdk$JAVA_VERSION?openjdk_impl=hotspot&os=linux&arch=x64&release=latest&type=jre"
jdk_download_url="$ADOPTOPENJDK_API/v2/binary/releases/openjdk$JAVA_VERSION?openjdk_impl=hotspot&os=linux&arch=x64&release=latest&type=jdk"

echo "Fetching ${jre_download_url}"
(
  mkdir -p jre/ && cd jre/
  curl -JLO "${jre_download_url}"
)

printf "\n\n"

echo "Fetching ${jdk_download_url}"
(
  mkdir -p jdk/ && cd jdk/
  curl -JLO "${jdk_download_url}"
)

