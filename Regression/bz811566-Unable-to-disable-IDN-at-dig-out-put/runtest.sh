#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind97/Regression/bz811566-Unable-to-disable-IDN-at-dig-out-put
#   Description: Test for BZ#811566 (Unable to disable IDN at "dig" out put)
#   Author: Branislav Blaskovic <bblaskov@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2012 Red Hat, Inc. All rights reserved.
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

# Include Beaker environment
. /usr/bin/rhts-environment.sh
. /usr/share/beakerlib/beakerlib.sh

PACKAGE="bind97"

rlJournalStart
    rlPhaseStartSetup
	if rpm -q "bind"; then
		PACKAGE=bind
	fi
        rlAssertRpm "$PACKAGE"
	rlAssertRpm "$PACKAGE-utils"
    rlServiceStop "named"

	rlRun "rlFileBackup /etc/named.conf"
	echo '
zone "xn--mnchen-3ya.test" IN {
        type master;
        file "named.localhost";
        allow-update { none; };
};
' >> /etc/named.conf
	rlRun "sed -e 's/recursion on/recursion off/' -i /etc/named.conf"
	rlRun "sed -e 's/recursion yes/recursion no/' -i /etc/named.conf"
	rlRun "rlServiceStart named"

	export LC_ALL=en_US.UTF-8
	rlRun "locale"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "gunzip -c /usr/share/man/man1/dig.1.gz | grep \"like to turn off the IDN support for some reason, \"" 0 "Sentence is grammatically correct"

	rlLog "Checking IDN is enabled by default"
	rlRun "dig @localhost xn--mnchen-3ya.test | grep ^münchen.test" 0 "IDN is enabled on dig output"
	rlRun "dig @localhost münchen.test | grep ^münchen.test" 0 "IDN name is accepted on dig input"
	rlRun "host münchen.test localhost | grep ^münchen.test" 0 "IDN name is accepted on host input"

	rlRun "export CHARSET=ASCII IDN_DISABLE=1" 0 "Disabling IDN support"
	rlRun "dig @localhost münchen.test | grep ^münchen.test" 1-255 "IDN name is not accepted on dig input"
	rlRun "host münchen.test | grep ^münchen.test" 1-255 "IDN name is not accepted on host input"
	rlRun "dig @localhost xn--mnchen-3ya.test | grep ^xn--mnchen-3ya.test" 0 "ASCII encoded IDN name works when disabled"

	if dig -h | grep -q "+\[no\]idnin"; then
		export -n CHARSET # libidn on RHEL7 overrides command line parameters
		rlLog "DiG supports +idnin; check it works"
		rlRun "dig @localhost +idnin +noidnout münchen.test | grep ^xn--mnchen-3ya.test" 0 "IDN can disabled on dig output by parameter"
		rlRun "dig @localhost +noidnin +idnout xn--mnchen-3ya.test | grep ^münchen.test" 0 "IDN can disabled on dig input by parameter"
	fi

    rlPhaseEnd

    rlPhaseStartCleanup
        rlServiceStop "named"
        rlRun "rlFileRestore"
        rlRun "rlServiceRestore named"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
