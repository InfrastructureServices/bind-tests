#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz517279-BIND-post-install-scripts-overwriting-data
#   Description: Test for bz517279 (BIND post install scripts overwriting data,)
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

# Include rhts environment
. /usr/bin/rhts-environment.sh
. /usr/lib/beakerlib/beakerlib.sh

# this test must not be run automatically
if test -z "$JOBID"; then

rlJournalStart
    rlPhaseStartSetup
        if rpm -q bind97; then
                rlAssertRpm "bind97-chroot"
                rlAssertRpm "bind97-utils"
                PACKAGE="bind97-chroot"
        else
                rlAssertRpm "bind-chroot"
                rlAssertRpm "bind-utils"
                PACKAGE="bind-chroot"
        fi
        rlRun "service named stop" 
        rlFileBackup --clean "/var/named"
        rlRun "rm -rf /var/named/*"
        rlRun "mkdir -p /var/named/chroot/var/named/data"
        rlRun "ln -s /var/named/chroot/var/named/data /var/named/data"
        rlRun "touch /var/named/data/testfile"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "file /var/named/data/* | grep \"broken symbolic link\"" 1
        if rlIsFedora; then
            rlRun "dnf -y remove $PACKAGE"
            rlRun "dnf -y install $PACKAGE"
        else
            rlRun "yum -y remove $PACKAGE"
            rlRun "yum -y install $PACKAGE"
        fi
        rlRun "file /var/named/data/* | grep \"broken symbolic link\"" 1
    rlPhaseEnd

    rlPhaseStartCleanup
        rlFileRestore
    rlPhaseEnd
rlJournalEnd

else

rlJournalStart
        rlPhaseStartTest
                rlLogInfo "This test should be run by hand. Reporting PASS formally."
        rlPhaseEnd
rlJournalEnd

fi
