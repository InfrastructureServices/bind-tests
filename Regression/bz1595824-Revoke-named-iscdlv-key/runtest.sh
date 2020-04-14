#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1595824-Revoke-named-iscdlv-key
#   Description: Test for BZ#1595824 (Revoke named.iscdlv.key)
#   Author: Ondrej Mejzlik <omejzlik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
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

PACKAGE=${PACKAGE:-bind}

rlJournalStart
        rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        if [ $? -ne 0  ]; then
            rlDie "Package $PACKAGE not installed"
        fi
        rlLog "PC name: $(hostname)"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlGetTestState && {
    rlPhaseStartTest
        rlAssertExists "/etc/named.conf"
        rlAssertExists "/etc/named.root.key"
        # /etc/named.iscdlv.key has been revoked and removed from the package
        rlAssertNotExists "/etc/named.iscdlv.key"
        rlRun "grep 'iscdlv' /etc/named.conf" 1 "iscdlv is not present in working configuration"
        rlRun "grep 'named.root.key' /etc/named.conf" 0 "named.root.key is mentioned in configuration"
        rlRun "grep 'iscdlv' /usr/share/doc/bind/sample/etc/named.conf" 1 "iscdlv is not present in sample configuration"
        rlRun "man named | grep 'iscdlv'" 1 "iscdlv is not mentioned in manpages"
    rlPhaseEnd
    }

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
