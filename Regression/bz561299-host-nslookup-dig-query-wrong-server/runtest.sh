#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz561299-host-nslookup-dig-query-wrong-server
#   Description: Test for bz561299 (host/nslookup/dig query wrong server)
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

UNEXISTINGIP="1.2.3.4"

rlJournalStart
    rlPhaseStartSetup
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
		
		rlRun "rlImport bind/bind-setup"
        #rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

        bsBindSetupStart
        bsSetUserOptions "forwarders { `bsGetDefaultNameServer`; };"
        bsSetUserOptions "forward only;"
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        # out UNEXISTINGIP shouldn't be reachable
        rlRun "ping -c 1 $UNEXISTINGIP" 1
        # the test itself
        rlRun "nslookup ns1.redhat.com $UNEXISTINGIP 2>&1 | grep \"no servers could be reached\""
    rlPhaseEnd

    rlPhaseStartCleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
