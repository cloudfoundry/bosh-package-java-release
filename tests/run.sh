#!/bin/bash

set -e # -x

echo "-----> `date`: Upload stemcell"
bosh -n upload-stemcell 'https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent?v=315.36' \
  --sha1 b33bc047562aab2d9860420228aadbd88c5fccfb

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
