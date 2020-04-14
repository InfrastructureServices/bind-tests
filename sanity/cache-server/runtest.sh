#!/bin/bash                                                 
# vim: dict=/usr/share/rhts-library/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   runtest.sh of /CoreOS/bind/sanity/cache-server                   
#   Author: Matej Susta <msusta@redhat.com>                          
#           Martin Cermak <msusta@redhat.com> 
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

#Include rhts environment
. /usr/bin/rhts-environment.sh           1                                        
. /usr/share/rhts-library/rhtslib.sh      
. /usr/share/beakerlib/beakerlib.sh || exit 1
  

PACKAGE="bind"
LH="127.0.0.1"
SCORE=0

DOMAIN1="ns1.redhat.com"
DOMAIN2="ns2.redhat.com"
DOMAIN3="ns3.redhat.com"

LOOPS_COUNT=300

rlJournalStart
    rlPhaseStartSetup Setup
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "rlImport bind/bind-setup"
       # rlRun "wget --quiet http://nest.test.redhat.com/mnt/qa/scratch/mcermak/bind-setup.tar.gz && tar xvzf bind-setup.tar.gz > /dev/null && . bind-setup/bind-setup.sh" 0 "Imported bind-setup functions."

        bsBindSetupStart
        bsDnssecDisable
        bsSetUserOptions "forwarders { `bsGetDefaultNameServer`; };"
        bsSetUserOptions "forward only;"
        bsBindSetupDone
    rlPhaseEnd

    rlPhaseStartTest Test
        if ! test -e /etc/rndc.key; then
                rlRun "touch /etc/rndc.key"
                rlRun "chmod a+w /etc/rndc.key"
                rlRun "rndc-confgen -a"
                rlRun "service named restart"
        fi
        #rlRun "test -e /etc/rndc.key || rndc-confgen -a"
        rlRun "/usr/sbin/rndc flush" 0 "Flushing caches"
        rlRun "SERVER_RESPONDS=TRUE"
        rlRun "/usr/bin/dig @$LH $DOMAIN1 +short || SERVER_RESPONDS=FALSE"
        rlRun "/usr/bin/dig @$LH $DOMAIN2 +short || SERVER_RESPONDS=FALSE"
        rlRun "/usr/bin/dig @$LH $DOMAIN3 +short || SERVER_RESPONDS=FALSE"

        if [ "$SERVER_RESPONDS" == 'FALSE' ]; then
                rlRun "false" 0 "Our domains did not get resolved."
        fi

        rlRun "/usr/sbin/rndc dumpdb -cache &>/dev/null" 0 "Dupming cache"
        rlRun "/usr/sbin/rndc flush &>/dev/null" 0 "Flushing caches"

        if [ "$SERVER_RESPONDS" == 'TRUE' ]; then
                for i in `seq 1 $LOOPS_COUNT`;do
                        /usr/bin/dig @localhost $DOMAIN1 &>/dev/null || let "SCORE += 1"
                        #echo "1.domain1"
                        /usr/bin/dig @localhost $DOMAIN2 &>/dev/null || let "SCORE += 1"
                        #echo "1.domain2"
                        /usr/bin/dig @localhost $DOMAIN3 &>/dev/null || let "SCORE += 1"
                        #echo "1.domain3"
                        /usr/bin/dig @localhost $DOMAIN1 &>/dev/null || let "SCORE += 1"
                        #echo "2.domain1"
                        /usr/bin/dig @localhost $DOMAIN2 &>/dev/null || let "SCORE += 1"
                        #echo "2.domain2"
                        /usr/bin/dig @localhost $DOMAIN3 &>/dev/null || let "SCORE += 1"
                        #echo "2.domain3"

                        /usr/sbin/rndc flush &>/dev/null
                done
        fi

    rlAssert0 "Checking return value after loops" "$SCORE"

    rlPhaseEnd


    rlPhaseStartCleanup Cleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalEnd
