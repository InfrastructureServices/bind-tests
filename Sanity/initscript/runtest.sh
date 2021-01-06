#!/bin/bash
# vim: dict=/usr/share/rhts-library/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/initscript
#   Description: Init script should meet LSB specifications
#   Author: Jan Scotka <jscotka@redhat.com>, Yulia Kopkova <ykopkova@redhat.com>
#   and for el8 && fedora reworked by psklenar@redhat.com Petr Sklenar
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
. /usr/bin/rhts-environment.sh
. /usr/share/rhts-library/rhtslib.sh
. /usr/share/beakerlib/beakerlib.sh || exit 1


SERVICE='named'
rlJournalStart
    rlPhaseStartSetup
        rlRun "useradd testuserqa" 0 "Add test user"

        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"

        rlRun "rlImport bind/bind-setup"

        bsBindSetupStart
        bsBindSetupDone

	export SYSTEMD_PAGER=''
    rlPhaseEnd

    rlPhaseStartTest $SERVICE
	        rlServiceStop $SERVICE
                rlLog ">>>>>>>>> service start"
                rlRun "service $SERVICE start" 0 " Service must start without problem"
                rlRun "service $SERVICE status" 0 " Then Status command "
                rlRun "service $SERVICE start" 0 " Already started service "
                rlRun "service $SERVICE status" 0 " Again status command "

                rlLog ">>>>>>>>> service restart"
                rlRun "service $SERVICE restart" 0 " Restarting of service"
                rlRun "service $SERVICE status" 0 " Status command "

                rlLog ">>>>>>>>> service stop"
                rlRun "service $SERVICE stop" 0 " Stopping service "
                rlRun "service $SERVICE status" 3 " Status of stopped service "
                rlRun "service $SERVICE stop" 0 " Stopping service again "
                rlRun "service $SERVICE status" 3 " Status of stopped service "

                rlLog ">>>>>>>>> insufficient rights"
                rlRun "service $SERVICE start " 0 " Starting service for restarting under nonpriv user "
                rlRun "su testuserqa -c 'service $SERVICE restart'" 1,4 "Insufficient rights, restarting service under nonprivileged user must fail"

                rlLog ">>>>>>>>> operations"
                rlRun "service $SERVICE start" 0 " Service have to implement start function "
                rlRun "service $SERVICE restart" 0 " Service have to implement restart function "
                rlRun "service $SERVICE status" 0 " Service have to implement status function "
                rlRun "service $SERVICE condrestart" 0 " Service have to implement condrestart function "
                rlRun "service $SERVICE try-restart" 0 " Service have to implement try-restart function "
                rlRun "service $SERVICE reload" 0 " Service have to implement reload function "
                rlRun "service $SERVICE force-reload" 0 " Service have to implement force-reload function "

                rlLog ">>>>>>>>> nonexist operations"
		# systemd returns always 1, just make sure it just fails
                rlRun "service $SERVICE noexistop" 1,2 " Testing proper return code when nonexisting function"
	rlPhaseEnd

	rlPhaseStartTest
#this is bug for rhel7, rhel8.0, rhel8.2

		echo 'corrupted' >> /etc/named.conf
		rlRun "service $SERVICE reload" 1-255
                rlRun "service $SERVICE status" 0 " Service still runs with previous configuration"
		
	rlPhaseEnd

    rlPhaseStartCleanup
        bsBindSetupCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "userdel -fr testuserqa" 0 "Remove test user"
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd
