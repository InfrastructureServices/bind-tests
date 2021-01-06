#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/bind-dualhost-test-skeleton
#   Description: Tests bind
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

# now the ROOTDIR should get defined
. /etc/sysconfig/named

        echo "ROOTDIR=$ROOTDIR"

        exit


ORIGPWD=`pwd`
PACKAGE="bind"
CNF="$ROOTDIR/etc/named.conf"
TDOMAIN="myexdomain.cz"
IP1=192.168.66.1
IP2=192.168.66.2
IP3=192.168.66.3
IP4=192.168.66.4
IP5=192.168.66.5

# set client & server manually if debugging
SERVERS="dell-pe1750-1.rhts.eng.rdu.redhat.com"
CLIENTS="dell-pe1850-02.rhts.eng.bos.redhat.com"

Server() {
    rlPhaseStartTest Server
        # server setup goes here
        rlLog "ROOTDIR=$ROOTDIR"

        # backup configs
        rlFileBackup $CNF
	rlFileBackup --clean $CNF `readlink -f $CNF`
	rlFileBackup --clean /etc/resolv.conf `readlink -f /etc/resolv.conf`

        # zonefile
        rlRun "TZONEFILE=$ROOTDIR/var/named/$TDOMAIN.zone"

        # set up named.conf
        rlRun "cp $ORIGPWD/named.conf $CNF"
        rlRun "chmod a+r $CNF"
        rlRun "sed -i \"s/<DOMAIN>/$TDOMAIN/g\" $CNF"

        # set up zonefile
        rlRun "cp zonefile $TZONEFILE"
        rlRun "chmod a+r $TZONEFILE"
        rlRun "sed -i \"s/<DOMAIN>/$TDOMAIN/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP1>/$IP1/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP2>/$IP2/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP3>/$IP3/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP4>/$IP4/g\" $TZONEFILE"
        rlRun "sed -i \"s/<IP5>/$IP5/g\" $TZONEFILE"
        rlRun "sed -i \"s/<SERIAL>/$SERIAL/g\" $TZONEFILE"

        # (re)start the server
        rlServiceStart "named"

        rlRun "rhts-sync-set -s READY" 0 "Server ready"
        rlRun "rhts-sync-block -s DONE $CLIENTS" 0 "Waiting for the client"

        # clean up
        rlFileRestore
        rlRun "rm -rf $TZONEFILE"
        
        # (re)start the server
        rlServiceStart "named"

    rlPhaseEnd
}

Client() {
    rlPhaseStartTest Client
        rlRun "rhts-sync-block -s READY $SERVERS" 0 "Waiting for the server"
        # client action goes here
        rlRun "rhts-sync-set -s DONE" 0 "Client done"
    rlPhaseEnd
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlLog "Server: $SERVERS"
        rlLog "Client: $CLIENTS"
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlAssertRpm bind
        rlAssertRpm bind-chroot
        rlAssertRpm bind-utils        

    rlPhaseEnd

    if echo $SERVERS | grep -q $HOSTNAME ; then
        Server
    elif echo $CLIENTS | grep -q $HOSTNAME ; then
        Client
    else
        rlReport "Stray" "FAIL"
    fi

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
