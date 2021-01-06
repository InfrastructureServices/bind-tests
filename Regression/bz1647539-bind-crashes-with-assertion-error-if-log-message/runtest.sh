#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/bind/Regression/bz1647539-bind-crashes-with-assertion-error-if-log-message
#   Description: Test for BZ#1647539 (bind crashes with assertion error if log message)
#   Author: Petr Mensik <pemensik@redhat.com>
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

true <<'=cut'
=head2 bsDnssecManagedKeys
=over

=item path Path to public key
Generated managed keys config snipped. Can be included as trusted anchor
from named.conf.
=cut
bsDnssecManagedKeys()
{
    echo "managed-keys {"
    grep -v '^;' "$@" | while read ZONE CLASS TYPE FLAGS PROTO ALG KEYDATA; do
        echo "$ZONE initial-key $FLAGS $PROTO $ALG \"$KEYDATA\";"
    done
    echo "};"
}

true <<'=cut'
=head2 bsDnssecGenerateSign
=item zone Domain origin
=item file Zone file with zone data
=item [anchor] Anchor basename, where trusted root would be generated
=item [key algorithm] Key algorithm
=item [key bitsize]   Key bit size
=over

Generate new zone Key Signing Key and Zone Signing Key, then use it to sign
the zone. If anchor is also non-empty, generate trusted anchor from KSK.
=cut
bsDnssecGenerateSign()
{
    local ZONE="$1"
    local FILE="${2:-$ZONE.db}"
    local ANCHOR="$3"
    local ALGORITHM="${4:-RSASHA256}"
    local KEY_SIZE="${5:-2048}"

    rlRun "KSK=`dnssec-keygen -a $ALGORITHM -b $KEY_SIZE -f KSK $ZONE`"
    rlRun "ZSK=`dnssec-keygen -a $ALGORITHM -b $KEY_SIZE $ZONE`"
    rlRun "dnssec-signzone -S -g -o $ZONE $FILE $KSK $ZSK"
    if [ -n "$ANCHOR" ]; then
        rlRun "bsDnssecManagedKeys $KSK.key > $ANCHOR.conf"
        rlRun "grep -v '^;' $KSK.key > $ANCHOR.key"
    fi
}

true <<'=cut'
=head2 bsDigStatus
=over
=item status Required dig status
=item dig_params Remaining dig parameters
=cut
bsDigStatus()
{
	STATUS="$1"
	shift
	local DIG_PARAMS="$@"
	rlRun -s "${DIG:-dig} ${DIG_PARAMS}"
	RET=$?
	rlAssertEquals "Checking ${DIG:-dig} status matches" \
		"$STATUS" \
		"`sed -e 's/;; ->>HEADER<<- opcode: QUERY, status: \([A-Z0-9]\+\),.*/\1/' -e 't' -e 'd' \"$rlRun_LOG\"`"
	rlRun "rm -f \"$rlRun_LOG\""
	return $RET
}


test_iteration()
{
	T="x123456789.123456789.123456789.123456789.abcdefghijklmnopqrstuvwxyz"
	SUFFIX=$1
	RRTYPE=${2:-TXT}
	if rlRun "$DIG_REC -t NS $SUFFIX" 0 "Testing recursive server with suffix $SUFFIX"
	then
		for ((I=1; I<${#T}; I++))
		do
			rlRun "$DIG_REC +dnssec +bufsize=2048 -t $RRTYPE ${T:0:I}.$SUFFIX"
		done
	fi
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
	rlAssertRpm bind
	rlAssertRpm bind-utils
	rlAssertRpm procps-ng
	rlAssertRpm rng-tools
	ZONEFILES="root.db very-long-01234567890123456789012345678901234567.test.db"
	ZONEFILES="root.db edu-servers.net.db"
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
	rlRun "cp named.conf named-recursive.conf named.hints $ZONEFILES $TmpDir"
	rlRun "cp $ZONEFILES $TmpDir"
	rlRun "cp dsset-* $TmpDir"
        rlRun "pushd $TmpDir"
	rlServiceStart rngd
	rlRun "bsDnssecGenerateSign . root.db root"
	rlRun "named -c named.conf -d 12" 0 "Starting authoritative server"
	rlRun "named -c named-recursive.conf -d 12" 0 "Starting recursive server"
    rlPhaseEnd

    rlPhaseStartTest
	DIG="dig @localhost"
	REC_PORT="-p 53333"
	DIG_REC="$DIG $REC_PORT"
        rlRun "bsDigStatus NOERROR +norec" 0 "Testing authoritative server"
	rlRun "bsDigStatus NOERROR $REC_PORT" 0 "Testing recursive server"
        rlAssertExists "named.pid"
	rlAssertExists "named-recursive.pid"
	rlAssertExists "named-recursive.run"
	rlRun "$DIG_REC" 0 "Testing recursive server"
	# FIXME: this assumes query id is 5 characters long. May not work reliably if shorter is used.
	rlRun "$DIG_REC -t AAAA +dnssec udel.edu." 0 "Checking crashing request"
	rlRun "$DIG_REC" 0 "Testing recursive server"
	#rlRun "PS1='in-test ' bash -i"
    rlPhaseEnd

    rlPhaseStartCleanup
	rlRun "pkill -F named-recursive.pid"
	rlRun "pkill -F named.pid"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
	rlServiceRestore rngd
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
