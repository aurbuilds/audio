#!/bin/bash

set -ex

user=${1}
host=${2}
pass=${3}
path=${4}
arch=${5} # ${TRAVIS_TAG}

# Move repo files in the ${arch} directory and push it to the FTP server
mv known_hosts ${HOME}/.ssh/
cd pkg && mkdir ${arch}
mv *.db *.files *.tar.gz *.tar.xz ${arch} 2>/dev/null || true

sshpass -p ${pass} scp -r ${arch} ${user}@${host}:${path}
cd ..
