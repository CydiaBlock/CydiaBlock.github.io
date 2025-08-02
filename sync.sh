#!/bin/bash
dpkg-scanpackages -m . /dev/null >Packages
rm -rf Packages.bz2
bzip2 -fks Packages

rm -rf ./package_debian_*
