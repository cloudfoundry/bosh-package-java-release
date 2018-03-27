#!/bin/bash

set -e -x -u -o pipefail

if which apt-get; then
	echo "Install uuidgen"
	apt-get -y update
	apt-get -y install uuid-runtime
fi

function build_jdk() {
  rm -rf output/ && mkdir output/
  touch build.log
  tail -f build.log &

  echo "Build assets"
  # todo using build+run, since there is no way to copy back to the host
  uuid=openjdk-$(uuidgen|tr '[:upper:]' '[:lower:]')
  docker build --no-cache -t $uuid . >build.log 2>&1
  docker run --entrypoint= $uuid tar -cf - output/ | tar xvf - -C output/

  echo "Check exported assets"
  cd output
  cat output/shasums | shasum -c -
  rm output/shasums
  cd ..

  echo "Add as blobs"
  ls output/output/ | xargs -n1 -I{} bosh add-blob --sha2 --dir ../.. output/output/{} {}
  rm -rf output
}

echo "----> Docker"
docker -v

echo "----> OpenJDK 8"
pushd packages/openjdk-8/
  build_jdk
popd

echo "----> OpenJDK 9"
pushd packages/openjdk-9/
  build_jdk
popd
