#!/bin/bash

# time fly -t production execute -p -i java-release=.. -o java-release-out=/tmp/java-release -c ./build.yml 

fly -t production set-pipeline -p java-release -c pipeline.yml \
	-l <(lpass show --note "bosh-packages-concourse-vars-java-release")
