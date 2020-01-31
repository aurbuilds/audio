#!/bin/bash

set -ex

# ------------------------------------------------------------------------------
# Environment Variables setup
# ------------------------------------------------------------------------------
TRAVIS_REPO_SLUG=${1}
TRAVIS_REPO=${1#*/}
TRAVIS_BUILD_ID=${3}
DEPLOY_GITHUB=${4}
ARCH=${2} # ${TRAVIS_TAG}

# Use GH releases by default if not specified
if [[ ${DEPLOY_GITHUB} == "" ]]; then DEPLOY_GITHUB=1; fi

# Remove comments or blank lines.
for filename in "aur.list" "pacman.list" "gpgkeys.list"; do
  sed -i -e "/\s*#.*/s/\s*#.*//" -e "/^\s*$/d" $filename
done

if [[ -f aur.list ]];     then aurpkgs=`cat aur.list`; fi
if [[ -f pacman.list ]];  then pacpkgs=`cat pacman.list`; fi
if [[ -f gpgkeys.list ]]; then gpgkeys=`cat gpgkeys.list`; fi

# Set the PACKAGER information if no makepkg.conf was provided
makepkg_conf="${HOME}/.makepkg.conf"
if [ ! -f "${makepkg_conf}" ] || ! grep -q "PACKAGER" "${makepkg_conf}"; then
  echo "No makepkg.conf or no PACKAGER variable found: exporting it..."
  export PACKAGER="${TRAVIS_REPO_SLUG/\// } <${TRAVIS_BUILD_ID}@travis.build.id>"
fi
# ------------------------------------------------------------------------------
# Pacman setup
# ------------------------------------------------------------------------------

# Enable `multilib` repository
sudo sed -i -e "/\[multilib\]/,/Include/s/^#//" "/etc/pacman.conf"

# Append custom repository from user's pacman.conf if any
if [[ -f pacman.conf ]]; then
  cat pacman.conf | sudo tee -a /etc/pacman.conf >/dev/null
fi
# System update
sudo pacman -Syu --noconfirm

# ------------------------------------------------------------------------------
# Packages setup
# ------------------------------------------------------------------------------

# Get missing GPG keys if any specified
for gpgkey in ${gpgkeys[@]}; do
  gpg --recv-keys --keyserver hkp://ipv4.pool.sks-keyservers.net:11371 ${gpgkey}
done

# Install required packages if any specified
if (( ${#pacpkgs[@]} )); then
  sudo pacman -S --noconfirm ${pacpkgs[@]}
fi

# Build packages from source files or, if no AUR package list, exit successfully
if (( ! ${#aurpkgs[@]} )); then exit 0; fi

cd src

for aurpkg in ${aurpkgs[@]}; do
  git clone https://aur.archlinux.org/${aurpkg}
  cd ${aurpkg}
  echo && echo -n "-- building in `pwd`"
  makepkg -si --needed --asdeps --noprogressbar --noconfirm
  mv *.pkg.tar.xz ${HOME}/pkg/
  cd ..
  rm -rf ${aurpkg}
done

cd ../pkg

# Download or create the repository database
if curl -fOOL https://github.com/${TRAVIS_REPO_SLUG}/releases/download/${ARCH}/${TRAVIS_REPO}.{db,files}.tar.gz; then
  ln -fs "${TRAVIS_REPO}.db.tar.gz" "${TRAVIS_REPO}.db"
  ln -fs "${TRAVIS_REPO}.files.tar.gz" "${TRAVIS_REPO}.files"
else
  rm -f "${TRAVIS_REPO}.db.tar.gz" "${TRAVIS_REPO}.files.tar.gz"
  repo-add "${TRAVIS_REPO}.db.tar.gz"
fi

# Add packages to the database
for package in *.tar.xz; do
  # Workaround fo GH releases because colon in names are not permitted
  if [[ ${DEPLOY_GITHUB} != 0 && ${package} == *':'* ]]; then
    echo "renaming ${package} and add it back to db..."
    oldname=${package}
    package=${package/:/.}
    mv -- ${oldname} ${package}
  fi
  repo-add "${TRAVIS_REPO}.db.tar.gz" ${package}
done

cd ..
