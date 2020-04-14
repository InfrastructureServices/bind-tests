#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1609856-bind-disable-GeoIP-support
#   Description: Test for BZ#1609856 (bind disable GeoIP support)
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
        TESTDIR=$(pwd)
        rlRun "rlFileBackup /etc/named.conf" 0 "Backing up /etc/named.conf"
        rlLog "PC name: $(hostname) User: $(whoami)"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlGetTestState && {
    rlPhaseStartTest CheckRequirements
        # Systems may provide more versions, we need only the installed bind version.
        rlRun "repoquery --requires $(rpm -q bind) | grep -i 'libGeoIP'" 1 "Geoip library is not in requirements"
    rlPhaseEnd    

    rlPhaseStartTest RunWithGeoIP
        rlRun "rlServiceStart named" 0 "Named should start with default config"
        rlRun "cp -f $TESTDIR/named.conf /etc/named.conf" 0 "Put geoip option into config"
        rlRun "rlServiceStart named" 1 "Named should NOT start with geoip"
        rlRun "systemctl status named | grep \"option .geoip-directory. was not enabled at compile time\"" 0 "Log reports geoip disabled"
    rlPhaseEnd
    }

    rlPhaseStartCleanup
        rlRun "rlFileRestore" 0 "Restoring /etc/named.conf"
        rlLog "Restoring original named state"
        rlServiceRestore
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
