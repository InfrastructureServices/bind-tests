# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Makefile of /CoreOS/bind/Sanity/Run-internal-BIND-test-suite
#   Description: Run internal BIND test suite
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

export TEST=/CoreOS/bind/Sanity/Run-internal-BIND-test-suite
export TESTVERSION=1.3

BUILT_FILES=

FILES=$(METADATA) runtest.sh Makefile PURPOSE knownerror* setup-named-softhsm.sh bind-systest-filter.sh

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
	@echo "Description:     Run internal BIND test suite" >> $(METADATA)
	@echo "Type:            Sanity" >> $(METADATA)
	@echo "TestTime:        8h" >> $(METADATA)
	@echo "RunFor:          bind" >> $(METADATA)
	@echo "Requires:        bind perl-Net-DNS rpm-build bind-utils" >> $(METADATA)
	@echo "Requires:        bind-pkcs11 bind-pkcs11-utils softhsm" >> $(METADATA)
	@echo "Requires:        openssl-devel libtool autoconf" >> $(METADATA)
	@echo "Requires:        libcap-devel libidn-devel libxml2-devel" >> $(METADATA) 
	@echo "Requires:        openldap-devel postgresql-devel" >> $(METADATA)
	@echo "Requires:        sqlite-devel krb5-devel net-tools perl-Net-DNS-Nameserver" >> $(METADATA)
	@echo "Requires:        yum-utils dnf-utils" >> $(METADATA)
	@echo "Requires:        gcc-c++" >> $(METADATA)
	@echo "Priority:        Normal" >> $(METADATA)
	@echo "License:         GPLv2" >> $(METADATA)
	@echo "Confidential:    no" >> $(METADATA)
	@echo "Destructive:     no" >> $(METADATA)
	@echo "Bug:             642970" >> $(METADATA)

	rhts-lint $(METADATA)
