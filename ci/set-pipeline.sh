#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -eu

CONCOURSE_URL='https://concourse.cf-denver.com/'
TARGET_NAME='production'
TEAM_NAME='healthwatch'

function authorized() {
  fly --target "$TARGET_NAME" status &> /dev/null
}

function login() {
  fly --target "$TARGET_NAME" login \
      --open-browser \
      --concourse-url "$CONCOURSE_URL" \
      --team-name "$TEAM_NAME"
}

lpass sync
authorized || login

fly --target production set-pipeline \
    --pipeline java-release \
    --config "$DIR"/pipeline.yml \
	  --load-vars-from <(lpass show --note "bosh-packages-concourse-vars-java-release")
