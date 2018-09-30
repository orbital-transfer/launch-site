#!/bin/bash

function _setup() {
	if [ -f $TRAVIS_BUILD_DIR/bin/oberthian ]; then
		echo "Running inside oberthian: $TRAVIS_REPO_SLUG"
		export OBERTH_PROTOTYPE_DIR=$TRAVIS_BUILD_DIR
		export OBERTH_TEST_DIR=$(cd .. && pwd)/build/repository
		git clone --recursive $OBERTH_TEST_REPO $OBERTH_TEST_DIR
	else
		echo "Running outside oberthian: $TRAVIS_REPO_SLUG"
		export OBERTH_PROTOTYPE_DIR=$(cd .. && pwd)/external/oberth-manoeuvre/oberth-prototype
		export OBERTH_TEST_DIR=$TRAVIS_BUILD_DIR

		if [ -z "$OBERTH_PROTOTYPE_BRANCH" ]; then
			export OBERTH_PROTOTYPE_BRANCH="9-clone-ci";
		fi

		git clone \
			--recursive \
			-b $OBERTH_PROTOTYPE_BRANCH \
			https://github.com/oberth-manoeuvre/oberth-prototype.git \
			$OBERTH_PROTOTYPE_DIR
	fi

	export PATH="$OBERTH_PROTOTYPE_DIR"/bin:$PATH
}

function travis-oberth() {
	case "$1" in
		"before-install")
			$OBERTH_PROTOTYPE_DIR/maint/travis-ci/before-install
			;;
		"install")
			true
			;;
		"script")
			$OBERTH_PROTOTYPE_DIR/maint/travis-ci/script
			;;
	esac
}

_setup
