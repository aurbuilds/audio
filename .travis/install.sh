#!/bin/bash

set -ex

# All configuration files are optional.
# Don't run docker in master branch
# where the `config` directory was removed by purpose.

if [[ ! -d "config" ]]; then exit 0; fi

if [[ -f "config/makepkg.conf" ]]; then
  docker cp "config/makepkg.conf" "${DEPLOY_HOME}/.makepkg.conf"
fi
if [[ -f "config/pacman.conf" ]]; then
  docker cp "config/pacman.conf" ${DEPLOY_HOME}
fi
if [[ -f "config/aur.list" ]]; then
  docker cp "config/aur.list" ${DEPLOY_HOME}
fi
if [[ -f "config/pacman.list" ]]; then
  docker cp "config/pacman.list" ${DEPLOY_HOME}
fi
if [[ -f "config/gpgkeys.list" ]]; then
  docker cp "config/gpgkeys.list" ${DEPLOY_HOME}
fi
docker cp "setup.sh"    ${DEPLOY_HOME}
docker cp "providers/." ${DEPLOY_HOME}
