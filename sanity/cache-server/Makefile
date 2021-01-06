# Makefile - /CoreOS/bind/sanity/cache-server
# Author: Petr Sklenar <psklenar@redhat.com>
# Location: /CoreOS/bind/sanity/cache-server

# Copyright (c) 2008 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 


TOPLEVEL_NAMESPACE=/CoreOS
PACKAGE_NAME=bind
RELATIVE_PATH=sanity/cache-server

export TEST=$(TOPLEVEL_NAMESPACE)/$(PACKAGE_NAME)/$(RELATIVE_PATH)
export TESTVERSION=2.0

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE

.PHONY: all install download clean

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	chmod a+x ./runtest.sh

clean:
	rm -f *~ $(BUILT_FILES)


include /usr/share/rhts/lib/rhts-make.include


$(METADATA): Makefile
	@touch $(METADATA)
	@echo "Owner:        Martin Cermak <mcermak@redhat.com>" > $(METADATA)
	@echo "Name:         $(TEST)" >> $(METADATA)
	@echo "Path:         $(TEST_DIR)"       >> $(METADATA)
	@echo "TestVersion:  $(TESTVERSION)"    >> $(METADATA)
	@echo "Description:  Creating and using cache server for a while" >> $(METADATA)
	@echo "Type:         Sanity" >> $(METADATA)
	@echo "TestTime:     30m" >> $(METADATA)
	@echo "RunFor:       $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     $(PACKAGE_NAME)" >> $(METADATA)
	@echo "Requires:     bind bind-chroot caching-nameserver bind-utils" >> $(METADATA)
	@echo "License:      GPLv2" >> $(METADATA)
	@echo "RhtsRequires: library(bind/bind-setup)" >> $(METADATA)
	#@echo "Releases:    just rhels... " >> $(METADATA)

	rhts-lint $(METADATA)
