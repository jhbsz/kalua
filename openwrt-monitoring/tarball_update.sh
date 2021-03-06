#!/bin/sh

NETWORK="$1"	# liszt28 or 'start'
MODE="$2"	# testing or <githash>
TARBALL='/tmp/tarball.tgz'

[ "$NETWORK" = 'start' ] && {
	HASH="$MODE"

	mkdir -p /root/tarball
	cd /root/tarball || exit
	cd kalua || {
		git clone 'https://github.com/bittorf/kalua.git'
		cd kalua || exit
	}

	git log -1
	git pull
	[ -n "$HASH" ] && {
		if git show "$HASH" >/dev/null; then
			git checkout -b 'userwish' "$HASH"
		else
			HASH=
		fi
	}
	git log -1
	cd ..

	kalua/openwrt-build/mybuild.sh build_kalua_update_tarball

	[ -n "$HASH" ] && {
		cd kalua || exit
		git checkout master
		git branch -D 'userwish'
		cd ..
	}

	exit $?
}

[ -z "$MODE" ] && {
	echo "usage: $0 <network|all> <mode>"
	echo "       $0 start"
	echo
	echo "e.g. : $0 liszt28 testing"

	exit 1
}

list_networks()
{
        local pattern1="/var/www/networks/"
        local pattern2="/meshrdf/recent"

        find /var/www/networks/ -name recent |
         grep "meshrdf/recent"$ |
          sed -e "s|$pattern1||" -e "s|$pattern2||"
}

[ "$NETWORK" = 'all' ] && NETWORK="$( list_networks )"

[ -e "$TARBALL" ] || {
	cat <<EOF
[ERROR] cannot find tarball '$TARBALL', please do:

cd /root/tarball/
cd kalua
git pull
cd ..
kalua/openwrt-build/mybuild.sh build_kalua_update_tarball
EOF
	exit 1
}

for NW in $NETWORK; do {
	DIR="/var/www/networks/$NW/tarball/$MODE"
	MD5="$( md5sum "$TARBALL" | cut -d' ' -f1 )"
	SIZE="$( stat -c%s "$TARBALL" )"

	cp -v "$TARBALL" "$DIR"
	echo "CRC[md5]: $MD5  SIZE[byte]: $SIZE  FILE: 'tarball.tgz'" >"$DIR/info.txt"
} done
