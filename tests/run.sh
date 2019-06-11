#!/bin/bash

set -e # -x

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
build_dir="${script_dir}/../.."
stemcell="${build_dir}/stemcell/stemcell.tgz"

echo "-----> $(date): Uploading stemcell"
bosh -n upload-stemcell "${stemcell}"

echo "-----> `date`: Delete previous deployment"
bosh -n -d test delete-deployment --force
rm -f creds.yml

echo "-----> `date`: Deploy"
( set -e; cd ..; bosh -n -d test deploy ./manifests/test.yml )

echo "-----> `date`: Run test errand"
bosh -n -d test run-errand openjdk-test
#bosh -n -d test run-errand openjdk-jdk-test

echo "-----> `date`: Delete deployments"
bosh -n -d test delete-deployment

echo "-----> `date`: Done"
