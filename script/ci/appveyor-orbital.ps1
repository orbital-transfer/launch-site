function _Setup {
	cinst StrawberryPerl
	if( Test-Path $Env:APPVEYOR_BUILD_FOLDER\maint\launch-site-repo ) {
		git submodule update --init --recursive
		echo "Running inside orbitalism: $Env:APPVEYOR_PROJECT_SLUG"
		$Env:ORBITAL_LAUNCH_SITE_DIR=$Env:APPVEYOR_BUILD_FOLDER
		$Env:ORBITAL_TEST_DIR=(Join-Path ([System.IO.Path]::GetFullPath("$(pwd)/..")) 'build\repository')

		if ( [string]::IsNullOrEmpty($Env:ORBITAL_TEST_REPO_BRANCH) ) {
			echo "Cloning $Env:ORBITAL_TEST_REPO @ default branch"
			git clone --recursive $Env:ORBITAL_TEST_REPO $Env:ORBITAL_TEST_DIR
		} else {
			echo "Cloning $Env:ORBITAL_TEST_REPO @ $Env:ORBITAL_TEST_REPO_BRANCH"
			git clone `
				--recursive `
				-b $Env:ORBITAL_TEST_REPO_BRANCH `
				$Env:ORBITAL_TEST_REPO `
				$Env:ORBITAL_TEST_DIR
		}
	} else {
		echo "Running outside orbitalism: $Env:APPVEYOR_PROJECT_SLUG"
		$Env:ORBITAL_LAUNCH_SITE_DIR=(Join-Path ([System.IO.Path]::GetFullPath("$(pwd)/..")) '_orbital\external\orbital-transfer\launch-site')
		$Env:ORBITAL_TEST_DIR=$Env:APPVEYOR_BUILD_FOLDER

		if ( [string]::IsNullOrEmpty($Env:ORBITAL_LAUNCH_SITE_BRANCH) ) {
			$Env:ORBITAL_LAUNCH_SITE_BRANCH="master";
		}

		git clone `
			--recursive `
			-b $Env:ORBITAL_LAUNCH_SITE_BRANCH `
			https://github.com/orbital-transfer/launch-site.git `
			$Env:ORBITAL_LAUNCH_SITE_DIR
	}
}

function appveyor-orbital {
	param( [string]$command )
	# Run under Strawberry Perl because default ActiveState Perl has broken pl2bat
	$Env:PATH="C:\strawberry\perl\bin;C:\strawberry\perl\site\bin;C:\strawberry\c\bin;$Env:PATH"
	perl -V
	cd $Env:ORBITAL_TEST_DIR
	switch( $command ) {
		"install" {
			perl $Env:ORBITAL_LAUNCH_SITE_DIR\vendor\p5-Orbital-Launch\bin\orbitalism bootstrap auto;

			if( $LastExitCode -ne 0 ) { exit $LastExitCode; }
			perl $Env:ORBITAL_LAUNCH_SITE_DIR\vendor\p5-Orbital-Launch\bin\orbitalism;
			if( $LastExitCode -ne 0 ) { exit $LastExitCode; }
			break
		}
		"build-script" {
			break
		}
		"test-script" {
			perl $Env:ORBITAL_LAUNCH_SITE_DIR\vendor\p5-Orbital-Launch\bin\orbitalism test;
			if( $LastExitCode -ne 0 ) { exit $LastExitCode; }
			break
		}
	}
}

_Setup
