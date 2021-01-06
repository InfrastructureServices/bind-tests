# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /CoreOS/bind/Regression/bz518866-named-stops-responding-after-an-unexpected-error
#   Description: Test for bz518866 (named stops responding after an unexpected error)
#   Author: Martin Cermak <mcermak@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2010 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

export TEST=/CoreOS/bind/Regression/bz518866-named-stops-responding-after-an-unexpected-error
export TESTVERSION=1.0

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE

.PHONY: all install download clean

run: $(FILES) build
	./runtest.sh

build: $(BUILT_FILES)
	chmod a+x runtest.sh

clean:
	rm -f *~ $(BUILT_FILES)


include /usr/share/rhts/lib/rhts-make.include

$(METADATA): Makefile
	@echo "Owner:           Martin Cermak <mcermak@redhat.com>" > $(METADATA)
	@echo "Name:            $(TEST)" >> $(METADATA)
	@echo "TestVersion:     $(TESTVERSION)" >> $(METADATA)
	@echo "Path:            $(TEST_DIR)" >> $(METADATA)
	@echo "Description:     Test for bz518866 (named stops responding after an unexpected error)" >> $(METADATA)
	@echo "Type:            Regression" >> $(METADATA)
	@echo "TestTime:        5m" >> $(METADATA)
	@echo "RunFor:          bind" >> $(METADATA)
	@echo "Requires:        bind bind-utils bind-chroot" >> $(METADATA)
# caching nameserver on older RHELs ensures the existence of /etc/named.conf file
	@echo "Requires:        caching-nameserver net-tools redhat-lsb rng-tools rng-utils psmisc" >> $(METADATA)
	@echo "Priority:        Normal" >> $(METADATA)
	@echo "License:         GPLv2" >> $(METADATA)
	@echo "Confidential:    no" >> $(METADATA)
	@echo "Destructive:     no" >> $(METADATA)
	@echo "Bug:             518866" >> $(METADATA)

	rhts-lint $(METADATA)
