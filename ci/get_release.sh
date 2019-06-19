#!/usr/bin/env bash

ADOPTOPENJDK_API='https://api.adoptopenjdk.net'

releases="$(curl -Ss "${ADOPTOPENJDK_API}/v2/info/releases/openjdk${JAVA_VERSION}")"

latest_release="$(echo ${releases} | jq -r '.[] | .release_name' | grep -v 'openj9' | sort -rV | head -n1)"

echo "Latest release of Java ${JAVA_VERSION} is ${latest_release}\n"

jre_download_url="$(echo ${releases} | jq -r ".[] | select(.release_name == \"${latest_release}\") | .binaries[]| select(.os == \"linux\" and .architecture == \"x64\" and .binary_type == \"jre\") | .binary_link")"
jdk_download_url="$(echo ${releases} | jq -r ".[] | select(.release_name == \"${latest_release}\") | .binaries[]| select(.os == \"linux\" and .architecture == \"x64\" and .binary_type == \"jdk\") | .binary_link")"

echo "Fetching $(basename ${jre_download_url})"
wget --quiet "${jre_download_url}" -P jre/

echo "Fetching $(basename ${jdk_download_url})"
wget --quiet "${jdk_download_url}" -P jdk/
