#!/bin/sh
#
# Remove RHTS dependencies from beakerlib test
# Do not remove them hard way, just make it possible running test without them installed

find -name Makefile -exec sed -e 's|include \(/usr/share/rhts/lib/rhts-make.include\)|include $(realpath \1)|' -e 's|rhts-lint $(METADATA)|[ -x /usr/bin/rhts-lint ] \&\& &|' -i '{}' ';'
find -name runtest.sh -exec sed -e 's,\. /usr/bin/rhts-environment.sh || exit 1,if [ -r /usr/bin/rhts-environment.sh ]; then &; fi,' -i '{}' ';'
find -name runtest.sh -exec sed -e 's|\. /usr/lib/beakerlib/beakerlib.sh|for LIB in /usr/{lib,share}/beakerlib/beakerlib.sh; do [ -r "$LIB" ] \&\& . $LIB \&\& break; done|' -i '{}' ';'
