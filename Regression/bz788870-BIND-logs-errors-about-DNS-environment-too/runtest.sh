#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz788870-BIND-logs-errors-about-DNS-environment-too
#   Description: Test for BZ#788870 (BIND logs errors about DNS environment too)
#   Author: Juraj Marko <jmarko@redhat.com>
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
. /usr/lib/beakerlib/beakerlib.sh

PACKAGE="bind"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlServiceStop "named"
        rlFileBackup /etc/named.conf
        echo "options {" > /etc/named.conf
        echo " filter-aaaa-on-v4 yes;" >> /etc/named.conf
        echo " filter-aaaa { 192.168.0.1; };" >> /etc/named.conf
        echo "};" >> /etc/named.conf
    rlPhaseEnd

    rlPhaseStartTest
        rlServiceStart "named"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlServiceStop "named"
        rlRun "rm -f /etc/named.conf"
        rlFileRestore
        rlServiceRestore "named"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
