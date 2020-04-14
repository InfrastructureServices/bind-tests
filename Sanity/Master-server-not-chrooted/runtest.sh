#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/Master-server-not-chrooted
#   Description: Set up master nameserver, test it.
#   Author: Martin Cermak <mcermak@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2009 Red Hat, Inc. All rights reserved.
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
#set -x
. /usr/lib/beakerlib/beakerlib.sh

# Some heplful functions
randomString () {
    TEMPSTR=`date +%c%N | md5sum | awk '{print $1}'`
    echo ${TEMPSTR:0:8}
    unset TEMPSTR
}

randomIp () {
    echo "192.168.1.`echo $[ $RANDOM / 256 + 1 ]`"
}

randomSerial () {
    date +%N
}

# Variable declarations
CONF="/etc/named.conf"
IP1=`randomIp`
IP2=`randomIp`
IP3=`randomIp`
IP4=`randomIp`
IP5=`randomIp`
SERIAL=`randomSerial`
ORIGPWD=`pwd`

# The test
rlJournalStart
    rlPhaseStartSetup
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "rlImport bind/bind-setup"

        bsBindSetupStart "$ORIGPWD/named.conf" "off"

        rlRun "TDOMAIN=`randomString`.cz"
        rlRun "TZONEFILE=$ROOTDIR/var/named/$TDOMAIN.zone"

        # set up /etc/named.conf
        rlRun "sed -i \"s/<DOMAIN>/$TDOMAIN/g\" $CONF"

        # set up zonefile
        rlRun "cp $ORIGPWD/zonefile $TZONEFILE"
        rlRun "chmod a+r $TZONEFILE"
        rlRun "sed -i \"s/<DOMAIN>/$TDOMAIN/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP1>/$IP1/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP2>/$IP2/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP3>/$IP3/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP4>/$IP4/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP5>/$IP5/g\" $TZONEFILE"
        rlRun "sed -i \"s/<SERIAL>/$SERIAL/g\" $TZONEFILE"

        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        # perform tests
        rlRun "dig @localhost $TDOMAIN | grep \"^$TDOMAIN\" | head -n 1 | grep \"$IP1\""
        rlRun "dig @localhost server1.$TDOMAIN | grep \"^server1.$TDOMAIN\" | grep \"$IP2\""
        rlRun "dig @localhost server2.$TDOMAIN | grep \"^server2.$TDOMAIN\" | grep \"$IP3\""
        rlRun "dig @localhost dns1.$TDOMAIN | grep \"^dns1.$TDOMAIN\" | grep \"$IP4\""
        rlRun "dig @localhost dns2.$TDOMAIN | grep \"^dns2.$TDOMAIN\" | grep \"$IP5\""
        rlRun "dig @localhost ftp.$TDOMAIN | grep \"^ftp.$TDOMAIN\" | grep \"server1.$TDOMAIN\""
        rlRun "dig @localhost mail.$TDOMAIN | grep \"^mail.$TDOMAIN\" | grep \"server1.$TDOMAIN\""
        rlRun "dig @localhost mail2.$TDOMAIN | grep \"^mail2.$TDOMAIN\" | grep \"server2.$TDOMAIN\""
        rlRun "dig @localhost www.$TDOMAIN | grep \"^www.$TDOMAIN\" | grep \"server2.$TDOMAIN\""

    rlPhaseEnd

    rlPhaseStartCleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -rf $TZONEFILE"
    rlPhaseEnd
rlJournalEnd
