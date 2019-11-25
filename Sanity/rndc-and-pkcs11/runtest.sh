#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Sanity/rndc-and-pkcs11
#   Description: rndc-and-pkcs11
#   Author: Petr Sklenar <psklenar@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
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
    rlPhaseStartSetup "service setup"
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlFileBackup --clean /var/lib/softhsm/tokens/*
        rlFileBackup --clean /etc/rndc.key
    rlPhaseEnd

    rlPhaseStartSetup "PKCS11 initializatoon"
### SETUP
        PIN='petr'
        rlFileBackup /etc/sysconfig/named
        rlFileBackup /etc/softhsm2.conf
        rlFileBackup /var/lib/softhsm/tokens
        export SOFTHSM2_CONF="/etc/softhsm2.conf"
        export OPENSSL_FORCE_FIPS_MODE=1
        echo 'OPENSSL_FORCE_FIPS_MODE=1' >>  /etc/sysconfig/named
        rlRun "softhsm2-util --init-token --free --label rpm --pin $PIN --so-pin $PIN"

### PERMISSIONS
        TOKEN=$(ls /var/lib/softhsm/tokens)
        echo $TOKEN
        chgrp named -R /var/lib/softhsm/tokens
        chmod g+rX -R /var/lib/softhsm/tokens
        rlRun "usermod -aG ods named"


### START
        rlRun "rlServiceStart named-pkcs11"
        rlRun "systemctl status named-pkcs11"

###DEBUG
        rlLog "SOFTHSM2_CONF=`echo $SOFTHSM2_CONF`"
        rlLog "pkcs11-tokens: `pkcs11-tokens`"
        rlLog "/var/lib/softhsm/tokens `ls -lad /var/lib/softhsm/tokens;ls -la /var/lib/softhsm/tokens`"
    rlPhaseEnd

   rlPhaseStartTest "Normal test"
	rlRun "rm -rf /etc/rndc.key"
        rlRun "systemctl restart named-pkcs11"
        rlRun "rndc reload"
        rlRun "pkcs11-tokens"

        for i in `seq 1 10`;do rndc reload;done
        rlLog "/etc/rndc.key `cat /etc/rndc.key`"
        rlRun "rndc reload" 0
        rlRun "rndc scan" 0
        rlRun "rndc sync" 0
        rlRun "rndc thaw" 0
        rlRun "systemctl status named-pkcs11"
   rlPhaseEnd

   rlPhaseStartTest "Manual confgen test"
        rlRun "rndc-confgen -a" 0
	RETURN=0 # it depends on fips mode status
        rlRun "systemctl restart named-pkcs11" 0
        for i in `seq 1 10`;do rndc reload;done
        rlLog "/etc/rndc.key `cat /etc/rndc.key`"
        rlRun "rndc reload" $RETURN
        rlRun "rndc scan" $RETURN
        rlRun "rndc sync" $RETURN
        rlRun "rndc thaw" $RETURN
        rlRun "systemctl status named-pkcs11" 0 "named-pkcs11 should survive"
        rlRun "pgrep named-pkcs11"
   rlPhaseEnd

  rlPhaseStartCleanup
	unset OPENSSL_FORCE_FIPS_MODE
        rlRun "systemctl restart named-pkcs11" 0
        rlServiceRestore named-pkcs11
        rm -rf /etc/softhsm2.conf /var/lib/softhsm/tokens
        rlFileRestore
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd
