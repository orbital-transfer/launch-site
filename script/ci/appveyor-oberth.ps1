function _Setup {
	if( Test-Path $Env:APPVEYOR_BUILD_FOLDER\bin\oberthian ) {
		echo "Running inside oberthian: $Env:APPVEYOR_PROJECT_SLUG"
		$Env:OBERTH_PROTOTYPE_DIR=$Env:APPVEYOR_BUILD_FOLDER
		$Env:OBERTH_TEST_DIR=(Join-Path ([System.IO.Path]::GetFullPath("$(pwd)/..")) 'build\repository')

		if ( [string]::IsNullOrEmpty($Env:OBERTH_TEST_REPO_BRANCH) ) {
			echo "Cloning $Env:OBERTH_TEST_REPO @ default branch"
			git clone --recursive $Env:OBERTH_TEST_REPO $Env:OBERTH_TEST_DIR
		} else {
			echo "Cloning $Env:OBERTH_TEST_REPO @ $Env:OBERTH_TEST_REPO_BRANCH"
			git clone `
				--recursive `
				-b $Env:OBERTH_TEST_REPO_BRANCH `
				$Env:OBERTH_TEST_REPO `
				$Env:OBERTH_TEST_DIR
		}
	} else {
		echo "Running outside oberthian: $Env:APPVEYOR_PROJECT_SLUG"
		$Env:OBERTH_PROTOTYPE_DIR=(Join-Path ([System.IO.Path]::GetFullPath("$(pwd)/..")) 'external\oberth-manoeuvre\oberth-prototype')
		$Env:OBERTH_TEST_DIR=$Env:APPVEYOR_BUILD_FOLDER

		if ( [string]::IsNullOrEmpty($Env:OBERTH_PROTOTYPE_BRANCH) ) {
			$Env:OBERTH_PROTOTYPE_BRANCH="master";
		}

		git clone `
			--recursive `
			-b $Env:OBERTH_PROTOTYPE_BRANCH `
			https://github.com/oberth-manoeuvre/oberth-prototype.git `
			$Env:OBERTH_PROTOTYPE_DIR
	}
}

function appveyor-oberth {
	param( [string]$command )
	cd $Env:OBERTH_TEST_DIR
	switch( $command ) {
		"install" {
			perl $Env:OBERTH_PROTOTYPE_DIR\maint\appveyor-ci\run install;
			break
		}
		"build-script" {
			perl $Env:OBERTH_PROTOTYPE_DIR\maint\appveyor-ci\run build;
			break
		}
		"test-script" {
			perl $Env:OBERTH_PROTOTYPE_DIR\maint\appveyor-ci\run test;
			break
		}
	}
}

_Setup
