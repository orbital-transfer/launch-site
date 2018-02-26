use Modern::Perl;
package Oberth::Prototype;

BEGIN {
	require File::Glob;
	require FindBin;
	our @VENDOR_LIB = File::Glob::bsd_glob("$FindBin::Bin/../vendor/*/lib");
	unshift @INC, @VENDOR_LIB;
}

use Moo;
use CLI::Osprey;

use Oberth::Common::Setup;

subcommand 'list-native-dependencies' => method() { 1 };

method run() {
	...
}


1;
