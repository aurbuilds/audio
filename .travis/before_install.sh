#!/bin/bash

set -ex

if [[ -d "config" ]]; then
  docker build -t ${TRAVIS_REPO_SLUG} .
  docker run --name aurdeploy -dt ${TRAVIS_REPO_SLUG} bash
fi
