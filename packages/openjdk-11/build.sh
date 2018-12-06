#!/usr/bin/env bash

set -e -x -u -o pipefail

major_ver=11
minor_ver=0
update_ver=1
build_number=13

# http://hg.openjdk.java.net/jdk-updates/jdk11u/tags
tag=jdk-${major_ver}.${minor_ver}.${update_ver}+${build_number}

echo "----> Setting up dev env"
apt-get -y update
apt-get -y install openjdk-8-jdk mercurial build-essential zip autoconf curl \
  libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev \
  libcups2-dev libfreetype6-dev libasound2-dev libelf-dev libfontconfig1-dev \

echo "----> Creating CA certs bundle"
mkdir cacerts/
awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{ print $0; }' \
  /etc/ssl/certs/ca-certificates.crt | \
  csplit -n 3 -s -f cacerts/ - '/-----BEGIN CERTIFICATE-----/' {*}
rm cacerts/000
for I in $(find cacerts -type f | sort) ; do
  keytool -importcert -noprompt -keystore cacerts.jks \
    -storepass changeit -file $I -alias $(basename $I)
done

echo "----> Downloading OpenJDK 10"
openjdk_10_url="https://download.java.net/java/GA/jdk10/10.0.2/19aef61b38124481863b1413dce1855f/13/openjdk-10.0.2_linux-x64_bin.tar.gz"
curl "$openjdk_10_url" | tar -xz -C /usr/lib/jvm

echo "----> Cloning OpenJDK 11 repo"
hg clone http://hg.openjdk.java.net/jdk-updates/jdk11u

echo "----> Building OpenJDK 11"
pushd jdk11u
  chmod +x configure
  ./configure \
    --disable-warnings-as-errors \
    --with-boot-jdk=/usr/lib/jvm/jdk-10.0.2/ \
    --with-cacerts-file=$(pwd)/../cacerts.jks \
    --with-native-debug-symbols=none \
    --with-version-pre= \
    --with-version-opt= \
    --with-version-build=$build_number
  COMPANY_NAME="github.com/bosh-packages/java-release" make images
  chmod -R a+r build/linux-x86_64-normal-server-release/images
  tar czvf $(pwd)/../openjdk.tar.gz -C build/linux-x86_64-normal-server-release/images/jdk .
popd

echo "----> Export"
mkdir output/
mv openjdk.tar.gz output/${tag}.tar.gz
shasum -a 256 output/*.tar.gz > output/shasums
cat output/shasums
