#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1321239-The-bind-and-bind-chroot-packages-specs-define-and
#   Description: Test for BZ#1321239 (The bind and bind-chroot packages specs define and)
#   Author: Petr Sklenar <psklenar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2016 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="bind"

rlJournalStart

if rlIsRHEL 6;then
    SERVICENAME="named"
else
    SERVICENAME="named named-chroot"
fi
    


for i in $SERVICENAME;do
    rlPhaseStartSetup "service $i"
       rlRun "rlServiceStart $i"
    rlPhaseEnd

    rlPhaseStartTest "service $i"
       rlRun "rlServiceStop $i"
       rlRun "rpm -V bind bind-chroot"
       rlRun "rlServiceStart $i"
       rlRun "rpm -V bind bind-chroot"
    rlPhaseEnd

    rlPhaseStartCleanup "service $i"
        rlServiceRestore $i
    rlPhaseEnd
done
rlJournalPrintText
rlJournalEnd
