#!/bin/bash

function _setup() {
	if [ -f $TRAVIS_BUILD_DIR/maint/launch-site-repo ]; then
		echo "Running inside orbitalism: $TRAVIS_REPO_SLUG"
		export ORBITAL_LAUNCH_SITE_DIR=$TRAVIS_BUILD_DIR
		export ORBITAL_TEST_DIR=$(cd .. && pwd)/build/repository
		if [ -z "$ORBITAL_TEST_REPO_BRANCH" ]; then
			echo "Cloning $ORBITAL_TEST_REPO @ default branch"
			git clone --recursive $ORBITAL_TEST_REPO $ORBITAL_TEST_DIR
		else
			echo "Cloning $ORBITAL_TEST_REPO @ $ORBITAL_TEST_REPO_BRANCH"
			git clone \
				--recursive \
				-b $ORBITAL_TEST_REPO_BRANCH \
				$ORBITAL_TEST_REPO \
				$ORBITAL_TEST_DIR
		fi
	else
		echo "Running outside orbitalism: $TRAVIS_REPO_SLUG"
		export ORBITAL_LAUNCH_SITE_DIR=$(cd .. && pwd)/_orbital/external/orbital-transfer/launch-site
		export ORBITAL_TEST_DIR=$TRAVIS_BUILD_DIR

		if [ -z "$ORBITAL_LAUNCH_SITE_BRANCH" ]; then
			export ORBITAL_LAUNCH_SITE_BRANCH="master";
		fi

		git clone \
			--recursive \
			-b $ORBITAL_LAUNCH_SITE_BRANCH \
			https://github.com/orbital-transfer/launch-site.git \
			$ORBITAL_LAUNCH_SITE_DIR
	fi

	export PATH="$ORBITAL_LAUNCH_SITE_DIR"/vendor/p5-Orbital-Launch/bin:$PATH
}

function travis-orbital() {
	case "$1" in
		"before-install")
			$ORBITAL_LAUNCH_SITE_DIR/maint/travis-ci/before-install
			;;
		"install")
			true
			;;
		"script")
			$ORBITAL_LAUNCH_SITE_DIR/maint/travis-ci/script
			;;
	esac
}

_setup
