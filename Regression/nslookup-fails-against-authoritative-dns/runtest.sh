#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/nslookup-fails-against-authoritative-dns
#   Description: nslookup-fails-against-authoritative-dns
#   Author: Martin Cermak <mcermak@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
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

rpm -q bind97 && PACKAGE="bind97" || PACKAGE="bind"

rlJournalStart
    rlPhaseStartSetup
        rlRun "ORIGPWD=$( pwd )"
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
	rlFileBackup --clean /etc/resolv.conf `readlink -f /etc/resolv.conf`        
        rlRun "rlImport bind/bind-setup"

        #rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

        if rlIsRHEL 5; then
                bsBindSetupStart "$ORIGPWD/custom.rhel5.conf"
        else
                bsBindSetupStart "$ORIGPWD/custom.rhel6.conf"
        fi
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        if rlIsRHEL 5 && rpm -q bind97; then
            rlPass 'Bug got a WONTFIX for bind97 on RHEL5 (i.e., current config) - see bz#757706. Skipping test.'
        else
            # resolv.conf is already backed up ATM (by common functions)
            echo "nameserver 127.0.0.1" > /etc/resolv.conf
            echo "nameserver 1.1.1.1" >> /etc/resolv.conf
            rlRun "nslookup localhost 2>&1 | tee output.txt"
            rlRun "grep -q 'no servers could be reached' output.txt" 1
        fi
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
	rlFileRestore
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
