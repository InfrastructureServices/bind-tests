#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz695382-bind97-does-not-contain-root-zone-dnskey
#   Description: bz695382-bind97-does-not-contain-root-zone-dnskey
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
. /usr/share/beakerlib/beakerlib.sh 

ORIGPWD=`pwd`

if rlIsRHEL 5 && rpm -q bind; then
        rlJournalStart
            rlPhaseStartTest
                rlLogInfo "It makes only sense to run this test for RHEL6/bind, or for RHEL5/bind97. But not for RHEL5/bind."
                rlRun "true"
            rlPhaseEnd
        rlJournalPrintText
        rlJournalEnd
else
        rlJournalStart
            rlPhaseStartSetup
		rngd -r /dev/urandom
                rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
                rlRun "chmod a+rx $TmpDir"
                rlRun "skfjhxshg=$TmpDir"
                rlRun "pushd $TmpDir"
                rlFileBackup --clean /var/named/chroot/

                rlRun "MYPACKAGE=$(rpm --queryformat="%{name}\n" -qf /etc/sysconfig/named)"
                rlRun "echo $MYPACKAGE | grep ^bind"
                rlRun "cp -p /etc/named.root.key $TmpDir/named.root.key"

                rlRun "rlImport bind/bind-setup"
                #rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

                bsBindSetupStart
                bsSetUserSettings "include \"\/etc\/named.root.key\";"
#https://mojo.redhat.com/docs/DOC-1010763:
                bsSetUserOptions "forwarders {                10.64.63.6;10.97.120.27;        };"
                rlRun "cp -p $TmpDir/named.root.key /var/named/chroot/etc/"
                bsBindSetupDone
            rlPhaseEnd

            rlPhaseStartTest
                rlRun "dig @127.0.0.1 . NS +dnssec &> output.txt"
                rlRun "cat output.txt"
                rlRun "grep ';; flags:[^;]* ad[^;]*;' output.txt"
            rlPhaseEnd
            rlPhaseStartCleanup
                bsBindSetupCleanup
                rlFileRestore
                rlRun "popd"
                rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
            rlPhaseEnd
        rlJournalPrintText
        rlJournalEnd
fi
