#!/bin/bash

set -ex

if [[ ! -d "config" ]]; then exit 0; fi

docker exec aurdeploy bash setup.sh ${TRAVIS_REPO_SLUG} ${TRAVIS_TAG} ${TRAVIS_BUILD_ID} ${DEPLOY_GITHUB}
