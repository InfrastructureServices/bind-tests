#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz160914-bind-does-not-go-on-to-second-DNS-when-first-one
#   Description: Test for bz160914 (bind does not go on to second DNS when first one)
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
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"

NS1="ns1.redhat.com"

rlJournalStart
    rlPhaseStartSetup
        rlFileBackup --clean /var/named
        rlFileBackup /etc/sysconfig/named
        rlFileBackup /etc/named.conf
	rlFileBackup --clean /etc/resolv.conf `readlink -f /etc/resolv.conf`
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "rlImport bind/bind-setup"
        #rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

    rlGetTestState && { 
        bsBindSetupStart "" "chrootoff"
            bsRemoveConfSetting "recursion.*yes"
            bsSetUserOptions "recursion no;" 
            bsBindSetupDone
    }
    rlPhaseEnd
rlGetTestState && { 
    rlPhaseStartTest
        rlRun "RHNS=`bsGetDefaultNameServer`"

        rlRun "nslookup $NS1 127.0.0.1 &> nslookup_localhost.txt" 0,1
        rlRun "nslookup $NS1 $RHNS &> nslookup_rhns.txt"
        rlRun "nslookup $NS1 &> nslookup_test1.txt"

        if rlIsRHEL 3 || rlIsRHEL 4 || rlIsRHEL 5; then
                rlRun "grep -q 'No answer' nslookup_localhost.txt" 0
        else
                rlRun "grep -q 'REFUSED' nslookup_localhost.txt" 0
        fi
        rlRun "grep -q 'No answer' nslookup_rhns.txt" 1
        rlRun "grep -q 'No answer' nslookup_test1.txt" 1

        rlRun "echo 'nameserver 127.0.0.1' > /etc/resolv.conf"
        rlRun "echo 'nameserver $RHNS' >> /etc/resolv.conf"
        rlRun "cat /etc/resolv.conf"

        rlRun "nslookup $NS1 &> nslookup_test2.txt"

        #bz756458 on rhel5 bug CLOSED WONTFIX 
        if ! rlIsRHEL 5 ; then
            rlRun "grep -q 'No answer' nslookup_test2.txt" 1
            rlRun "grep -q 'trying next server' nslookup_test2.txt" 0
        fi

        rlRun "echo 'nameserver $RHNS' > /etc/resolv.conf"
        rlRun "echo 'nameserver 127.0.0.1' >> /etc/resolv.conf"
        rlRun "cat /etc/resolv.conf"

        rlRun "nslookup $NS1 &> nslookup_test3.txt"

        rlRun "grep -q 'No answer' nslookup_test3.txt" 1
        rlRun "grep -q 'trying next server' nslookup_test3.txt" 1
    rlPhaseEnd
}
    rlPhaseStartCleanup
        rlBundleLogs "TEST_LOGS" "nslookup_localhost.txt" "nslookup_rhns.txt" "nslookup_test1.txt" "nslookup_test2.txt" "nslookup_test3.txt"
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
