#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz623673-Single-Zone-File-Error-Causes-Full-BIND-Failure
#   Description: Test for bz623673 (Single Zone File Error Causes Full BIND Failure)
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

PACKAGE="bind"
ORIGPWD=`pwd`

rlJournalStart
    rlPhaseStartSetup
        rlFileBackup --clean /var/named
        rlFileBackup /etc/sysconfig/named
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

        bsBindSetupStart "$ORIGPWD/named.conf" "chrooton"
        rlRun "cp $ORIGPWD/290b3302.cz.zone /var/named/chroot/var/named/290b3302.cz.zone"
        rlRun "cp $ORIGPWD/290b3302.cz.zone /var/named/290b3302.cz.zone"
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "dig @localhost 290b3302.cz +short | grep \"192.168.1.28\""


        rlRun "echo blablabla >> /var/named/chroot/var/named/290b3302.cz.zone"
        rlRun "echo blablabla >> /var/named/290b3302.cz.zone"

        rlRun "service named restart" 1-255

        rlRun "echo \"DISABLE_ZONE_CHECKING=yes\" >> /etc/sysconfig/named"

        rlRun "service named restart" 0

        rlRun "dig @localhost 290b3302.cz +short | grep \"192.168.1.28\"" 1
    rlPhaseEnd

    rlPhaseStartCleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        /bin/rm -f /var/named/chroot/var/named/290b3302.cz.zone /var/named/290b3302.cz.zone
    rlPhaseEnd
rlJournalEnd
