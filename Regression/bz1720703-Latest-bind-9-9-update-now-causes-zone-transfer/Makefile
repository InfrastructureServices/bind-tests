# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /CoreOS/bind/Regression/bz1720703-Latest-bind-9-9-update-now-causes-zone-transfer
#   Description: Test for BZ#1720703 (Latest bind (9.9) update now causes zone transfer)
#   Author: Petr Mensik <pemensik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2019 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

export TEST=/CoreOS/bind/Regression/bz1720703-Latest-bind-9-9-update-now-causes-zone-transfer
export TESTVERSION=1.0

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE named.conf bigzone.zone root.zone

.PHONY: all install download clean

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	test -x runtest.sh || chmod a+x runtest.sh

clean:
	rm -f *~ $(BUILT_FILES)


include /usr/share/rhts/lib/rhts-make.include

$(METADATA): Makefile
	@echo "Owner:           Petr Mensik <pemensik@redhat.com>" > $(METADATA)
	@echo "Name:            $(TEST)" >> $(METADATA)
	@echo "TestVersion:     $(TESTVERSION)" >> $(METADATA)
	@echo "Path:            $(TEST_DIR)" >> $(METADATA)
	@echo "Description:     Test for BZ#1720703 (Latest bind (9.9) update now causes zone transfer)" >> $(METADATA)
	@echo "Type:            Regression" >> $(METADATA)
	@echo "TestTime:        5m" >> $(METADATA)
	@echo "RunFor:          bind" >> $(METADATA)
	@echo "Requires:        bind bind-utils" >> $(METADATA)
	@echo "Priority:        Normal" >> $(METADATA)
	@echo "License:         GPLv2+" >> $(METADATA)
	@echo "Confidential:    no" >> $(METADATA)
	@echo "Destructive:     no" >> $(METADATA)
	@echo "Bug:             1720703" >> $(METADATA)
	@echo "Releases:        -RHEL4 -RHELClient5 -RHELServer5" >> $(METADATA)

	rhts-lint $(METADATA)
