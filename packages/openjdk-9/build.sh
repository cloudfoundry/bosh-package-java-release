#!/usr/bin/env bash

set -e -x -u -o pipefail

major_ver=9
minor_ver=0
update_ver=4
build_number=12

# http://hg.openjdk.java.net/jdk-updates/jdk9u/tags
tag=jdk-${major_ver}.${minor_ver}.${update_ver}+${build_number}

echo "----> Setting up dev env"
apt-get -y update
apt-get -y install openjdk-8-jdk mercurial build-essential zip \
  libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev \
  libcups2-dev libfreetype6-dev libasound2-dev libelf-dev

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

echo "----> Cloning OpenJDK 9 repo"
hg clone http://hg.openjdk.java.net/jdk-updates/jdk9u
pushd jdk9u
  chmod +x common/bin/hgforest.sh configure get_source.sh
  ./get_source.sh
  ./common/bin/hgforest.sh checkout $tag
popd

echo "----> Building OpenJDK 9"
pushd jdk9u
  ./configure \
    --disable-warnings-as-errors \
    --with-boot-jdk=/usr/lib/jvm/java-8-openjdk-amd64/ \
    --with-cacerts-file=$(pwd)/../cacerts.jks \
    --with-native-debug-symbols=none \
    --with-version-pre= \
    --with-version-opt= \
    --with-version-build=$build_number
  COMPANY_NAME="github.com/bosh-packages/java-release" make images
  chmod -R a+r build/linux-x86_64-normal-server-release/images
  tar czvf $(pwd)/../openjdk-jdk.tar.gz -C build/linux-x86_64-normal-server-release/images/jdk .
  tar czvf $(pwd)/../openjdk.tar.gz -C build/linux-x86_64-normal-server-release/images/jre . \
    -C ../jdk ./bin/jcmd ./bin/jmap ./bin/jstack \
    ./man/man1/jcmd.1 ./man/man1/jmap.1 ./man/man1/jstack.1 ./lib/libattach.so
popd

echo "----> Export"
mkdir output/
mv openjdk-jdk.tar.gz output/${tag}-jdk.tar.gz
mv openjdk.tar.gz     output/${tag}.tar.gz
shasum -a 256 output/*.tar.gz > output/shasums
cat output/shasums
