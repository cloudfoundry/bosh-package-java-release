#!/bin/bash

set -eux

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

bosh upload-blobs

git add -A
git status
git commit -m "Adding blobs via concourse"

bosh create-release --final

git add -A
git status
git commit -m "Final release via concourse"
