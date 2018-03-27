#!/bin/bash

set -e # -x

echo "-----> `date`: Upload stemcell"
bosh -n upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=3541.9" \
  --sha1 44138ff5e30cc1d7724d88eaa70fab955b8011bd \
  --name bosh-warden-boshlite-ubuntu-trusty-go_agent \
  --version 3541.9

echo "-----> `date`: Delete previous deployment"
bosh -n -d test delete-deployment --force
rm -f creds.yml

echo "-----> `date`: Deploy"
( set -e; cd ./..; bosh -n -d test deploy ./manifests/test.yml )

echo "-----> `date`: Run test errand"
bosh -n -d test run-errand openjdk-8-test
bosh -n -d test run-errand openjdk-9-test

echo "-----> `date`: Delete deployments"
bosh -n -d test delete-deployment

echo "-----> `date`: Done"
