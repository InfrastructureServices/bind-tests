#!/bin/sh
#
# Extract required packages from beakerlib Makefile
# and generate them into tmt files

TMPMETA=$(mktemp /tmp/beaker-meta-XXXXX.txt)
ALLPACKAGES=$(pwd)/allpackages.txt

find -name 'Makefile' | while read MAKEFILE; do
DIRNAME=$(dirname -- "$MAKEFILE")
FMF="$DIRNAME/main.fmf"
if [ -f "$FMF" ] && ! grep -q 'require:' "$FMF"; then
	rm -f "$TMPMETA"
	(cd $DIRNAME && make METADATA="$TMPMETA" "$TMPMETA")
	PACKAGES=$(grep Requires: "$TMPMETA" | cut -d: -f2- | xargs echo)
	echo 'require:' >> "$FMF"
	for PKG in $PACKAGES; do
		echo "    - $PKG" >> "$FMF"
		echo "$PKG" >> "$ALLPACKAGES"
	done
fi
done

sort -u < "$ALLPACKAGES" > "$TMPMETA"
mv "$TMPMETA" "$ALLPACKAGES"
