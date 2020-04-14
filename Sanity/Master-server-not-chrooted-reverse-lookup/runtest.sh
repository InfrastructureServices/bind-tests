#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/Master-server-not-chrooted-reverse-lookup
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
. /usr/share/beakerlib/beakerlib.sh || exit 1

# Some heplful functions
randomString () {
    TEMPSTR=`date +%c%N | md5sum | awk '{print $1}'`
    echo ${TEMPSTR:0:8}
    unset TEMPSTR
}

randomNo () {
    echo $[ $RANDOM / 256 + 1 ]
}

randomSerial () {
    date +%N
}

# Variable declarations
SERIAL=`randomSerial`
NO1=`randomNo`
NO2=`randomNo`
NO3=`randomNo`
ORIGPWD=`pwd`

# The test
rlJournalStart
    rlPhaseStartSetup
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "rlImport bind/bind-setup"
        #rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

        bsBindSetupStart "$ORIGPWD/named.conf" "off"

        rlRun "TDOMAIN=`randomString`.cz"
        rlRun "TZONEFILE=$ROOTDIR/var/named/$TDOMAIN.rr.zone"
        rlRun "sed -i \"s/<DOMAIN>/$TDOMAIN/g\" /etc/named.conf"

        # zonefile
        rlRun "cp $ORIGPWD/zonefile $TZONEFILE"
        rlRun "chmod a+r $TZONEFILE"
        rlRun "sed -i \"s/<DOMAIN>/$TDOMAIN/g\" $TZONEFILE"
        rlRun "sed -i \"s/<SERIAL>/$SERIAL/g\" $TZONEFILE"
        rlRun "sed -i \"s/<NO1>/$NO1/g\" $TZONEFILE"
        rlRun "sed -i \"s/<NO2>/$NO2/g\" $TZONEFILE"
        rlRun "sed -i \"s/<NO3>/$NO3/g\" $TZONEFILE"

        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest
        # perform tests
        rlRun "dig @localhost -x 10.0.1.$NO1 +short | grep \"^alice.$TDOMAIN.$\""
        rlRun "dig @localhost -x 10.0.1.$NO2 +short | grep \"^betty.$TDOMAIN.$\""
        rlRun "dig @localhost -x 10.0.1.$NO3 +short | grep \"^charlie.$TDOMAIN.$\""
    rlPhaseEnd

    rlPhaseStartCleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rm -rf $TZONEFILE"
    rlPhaseEnd
rlJournalEnd
