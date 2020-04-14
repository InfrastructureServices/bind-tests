#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz518866-named-stops-responding-after-an-unexpected-error
#   Description: Test for bz518866 (named stops responding after an unexpected error)
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

rlJournalStart
    rlPhaseStartSetup
	rngd -r /dev/urandom	
        if rpm -q bind97; then
                rlAssertRpm bind97-chroot
                rlAssertRpm bind97-utils
        else
                rlAssertRpm bind-chroot
                rlAssertRpm bind-utils
        fi

        service named stop
        killall -9 named

        rlRun "MYCONFIG=`mktemp`" 
        rlRun "chmod 0666 $MYCONFIG"
        rlRun "chcon --type=named_conf_t $MYCONFIG"
        rlRun "MYLOG=`mktemp`"
        rlRun "chmod 0666 $MYLOG"
        rlRun "chcon --type=named_log_t $MYLOG"
    rlPhaseEnd

    rlPhaseStartTest
cat <<MYMARK > $MYCONFIG
options {
        listen-on { none; };
        listen-on-v6 { any; };
};
MYMARK
        rlRun "named -c $MYCONFIG -g -u named &> $MYLOG &" 0 "Run bind"
        rlRun "sleep 2"
        rlRun "grep \"running\" $MYLOG" 0 "Ensure bind started"
        rlRun "cut --characters=-80 $MYLOG" 0 "Print the log for debugging purposes"
        rlRun "ls -la /var/run/named/named.pid" 0-255
        rlRun "netstat -tulpn | grep named"
        rlRun "dig +time=1 @127.0.0.1 foo.bar" 0-255 "Try to invoke the bug"
        rlRun "grep \"unexpected error\" $MYLOG" 1 "Ensure the bug is fixed"
        rlRun "killall -9 named" 0 "Kill bind"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rm -rf $MYCONFIG $MYLOG"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

