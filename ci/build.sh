#!/bin/bash

set -eu -o pipefail

ROOT="$PWD"


function populate_private_yml() {
  pushd "${ROOT}/java-release" &> /dev/null
  cat >> config/private.yml <<EOF
---
blobstore:
  provider: s3
  options:
    access_key_id: "$BLOBSTORE_ACCESS_KEY_ID"
    secret_access_key: "$BLOBSTORE_SECRET_ACCESS_KEY"
EOF
  popd &> /dev/null
}

function compare_blob_sha_with_new_file () {
  local blob_file_name="$1"
  local input_file_name="$2"

  pushd "${ROOT}/java-release" &> /dev/null
    local blob_sha="$(bosh blobs --json | jq -r ".Tables[].Rows[] | select(.path == \"${blob_file_name}\") | .digest" | cut -d: -f2)"
  popd &> /dev/null

  if [[ "${blob_sha}" == "" ]]; then
    return 1
  fi

  shasum -c <(echo "${blob_sha}  ${input_file_name}")
}

function get_major_version() {
  local version="$1"
  echo "$version" | sed -n 's/\([0-9]*\).*/\1/p'
}

jdk_file="$(ls jdk/*.tar.gz)"
jdk_version="$(ls jdk/*.tar.gz | sed -n 's/.*hotspot_\(.*\).tar.gz$/\1/p')"
major_version="$(get_major_version "$jdk_version")"

echo "version: $jdk_version"

echo "Adding openjdk to bosh blobs"
jdk_blob_filename="jdk-${jdk_version}.tar.gz"

if compare_blob_sha_with_new_file ${jdk_blob_filename} ${ROOT}/${jdk_file}; then
  echo "The blob to be added is identical with the existing one: ${jdk_blob_filename}"
  git clone java-release java-release-out
  exit 0
fi

bosh add-blob --sha2 --dir java-release jdk/*.tar.gz "$jdk_blob_filename"

echo "Create release folder structure"
cd java-release

mkdir -p "src/openjdk-$major_version"

cat > "src/openjdk-$major_version/compile.env" <<EOF
export JAVA_HOME=/var/vcap/packages/openjdk-${major_version}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

if [ -d /var/vcap/packages/openjdk-${major_version}/jre ]; then
  cat > "src/openjdk-$major_version/runtime.env" <<EOF
export JAVA_HOME=/var/vcap/packages/openjdk-${major_version}/jre
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

else
  cat > "src/openjdk-$major_version/runtime.env" <<EOF
export JAVA_HOME=/var/vcap/packages/openjdk-${major_version}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

fi

mkdir -p "packages/openjdk-$major_version"

cat > "packages/openjdk-$major_version/spec" <<EOF
---
name: openjdk-${major_version}
dependencies: []
files:
- openjdk-${major_version}/compile.env
- openjdk-${major_version}/runtime.env
- ${jdk_blob_filename}
EOF

cat > "packages/openjdk-$major_version/packaging" <<EOF
set -ex
mkdir \${BOSH_INSTALL_TARGET}/bosh
cp openjdk-${major_version}/runtime.env \${BOSH_INSTALL_TARGET}/bosh/runtime.env
cp openjdk-${major_version}/compile.env \${BOSH_INSTALL_TARGET}/bosh/compile.env

cd \${BOSH_INSTALL_TARGET}
tar zxvf \${BOSH_COMPILE_TARGET}/*.tar.gz --strip 1
EOF

mkdir -p "jobs/openjdk-$major_version-test/templates"
touch "jobs/openjdk-$major_version-test/monit"
cat > "jobs/openjdk-$major_version-test/spec" <<EOF
---
name: openjdk-${major_version}-test
templates:
  run: bin/run
packages:
- openjdk-${major_version}
properties: {}
EOF

cat > "jobs/openjdk-$major_version-test/templates/run" <<EOF
#!/bin/bash
set -ex
(
  source /var/vcap/packages/openjdk-${major_version}/bosh/compile.env
  javac -version
)

(
  source /var/vcap/packages/openjdk-${major_version}/bosh/runtime.env
  java -version
)
EOF

mkdir -p manifests
cat > manifests/test.yml <<EOF
{"name":"test",
"releases":[{"name":"java","version":"create","url":"file://."}],
"stemcells":[{"alias":"default","os":"ubuntu-xenial","version":"latest"}],
"update":{"canaries":2,"max_in_flight":1,"canary_watch_time":"5000-60000","update_watch_time":"5000-60000"},
"instance_groups":[
{"name":"openjdk-test",
"azs":["z1"],
"instances":1,
"lifecycle":"errand",
"jobs":[{"name":"openjdk-${major_version}-test","release":"java","properties":{}}],
"vm_type":"default",
"stemcell":"default",
"networks":[{"name":"default"}]}]}
EOF

echo "Starting Director"
source start-bosh
source /tmp/local-bosh/director/env

echo "Run tests"
pushd tests &> /dev/null
	./run.sh
popd &> /dev/null

echo "Issue new release"
populate_private_yml
./ci/finalize.sh

echo "Concourse output"
cd "$ROOT"

git clone java-release java-release-out
