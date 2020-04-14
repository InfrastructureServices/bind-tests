#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/Regression-BIND-9-11-listens-on-53-even-it
#   Description: Test for BZ#1753259 (Regression BIND 9.11 listens on []53 even it isn't)
#   Author: Petr Sklenar <psklenar@redhat.com>
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

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
	cat << EOF > /etc/named.my
options {
	listen-on port 53 { 127.0.0.1; };
};

EOF
	rlRun "named -u named -d10 -c /etc/named.my"
    rlPhaseEnd

    rlPhaseStartTest
	rlRun "pgrep named"
	rlRun "ss -lnp  | grep named | grep :53"
if rpm -q rpm  | grep el7;then
	rlRun "ss -lnp -f inet6 | grep named | grep :53" 1 "EL7 ONLY : NO LISTENING ON IPv6"
else
	rlRun "ss -lnp -f inet6 | grep named | grep :53" 0 "LISTENING ON IPv6 by default"
fi
    rlPhaseEnd

    rlPhaseStartCleanup
	rm -rf /etc/named.my
	rlRun "pkill named"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
