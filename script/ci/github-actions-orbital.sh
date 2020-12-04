#!/bin/sh

function _setup() {
	cd $GITHUB_WORKSPACE
	export ORBITAL_LAUNCH_SITE_DIR=$(cd .. && pwd)/_orbital/external/orbital-transfer/launch-site
	export ORBITAL_TEST_DIR=$GITHUB_WORKSPACE
	git clone --recursive \
		https://github.com/orbital-transfer/launch-site.git \
		$ORBITAL_LAUNCH_SITE_DIR
	export ORBITAL_LAUNCH_BIN="$ORBITAL_LAUNCH_SITE_DIR"/vendor/p5-Orbital-Launch/bin
	export PATH=$ORBITAL_LAUNCH_BIN:$PATH
	if [ "$RUNNER_OS" == "Windows" ]; then
		echo $(cygpath -w  $ORBITAL_LAUNCH_BIN) >> $GITHUB_PATH
	else
		echo $ORBITAL_LAUNCH_BIN >> $GITHUB_PATH
	fi
}

_setup
