#!/bin/sh
#
# Remove RHTS dependencies from beakerlib test

find -name Makefile -exec sed -e 's|include /usr/share/rhts/lib/rhts-make.include||' -e 's|rhts-lint $(METADATA)||'  -e 'T' -e 'd' -i '{}' ';'
find -name runtest.sh -exec sed -e 's|. /usr/bin/rhts-environment.sh||' -e 'T' -e 'd' -i '{}' ';'
find -name runtest.sh -exec sed -e 's|. /usr/lib/beakerlib/beakerlib.sh|. /usr/share/beakerlib/beakerlib.sh|' -e 'T' -e 'd' -i '{}' ';'
