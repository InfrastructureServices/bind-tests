#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz500535-etc-init-d-named-script-kills-all-process-named
#   Description: Test for bz500535 (/etc/init.d/named script kills all process named)
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

rlJournalStart
    rlPhaseStartSetup
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        #old backup because the bsBindSetupStart backup the same file
        cp -a /etc/named.conf /$TmpDir/named.conf
		
        rlRun "rlImport bind/bind-setup"
        #rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."
        echo "controls { inet 127.0.0.1 allow { none; }; };" >> /etc/named.conf
	# Second instance must not listen on the same port
	rlRun "sed -e 's/port 53/port 853/' /etc/named.conf > /etc/named/named-2.conf"
	rlRun "chown root:named /etc/named/named-2.conf"
	rlRun "chmod 0640 /etc/named/named-2.conf"
        bsBindSetupStart "" "chrootoff" 
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        # bsBindSetupStart ensures that
        # only one instance of bind is run

        # sleep a while
        rlRun "sleep 3"

        # let's start one extra named process
        rlRun "named -g -u named -c /etc/named/named-2.conf &"

        # sleep a while
        rlRun "sleep 3"

        # check what's running
        ps axu | grep named &> $TmpDir/two_processes_should_be_running.txt

        # our extra named shouldn't be killed here: 
        # Just the originally started process should be stopped:
        rlRun "service named stop" 0,1
        # RHEL6 bind fails to stop if our extra named process runs. Respectively - it stops, but ends up with 1.

        # check what's running
        ps axu | grep named &> $TmpDir/just_one_process_should_be_running.txt

        # ... so ensure it runs:
sleep 10
        rlRun "ps axu | grep \"named\ -g\ -u\ named\""
        rlRun "ps axu | grep \"named\ -g\ -u\ named\" | wc -l | grep \"^1$\"" 0 "Exactly one named process should be running now."
    rlPhaseEnd

    rlPhaseStartCleanup
       # rlFileBackup "TESTLOGS" "$TmpDir/two_processes_should_be_running.txt" "$TmpDir/just_one_process_should_be_running.txt"
        rlRun "killall named" 0-255
        bsBindSetupCleanup
 
        cp -a  $TmpDir/named.conf /etc/named.conf
	rlRun "rm -f /etc/named/named-2.conf"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
