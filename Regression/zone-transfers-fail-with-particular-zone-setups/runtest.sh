#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/zone-transfers-fail-with-particular-zone-setups
#   Description: zone-transfers-fail-with-particular-zone-setups
#   Author: Martin Cermak <mcermak@redhat.com>
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

rpm -q bind97 && PACKAGE="bind97" || PACKAGE="bind"
ORIGPWD=$( pwd )

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "rlImport bind/bind-setup"

        bsBindSetupStart "$ORIGPWD/named.conf"
        rlRun "rm -rf /var/named/include_0804 /var/named/include"
        rlRun "rm -rf /var/named/chroot/var/named/include_0804 /var/named/chroot/var/named/include"
        rlRun "tar -C /var/named -xmjf ${ORIGPWD}/reproducer.tar.bz2"
        rlRun "tar -C /var/named/chroot/var/named -xmjf ${ORIGPWD}/reproducer.tar.bz2"
        rlRun "mv /var/named/include_0804 /var/named/include"
        rlRun "mv /var/named/chroot/var/named/include_0804 /var/named/chroot/var/named/include"
        rlRun "chown -R named:named /var/named/epc.mnc990.mcc311.3gppnetwork.org.zone /var/named/include"
        rlRun "chown -R named:named /var/named/chroot/var/named/epc.mnc990.mcc311.3gppnetwork.org.zone /var/named/chroot/var/named/include"
        rlRun "restorecon -R /var/named"
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "cp /var/log/messages log1.txt"
        rlRun "dig @127.0.0.1 . AXFR > /dev/null"
        rlRun "sleep 3"
        rlRun "cp /var/log/messages log2.txt"
        rlRun "diff log1.txt log2.txt > diff.txt" 1

        rlRun "grep 'zone data: ran out of space' diff.txt" 1
    rlPhaseEnd

    rlPhaseStartCleanup

        rlRun "rm -rf /var/named/include_0804 /var/named/include"
        rlRun "rm -rf /var/named/chroot/var/named/include_0804 /var/named/chroot/var/named/include"
        rlRun "rm -f /var/named/epc.mnc990.mcc311.3gppnetwork.org.zone"
        rlRun "rm -f /var/named/chroot/var/named/epc.mnc990.mcc311.3gppnetwork.org.zone"

        bsBindSetupCleanup

        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
